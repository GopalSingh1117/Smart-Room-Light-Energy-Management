from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timezone

from app.database import get_db
from app.models import Device, LightingHistory, SensorReading
from app.schemas import (
    ModeCommand, PowerCommand, BrightnessCommand, TimeoutCommand,
    EnergySavingCommand, LightingStatusResponse
)
from app.services.communication_service import gateway
from app.services.simulation_service import simulator
from app.services.device_service import ensure_default_device, record_telemetry
from app.websocket.manager import manager

router = APIRouter(prefix="/api/lighting", tags=["Lighting Control"])

@router.get("/status", response_model=LightingStatusResponse)
def get_lighting_status(device_id: str = "ROOM_001", db: Session = Depends(get_db)):
    ensure_default_device(db)
    
    # Check if physical hardware is streaming or fetch from simulator / DB
    if gateway.is_connected:
        last_hist = db.query(LightingHistory).filter(LightingHistory.device_id == device_id).order_by(LightingHistory.id.desc()).first()
        last_sensor = db.query(SensorReading).filter(SensorReading.device_id == device_id).order_by(SensorReading.id.desc()).first()
        return {
            "device_id": device_id,
            "light_status": last_hist.lighting_status if last_hist else False,
            "brightness": last_hist.brightness if last_hist else 0,
            "operating_mode": last_hist.operating_mode if last_hist else "AUTO",
            "motion_detected": last_sensor.motion_detected if last_sensor else False,
            "occupancy": last_sensor.occupancy if last_sensor else False,
            "ambient_light": last_sensor.ambient_light if last_sensor else 500,
            "timeout_remaining": 30,
            "estimated_power_watts": round((last_hist.brightness / 100.0) * 10.0, 2) if last_hist and last_hist.lighting_status else 0.0,
            "hardware_connected": True,
            "last_update": last_hist.timestamp if last_hist else datetime.now(timezone.utc)
        }
    else:
        # Fallback to simulated hardware core
        t = simulator.get_telemetry()
        return {
            "device_id": device_id,
            "light_status": t["light_status"],
            "brightness": t["brightness"],
            "operating_mode": t["mode"],
            "motion_detected": t["motion_detected"],
            "occupancy": t["occupancy"],
            "ambient_light": t["ambient_light"],
            "timeout_remaining": t["timeout_remaining"],
            "estimated_power_watts": t["estimated_power_watts"],
            "hardware_connected": False,
            "last_update": datetime.now(timezone.utc)
        }

@router.post("/mode")
async def set_mode(cmd: ModeCommand, db: Session = Depends(get_db)):
    dev_id = cmd.device_id or "ROOM_001"
    
    # 1. Forward to Physical Hardware Gateway if available
    hardware_sent = gateway.send_mode(cmd.mode) if gateway.is_connected else False
    
    # 2. Update simulator state as well for seamless dual operation
    simulator.set_mode(cmd.mode)
    simulator.step_fsm()
    
    # 3. Synchronize Database & Broadcast Update
    telemetry = simulator.get_telemetry()
    telemetry["hardware_connected"] = hardware_sent
    record_telemetry(db, dev_id, telemetry)
    await manager.broadcast_json({"type": "telemetry", "data": telemetry})

    return {
        "status": "success",
        "command": "SET_MODE",
        "applied_mode": cmd.mode,
        "hardware_forwarded": hardware_sent
    }

@router.post("/power")
async def set_power(cmd: PowerCommand, db: Session = Depends(get_db)):
    target_mode = "MANUAL_ON" if cmd.power else "MANUAL_OFF"
    hardware_sent = gateway.send_mode(target_mode) if gateway.is_connected else False
    
    simulator.set_mode(target_mode)
    simulator.step_fsm()
    
    telemetry = simulator.get_telemetry()
    telemetry["hardware_connected"] = hardware_sent
    record_telemetry(db, cmd.device_id or "ROOM_001", telemetry)
    await manager.broadcast_json({"type": "telemetry", "data": telemetry})

    return {
        "status": "success",
        "command": "SET_POWER",
        "power": cmd.power,
        "operating_mode": target_mode,
        "hardware_forwarded": hardware_sent
    }

@router.post("/brightness")
async def set_brightness(cmd: BrightnessCommand, db: Session = Depends(get_db)):
    hardware_sent = gateway.send_brightness(cmd.brightness) if gateway.is_connected else False
    
    simulator.set_brightness(cmd.brightness)
    if simulator.mode != "MANUAL_ON":
        simulator.set_mode("MANUAL_ON")
    simulator.step_fsm()

    telemetry = simulator.get_telemetry()
    telemetry["hardware_connected"] = hardware_sent
    record_telemetry(db, cmd.device_id or "ROOM_001", telemetry)
    await manager.broadcast_json({"type": "telemetry", "data": telemetry})

    return {
        "status": "success",
        "command": "SET_BRIGHTNESS",
        "applied_brightness": cmd.brightness,
        "hardware_forwarded": hardware_sent
    }

@router.post("/timeout")
async def set_timeout(cmd: TimeoutCommand, db: Session = Depends(get_db)):
    hardware_sent = gateway.send_timeout(cmd.timeout_seconds) if gateway.is_connected else False
    
    simulator.set_timeout(cmd.timeout_seconds)
    telemetry = simulator.get_telemetry()
    await manager.broadcast_json({"type": "telemetry", "data": telemetry})

    return {
        "status": "success",
        "command": "SET_TIMEOUT",
        "timeout_seconds": cmd.timeout_seconds,
        "hardware_forwarded": hardware_sent
    }

@router.post("/energy-saving")
async def set_energy_saving(cmd: EnergySavingCommand, db: Session = Depends(get_db)):
    hardware_sent = gateway.send_energy_saving(cmd.enabled) if gateway.is_connected else False
    
    simulator.set_energy_saving(cmd.enabled)
    simulator.step_fsm()
    telemetry = simulator.get_telemetry()
    await manager.broadcast_json({"type": "telemetry", "data": telemetry})

    return {
        "status": "success",
        "command": "SET_ENERGY_SAVING",
        "enabled": cmd.enabled,
        "hardware_forwarded": hardware_sent
    }

@router.post("/simulate")
async def inject_simulation_event(event: dict, db: Session = Depends(get_db)):
    """Interactive Simulation Dock API for web browser testing without physical FPGA"""
    if "motion" in event:
        simulator.inject_motion(bool(event["motion"]))
    if "ambient_light" in event:
        simulator.set_ambient_light(int(event["ambient_light"]))
    if "tick_countdown" in event and event["tick_countdown"]:
        simulator.step_fsm()

    telemetry = simulator.get_telemetry()
    record_telemetry(db, "ROOM_001", telemetry)
    await manager.broadcast_json({"type": "telemetry", "data": telemetry})

    return {"status": "success", "telemetry": telemetry}
