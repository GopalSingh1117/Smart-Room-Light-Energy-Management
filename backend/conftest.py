import sys
import os

# Ensure backend root directory is in python search path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from app.database import Base, engine
from app.services.device_service import ensure_default_device
from app.database import SessionLocal

# Ensure tables and default device exist for testing
Base.metadata.create_all(bind=engine)
db = SessionLocal()
try:
    ensure_default_device(db)
finally:
    db.close()
