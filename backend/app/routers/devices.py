from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timezone

from app.database import get_db
from app.models import Device
from app.schemas import DeviceCreate, DeviceResponse, TelemetryPayload
from app.services.device_service import ensure_default_device, record_telemetry
from app.websocket.manager import manager
from app.services.simulation_service import simulator

router = APIRouter(prefix="/api/devices", tags=["Devices"])

@router.get("", response_model=List[DeviceResponse])
def get_devices(db: Session = Depends(get_db)):
    ensure_default_device(db)
    devices = db.query(Device).all()
    return devices

@router.post("", response_model=DeviceResponse, status_code=status.HTTP_201_CREATED)
def register_device(dev_in: DeviceCreate, db: Session = Depends(get_db)):
    existing = db.query(Device).filter(Device.id == dev_in.id).first()
    if existing:
        return existing

    device = Device(
        id=dev_in.id,
        device_name=dev_in.device_name,
        room_name=dev_in.room_name,
        device_status="ONLINE",
        last_seen=datetime.now(timezone.utc)
    )
    db.add(device)
    db.commit()
    db.refresh(device)
    return device

@router.post("/telemetry")
async def ingest_telemetry(payload: TelemetryPayload, db: Session = Depends(get_db)):
    """Receives JSON telemetry from physical ESP32 or gateway"""
    data = payload.model_dump()
    data["timestamp"] = datetime.now(timezone.utc).timestamp()
    record_telemetry(db, payload.device_id, data)

    # Broadcast to all live WebSocket UI clients
    await manager.broadcast_json({
        "type": "telemetry",
        "data": data
    })

    return {"status": "success", "message": "Telemetry processed"}
