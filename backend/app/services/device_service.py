from sqlalchemy.orm import Session
from datetime import datetime, timezone
from app.models import Device, DeviceSettings, SensorReading, LightingHistory, EnergyUsage
from app.config import settings

def ensure_default_device(db: Session) -> Device:
    device = db.query(Device).filter(Device.id == settings.DEFAULT_DEVICE_ID).first()
    if not device:
        device = Device(
            id=settings.DEFAULT_DEVICE_ID,
            device_name="Living Lab Controller (Artix-7)",
            room_name="Smart Engineering Lab",
            device_status="SIMULATED",
            last_seen=datetime.now(timezone.utc)
        )
        db.add(device)
        db.commit()
        db.refresh(device)

    dev_settings = db.query(DeviceSettings).filter(DeviceSettings.device_id == device.id).first()
    if not dev_settings:
        dev_settings = DeviceSettings(
            device_id=device.id,
            light_threshold_dark=350,
            light_threshold_bright=700,
            default_brightness=100,
            shutdown_timeout=30,
            energy_saving_enabled=True,
            led_rated_power_watts=10.0
        )
        db.add(dev_settings)
        db.commit()

    return device

def record_telemetry(db: Session, device_id: str, data: dict):
    device = db.query(Device).filter(Device.id == device_id).first()
    if not device:
        device = ensure_default_device(db)

    now = datetime.now(timezone.utc)
    device.last_seen = now
    device.device_status = "ONLINE" if data.get("hardware_connected", False) else "SIMULATED"

    # Add Sensor Reading
    reading = SensorReading(
        device_id=device_id,
        motion_detected=data.get("motion_detected", False),
        ambient_light=data.get("ambient_light", 500),
        occupancy=data.get("occupancy", False),
        timestamp=now
    )
    db.add(reading)

    # Add Lighting History
    history = LightingHistory(
        device_id=device_id,
        lighting_status=data.get("light_status", False),
        brightness=data.get("brightness", 0),
        operating_mode=data.get("mode", "AUTO"),
        timestamp=now
    )
    db.add(history)

    # Compute and record Energy Usage
    rated_power = 10.0
    if device.settings:
        rated_power = device.settings.led_rated_power_watts

    duty = data.get("brightness", 0) if data.get("light_status", False) else 0
    current_watts = (duty / 100.0) * rated_power
    # 0.5 second interval energy in Watt-hours: watts * (0.5 / 3600)
    delta_wh = current_watts * (0.5 / 3600.0)

    energy = EnergyUsage(
        device_id=device_id,
        estimated_power_watts=round(current_watts, 2),
        estimated_energy_wh=round(delta_wh, 5),
        timestamp=now
    )
    db.add(energy)

    db.commit()
