from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas import AnalyticsOverviewResponse
from app.services.energy_service import get_energy_analytics

router = APIRouter(prefix="/api/analytics", tags=["Analytics"])

@router.get("/energy", response_model=AnalyticsOverviewResponse)
def get_energy_overview(device_id: str = "ROOM_001", db: Session = Depends(get_db)):
    return get_energy_analytics(db, device_id)

@router.get("/daily")
def get_daily_analytics(device_id: str = "ROOM_001", db: Session = Depends(get_db)):
    data = get_energy_analytics(db, device_id)
    return {
        "device_id": device_id,
        "metric": "Daily Energy Consumption (Wh)",
        "daily_breakdown": data["daily_history"],
        "savings_percentage": data["estimated_savings_pct"]
    }

@router.get("/weekly")
def get_weekly_analytics(device_id: str = "ROOM_001", db: Session = Depends(get_db)):
    data = get_energy_analytics(db, device_id)
    return {
        "device_id": device_id,
        "weekly_total_wh": data["weekly_energy_wh"],
        "baseline_comparison_wh": 480.0 * 7,
        "savings_wh": (480.0 * 7) - data["weekly_energy_wh"]
    }

@router.get("/monthly")
def get_monthly_analytics(device_id: str = "ROOM_001", db: Session = Depends(get_db)):
    data = get_energy_analytics(db, device_id)
    return {
        "device_id": device_id,
        "monthly_total_wh": data["monthly_energy_wh"],
        "baseline_comparison_wh": 480.0 * 30,
        "cost_saved_inr": round(((480.0 * 30 - data["monthly_energy_wh"]) / 1000.0) * 8.5, 2)
    }
