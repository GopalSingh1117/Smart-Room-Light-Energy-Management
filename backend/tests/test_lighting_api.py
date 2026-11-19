from fastapi.testclient import TestClient
from app.main import app
from app.services.simulation_service import simulator

client = TestClient(app)

def test_root_endpoint():
    resp = client.get("/")
    assert resp.status_code == 200
    data = resp.json()
    assert "status" in data
    assert data["status"] == "ONLINE"

def test_lighting_status():
    resp = client.get("/api/lighting/status")
    assert resp.status_code == 200
    data = resp.json()
    assert "device_id" in data
    assert "operating_mode" in data

def test_lighting_mode_control():
    resp = client.post("/api/lighting/mode", json={"mode": "MANUAL_ON"})
    assert resp.status_code == 200
    assert resp.json()["applied_mode"] == "MANUAL_ON"

    # Reset to AUTO
    client.post("/api/lighting/mode", json={"mode": "AUTO"})

def test_brightness_control():
    resp = client.post("/api/lighting/brightness", json={"brightness": 60})
    assert resp.status_code == 200
    assert resp.json()["applied_brightness"] == 60

def test_simulation_event_injection():
    resp = client.post("/api/lighting/simulate", json={"motion": True, "ambient_light": 180})
    assert resp.status_code == 200
    telemetry = resp.json()["telemetry"]
    assert telemetry["motion_detected"] is True
    assert telemetry["ambient_light"] == 180
