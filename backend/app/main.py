import asyncio
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import json

from app.config import settings
from app.database import engine, Base, SessionLocal
from app.models import User
from app.auth import hash_password
from app.services.device_service import ensure_default_device, record_telemetry
from app.services.communication_service import gateway
from app.services.simulation_service import simulator
from app.websocket.manager import manager

from app.routers import authentication, devices, sensors, lighting, analytics, settings as settings_router

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

# Background task to stream telemetry periodically
async def telemetry_background_loop():
    logger.info("[SERVER] Telemetry background worker started.")
    while True:
        try:
            await asyncio.sleep(1.0)
            # Advance simulation FSM by 1 tick if physical hardware is not broadcasting
            if not gateway.is_connected:
                simulator.step_fsm()
                t = simulator.get_telemetry()
                
                # Record to database
                db = SessionLocal()
                try:
                    record_telemetry(db, settings.DEFAULT_DEVICE_ID, t)
                finally:
                    db.close()

                # Push to all connected dashboard websockets
                await manager.broadcast_json({
                    "type": "telemetry",
                    "data": t
                })
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.error(f"[SERVER] Background loop error: {e}")
            await asyncio.sleep(2.0)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # 1. Initialize Database Schema
    logger.info("[INIT] Initializing relational database schema...")
    Base.metadata.create_all(bind=engine)

    # 2. Seed Default User & Device
    db = SessionLocal()
    try:
        admin = db.query(User).filter(User.email == "admin@smartroom.edu").first()
        if not admin:
            admin = User(
                name="Lab Administrator",
                email="admin@smartroom.edu",
                password_hash=hash_password("admin123")
            )
            db.add(admin)
            db.commit()
            logger.info("[INIT] Seeded default administrator user (admin@smartroom.edu / admin123).")

        ensure_default_device(db)
        logger.info("[INIT] Default Room Device initialized.")
    finally:
        db.close()

    # 3. Attempt physical hardware connection
    if settings.ENABLE_HARDWARE_SERIAL:
        gateway.connect()

    # 4. Launch background telemetry publisher
    bg_task = asyncio.create_task(telemetry_background_loop())

    yield

    # Teardown
    bg_task.cancel()
    if gateway.is_connected:
        gateway.disconnect()
    logger.info("[SERVER] Shutdown complete.")

app = FastAPI(
    title=settings.APP_NAME,
    description="Smart Automatic Room Light and Energy Management System API",
    version="1.0.0",
    lifespan=lifespan
)

# CORS configuration for React frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register API Routers
app.include_router(authentication.router)
app.include_router(devices.router)
app.include_router(lighting.router)
app.include_router(sensors.router)
app.include_router(analytics.router)
app.include_router(settings_router.router)

@app.get("/")
def root():
    return {
        "system": settings.APP_NAME,
        "status": "ONLINE",
        "docs_url": "/docs",
        "simulation_mode": not gateway.is_connected
    }

# -----------------------------------------------------------------------------
# WebSocket Endpoint: /ws/dashboard
# -----------------------------------------------------------------------------
@app.websocket("/ws/dashboard")
async def websocket_dashboard(websocket: WebSocket):
    await manager.connect(websocket)
    # Immediately send current state snapshot
    snap = simulator.get_telemetry()
    await websocket.send_text(json.dumps({"type": "snapshot", "data": snap}))

    try:
        while True:
            raw_text = await websocket.receive_text()
            try:
                data = json.loads(raw_text)
                cmd = data.get("command")
                if cmd == "SET_MODE":
                    simulator.set_mode(data.get("mode", "AUTO"))
                    if gateway.is_connected:
                        gateway.send_mode(data.get("mode"))
                elif cmd == "SET_BRIGHTNESS":
                    b = data.get("brightness", 100)
                    simulator.set_brightness(b)
                    if gateway.is_connected:
                        gateway.send_brightness(b)
                elif cmd == "INJECT_MOTION":
                    simulator.inject_motion(data.get("active", True))
                elif cmd == "SET_LUX":
                    simulator.set_ambient_light(data.get("lux", 500))

                simulator.step_fsm()
                t = simulator.get_telemetry()
                await manager.broadcast_json({"type": "telemetry", "data": t})
            except Exception as pe:
                logger.warning(f"[WS] Failed to parse message: {pe}")
    except WebSocketDisconnect:
        manager.disconnect(websocket)
