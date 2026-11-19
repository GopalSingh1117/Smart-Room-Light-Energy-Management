# REST API and WebSocket Specification

## 1. Overview
The FastAPI backend serves both RESTful HTTP endpoints for state modification and historical data retrieval, as well as a duplex WebSocket connection for real-time telemetry streaming at `/ws/dashboard`.

Base URL: `http://localhost:8000`

---

## 2. Authentication Endpoints (`/api/auth`)

### A. Register User
- **Method:** `POST /api/auth/register`
- **Request Body:**
```json
{
  "name": "Prof. Alan Turing",
  "email": "turing@university.edu",
  "password": "SecurePassword123"
}
```
- **Response (201 Created):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6...",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "name": "Prof. Alan Turing",
    "email": "turing@university.edu",
    "created_at": "2026-11-17T08:30:00Z"
  }
}
```

### B. User Login
- **Method:** `POST /api/auth/login`
- **Request Body:**
```json
{
  "email": "turing@university.edu",
  "password": "SecurePassword123"
}
```
- **Response (200 OK):** Returns JWT access token.

---

## 3. Lighting Control Endpoints (`/api/lighting`)

### A. Set Operating Mode
- **Method:** `POST /api/lighting/mode`
- **Description:** Forwards requested mode (`AUTO`, `MANUAL_ON`, `MANUAL_OFF`) to the FPGA through the ESP32 gateway.
- **Request Body:**
```json
{
  "device_id": "ROOM_001",
  "mode": "MANUAL_ON"
}
```
- **Response (200 OK):**
```json
{
  "status": "success",
  "command": "SET_MODE",
  "applied_mode": "MANUAL_ON",
  "hardware_forwarded": true
}
```

### B. Set PWM Brightness Level
- **Method:** `POST /api/lighting/brightness`
- **Request Body:**
```json
{
  "device_id": "ROOM_001",
  "brightness": 60
}
```
- **Response (200 OK):**
```json
{
  "status": "success",
  "command": "SET_BRIGHTNESS",
  "applied_brightness": 60,
  "hardware_forwarded": true
}
```

### C. Set Inactivity Shutdown Timeout
- **Method:** `POST /api/lighting/timeout`
- **Request Body:**
```json
{
  "device_id": "ROOM_001",
  "timeout_seconds": 45
}
```

### D. Get Current Lighting Status
- **Method:** `GET /api/lighting/status?device_id=ROOM_001`
- **Response (200 OK):**
```json
{
  "device_id": "ROOM_001",
  "light_status": true,
  "brightness": 60,
  "operating_mode": "AUTO",
  "motion_detected": true,
  "occupancy": true,
  "ambient_light": 280,
  "timeout_remaining": 38,
  "estimated_power_watts": 6.0,
  "hardware_connected": true,
  "last_update": "2026-11-17T08:35:10Z"
}
```

---

## 4. Sensor & Analytics Endpoints

### A. Latest Sensor Telemetry
- **Method:** `GET /api/sensors/latest`
- **Response (200 OK):**
```json
{
  "device_id": "ROOM_001",
  "motion_detected": true,
  "ambient_light": 280,
  "occupancy": true,
  "timestamp": "2026-11-17T08:35:12Z"
}
```

### B. Historical Sensor Data
- **Method:** `GET /api/sensors/history?limit=50`
- **Response (200 OK):** Array of historical sensor time-series points.

### C. Energy Analytics Overview
- **Method:** `GET /api/analytics/energy`
- **Response (200 OK):**
```json
{
  "device_id": "ROOM_001",
  "today_energy_wh": 52.4,
  "weekly_energy_wh": 348.6,
  "monthly_energy_wh": 1420.0,
  "estimated_savings_pct": 78.4,
  "daily_history": [
    {
      "label": "Mon 16",
      "energy_wh": 48.2,
      "energy_saved_wh": 431.8,
      "avg_brightness": 65.0,
      "active_hours": 4.8
    }
  ]
}
```

---

## 5. WebSocket Telemetry Stream: `/ws/dashboard`
- **Connection URL:** `ws://localhost:8000/ws/dashboard`
- **Server Push Payload:**
```json
{
  "type": "telemetry",
  "data": {
    "device_id": "ROOM_001",
    "timestamp": 1731835682.105,
    "motion_detected": true,
    "occupancy": true,
    "ambient_light": 280,
    "light_status": true,
    "brightness": 60,
    "mode": "AUTO",
    "timeout_remaining": 45,
    "estimated_power_watts": 6.0,
    "hardware_connected": true
  }
}
```
- **Client Control Commands (Duplex Upstream):**
```json
{
  "command": "SET_MODE",
  "mode": "MANUAL_ON"
}
```
