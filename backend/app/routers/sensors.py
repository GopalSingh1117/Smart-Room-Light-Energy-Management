from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List, Dict, Any
from datetime import datetime, timedelta, timezone

from app.database import get_db
from app.models import SensorReading
from app.services.device_service import ensure_default_device
from app.services.simulation_service import simulator

router = APIRouter(prefix="/api/sensors", tags=["Sensors"])

@router.get("/latest")
def get_latest_sensors(device_id: str = "ROOM_001", db: Session = Depends(get_db)):
    reading = db.query(SensorReading).filter(SensorReading.device_id == device_id).order_by(SensorReading.id.desc()).first()
    if reading:
        return {
            "device_id": reading.device_id,
            "motion_detected": reading.motion_detected,
            "ambient_light": reading.ambient_light,
            "occupancy": reading.occupancy,
            "timestamp": reading.timestamp
        }
    else:
        t = simulator.get_telemetry()
        return {
            "device_id": device_id,
            "motion_detected": t["motion_detected"],
            "ambient_light": t["ambient_light"],
            "occupancy": t["occupancy"],
            "timestamp": datetime.now(timezone.utc)
        }

@router.get("/history")
def get_sensor_history(
    device_id: str = "ROOM_001",
    limit: int = Query(50, ge=1, le=500),
    db: Session = Depends(get_db)
):
    readings = db.query(SensorReading).filter(
        SensorReading.device_id == device_id
    ).order_by(SensorReading.id.desc()).limit(limit).all()

    # If database is fresh, populate mock historical time-series for chart visualizer
    if len(readings) < 10:
        now = datetime.now(timezone.utc)
        history_points = []
        for i in range(20, -1, -1):
            t = now - timedelta(minutes=i*2)
            # Simulate a realistic daylight curve peaking at midday and dipping in the evening
            lux_val = int(300 + 400 * (1 - abs(i - 10) / 10.0))
            history_points.append({
                "id": 1000 - i,
                "device_id": device_id,
                "motion_detected": (i % 4 == 0),
                "ambient_light": lux_val,
                "occupancy": (i % 4 == 0 or i % 4 == 1),
                "timestamp": t.isoformat()
            })
        return history_points

    return [
        {
            "id": r.id,
            "device_id": r.device_id,
            "motion_detected": r.motion_detected,
            "ambient_light": r.ambient_light,
            "occupancy": r.occupancy,
            "timestamp": r.timestamp.isoformat()
        } for r in reversed(readings)
    ]

@router.get("/occupancy")
def get_occupancy_status(device_id: str = "ROOM_001", db: Session = Depends(get_db)):
    t = simulator.get_telemetry()
    return {
        "device_id": device_id,
        "motion_detected": t["motion_detected"],
        "occupancy": t["occupancy"],
        "timeout_remaining": t["timeout_remaining"],
        "timestamp": datetime.now(timezone.utc)
    }

@router.get("/ambient-light")
def get_ambient_light(device_id: str = "ROOM_001", db: Session = Depends(get_db)):
    t = simulator.get_telemetry()
    lux = t["ambient_light"]
    zone = "DARK" if lux < 350 else ("BRIGHT" if lux >= 700 else "MEDIUM")
    return {
        "device_id": device_id,
        "ambient_light_adc": lux,
        "classification": zone,
        "percentage": round((lux / 1023.0) * 100.0, 1),
        "timestamp": datetime.now(timezone.utc)
    }
