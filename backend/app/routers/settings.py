from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timezone

from app.database import get_db
from app.models import Device, DeviceSettings
from app.schemas import SettingsUpdate, SettingsResponse
from app.services.device_service import ensure_default_device
from app.services.simulation_service import simulator
from app.services.communication_service import gateway

router = APIRouter(prefix="/api/settings", tags=["Settings"])

@router.get("", response_model=SettingsResponse)
def get_settings(device_id: str = "ROOM_001", db: Session = Depends(get_db)):
    device = ensure_default_device(db)
    st = device.settings
    return {
        "device_id": device.id,
        "room_name": device.room_name,
        "light_threshold_dark": st.light_threshold_dark,
        "light_threshold_bright": st.light_threshold_bright,
        "default_brightness": st.default_brightness,
        "shutdown_timeout": st.shutdown_timeout,
        "energy_saving_enabled": st.energy_saving_enabled,
        "led_rated_power_watts": st.led_rated_power_watts
    }

@router.put("", response_model=SettingsResponse)
def update_settings(update_data: SettingsUpdate, device_id: str = "ROOM_001", db: Session = Depends(get_db)):
    device = ensure_default_device(db)
    st = device.settings

    if update_data.room_name is not None:
        device.room_name = update_data.room_name
    if update_data.light_threshold_dark is not None:
        st.light_threshold_dark = update_data.light_threshold_dark
        simulator.thresh_dark = update_data.light_threshold_dark
    if update_data.light_threshold_bright is not None:
        st.light_threshold_bright = update_data.light_threshold_bright
        simulator.thresh_bright = update_data.light_threshold_bright
    if update_data.default_brightness is not None:
        st.default_brightness = update_data.default_brightness
    if update_data.shutdown_timeout is not None:
        st.shutdown_timeout = update_data.shutdown_timeout
        simulator.set_timeout(update_data.shutdown_timeout)
        if gateway.is_connected:
            gateway.send_timeout(update_data.shutdown_timeout)
    if update_data.energy_saving_enabled is not None:
        st.energy_saving_enabled = update_data.energy_saving_enabled
        simulator.set_energy_saving(update_data.energy_saving_enabled)
        if gateway.is_connected:
            gateway.send_energy_saving(update_data.energy_saving_enabled)
    if update_data.led_rated_power_watts is not None:
        st.led_rated_power_watts = update_data.led_rated_power_watts

    st.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(st)
    db.refresh(device)

    return {
        "device_id": device.id,
        "room_name": device.room_name,
        "light_threshold_dark": st.light_threshold_dark,
        "light_threshold_bright": st.light_threshold_bright,
        "default_brightness": st.default_brightness,
        "shutdown_timeout": st.shutdown_timeout,
        "energy_saving_enabled": st.energy_saving_enabled,
        "led_rated_power_watts": st.led_rated_power_watts
    }
