from sqlalchemy import Column, Integer, String, Boolean, Float, DateTime, ForeignKey, Index
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from app.database import Base

def utc_now():
    return datetime.now(timezone.utc)

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=utc_now)

    devices = relationship("Device", back_populates="owner", cascade="all, delete-orphan")

class Device(Base):
    __tablename__ = "devices"

    id = Column(String(50), primary_key=True, index=True) # e.g. "ROOM_001"
    device_name = Column(String(100), default="Smart Room Controller")
    room_name = Column(String(100), default="Living Lab Room")
    device_status = Column(String(30), default="ONLINE") # ONLINE, OFFLINE, SIMULATED
    last_seen = Column(DateTime, default=utc_now)
    created_at = Column(DateTime, default=utc_now)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    owner = relationship("User", back_populates="devices")
    sensor_readings = relationship("SensorReading", back_populates="device", cascade="all, delete-orphan")
    lighting_history = relationship("LightingHistory", back_populates="device", cascade="all, delete-orphan")
    energy_records = relationship("EnergyUsage", back_populates="device", cascade="all, delete-orphan")
    settings = relationship("DeviceSettings", back_populates="device", uselist=False, cascade="all, delete-orphan")

class SensorReading(Base):
    __tablename__ = "sensor_readings"

    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String(50), ForeignKey("devices.id"), nullable=False, index=True)
    motion_detected = Column(Boolean, default=False)
    ambient_light = Column(Integer, default=500) # 0 to 1023 ADC reading
    occupancy = Column(Boolean, default=False)
    timestamp = Column(DateTime, default=utc_now, index=True)

    device = relationship("Device", back_populates="sensor_readings")

    __table_args__ = (
        Index("idx_sensor_device_time", "device_id", "timestamp"),
    )

class LightingHistory(Base):
    __tablename__ = "lighting_history"

    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String(50), ForeignKey("devices.id"), nullable=False, index=True)
    lighting_status = Column(Boolean, default=False)
    brightness = Column(Integer, default=0) # 0 to 100 (%)
    operating_mode = Column(String(20), default="AUTO") # AUTO, MANUAL_ON, MANUAL_OFF
    timestamp = Column(DateTime, default=utc_now, index=True)

    device = relationship("Device", back_populates="lighting_history")

    __table_args__ = (
        Index("idx_lighting_device_time", "device_id", "timestamp"),
    )

class EnergyUsage(Base):
    __tablename__ = "energy_usage"

    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String(50), ForeignKey("devices.id"), nullable=False, index=True)
    estimated_power_watts = Column(Float, default=0.0)
    estimated_energy_wh = Column(Float, default=0.0)
    timestamp = Column(DateTime, default=utc_now, index=True)

    device = relationship("Device", back_populates="energy_records")

    __table_args__ = (
        Index("idx_energy_device_time", "device_id", "timestamp"),
    )

class DeviceSettings(Base):
    __tablename__ = "device_settings"

    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String(50), ForeignKey("devices.id"), unique=True, nullable=False)
    light_threshold_dark = Column(Integer, default=350)
    light_threshold_bright = Column(Integer, default=700)
    default_brightness = Column(Integer, default=100)
    shutdown_timeout = Column(Integer, default=30) # seconds
    energy_saving_enabled = Column(Boolean, default=True)
    led_rated_power_watts = Column(Float, default=10.0) # 10W standard fixture
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now)

    device = relationship("Device", back_populates="settings")
