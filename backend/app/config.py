from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    APP_NAME: str = "Smart Automatic Room Light & Energy Management Backend"
    DEBUG: bool = True
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    SECRET_KEY: str = "super-secret-jwt-key-replace-in-production-fpga-iot-2026"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440

    DATABASE_URL: str = "sqlite:///./smart_room_system.db"

    SERIAL_PORT: str = "COM3"
    BAUD_RATE: int = 115200
    ENABLE_HARDWARE_SERIAL: bool = False
    ENABLE_SIMULATION_FALLBACK: bool = True
    DEFAULT_DEVICE_ID: str = "ROOM_001"

settings = Settings()
