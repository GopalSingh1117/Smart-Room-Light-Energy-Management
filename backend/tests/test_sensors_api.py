from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_sensor_latest():
    resp = client.get("/api/sensors/latest")
    assert resp.status_code == 200
    data = resp.json()
    assert "ambient_light" in data
    assert "motion_detected" in data

def test_sensor_history():
    resp = client.get("/api/sensors/history?limit=10")
    assert resp.status_code == 200
    data = resp.json()
    assert isinstance(data, list)
    assert len(data) > 0

def test_occupancy_endpoint():
    resp = client.get("/api/sensors/occupancy")
    assert resp.status_code == 200
    assert "occupancy" in resp.json()
