from pydantic import BaseModel, EmailStr, Field, ConfigDict
from typing import Optional, List
from datetime import datetime

# --- User Schemas ---
class UserRegister(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    password: str = Field(..., min_length=6)

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    email: str
    created_at: datetime

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

# --- Device Schemas ---
class DeviceCreate(BaseModel):
    id: str = Field(..., min_length=2, max_length=50)
    device_name: str = "Smart Room Controller"
    room_name: str = "Living Lab Room"

class DeviceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    device_name: str
    room_name: str
    device_status: str
    last_seen: datetime

# --- Lighting & Sensor Schemas ---
class ModeCommand(BaseModel):
    device_id: Optional[str] = "ROOM_001"
    mode: str = Field(..., pattern="^(AUTO|MANUAL_ON|MANUAL_OFF)$")

class PowerCommand(BaseModel):
    device_id: Optional[str] = "ROOM_001"
    power: bool

class BrightnessCommand(BaseModel):
    device_id: Optional[str] = "ROOM_001"
    brightness: int = Field(..., ge=0, le=100)

class TimeoutCommand(BaseModel):
    device_id: Optional[str] = "ROOM_001"
    timeout_seconds: int = Field(..., ge=5, le=1800)

class EnergySavingCommand(BaseModel):
    device_id: Optional[str] = "ROOM_001"
    enabled: bool

class TelemetryPayload(BaseModel):
    device_id: str = "ROOM_001"
    motion_detected: bool
    occupancy: bool
    ambient_light: int = Field(..., ge=0, le=1023)
    light_status: bool
    brightness: int = Field(..., ge=0, le=100)
    mode: str = "AUTO"
    timeout_remaining: int = 30
    estimated_power_watts: Optional[float] = 0.0
    hardware_connected: bool = True

class LightingStatusResponse(BaseModel):
    device_id: str
    light_status: bool
    brightness: int
    operating_mode: str
    motion_detected: bool
    occupancy: bool
    ambient_light: int
    timeout_remaining: int
    estimated_power_watts: float
    hardware_connected: bool
    last_update: datetime

# --- Settings Schemas ---
class SettingsUpdate(BaseModel):
    room_name: Optional[str] = None
    light_threshold_dark: Optional[int] = Field(None, ge=50, le=900)
    light_threshold_bright: Optional[int] = Field(None, ge=100, le=1023)
    default_brightness: Optional[int] = Field(None, ge=10, le=100)
    shutdown_timeout: Optional[int] = Field(None, ge=5, le=1800)
    energy_saving_enabled: Optional[bool] = None
    led_rated_power_watts: Optional[float] = Field(None, gt=0, le=500)

class SettingsResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    device_id: str
    room_name: str
    light_threshold_dark: int
    light_threshold_bright: int
    default_brightness: int
    shutdown_timeout: int
    energy_saving_enabled: bool
    led_rated_power_watts: float

# --- Analytics Schemas ---
class EnergyPoint(BaseModel):
    label: str
    energy_wh: float
    energy_saved_wh: float
    avg_brightness: float
    active_hours: float

class AnalyticsOverviewResponse(BaseModel):
    device_id: str
    today_energy_wh: float
    weekly_energy_wh: float
    monthly_energy_wh: float
    estimated_savings_pct: float
    daily_history: List[EnergyPoint]
