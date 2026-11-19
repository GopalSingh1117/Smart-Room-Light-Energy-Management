# Python FastAPI Backend & Energy Service

## 1. Overview
The backend provides REST APIs, database persistence via SQLAlchemy + SQLite, JWT authentication, energy integration, and a real-time WebSocket connection hub (`/ws/dashboard`) interfacing with the ESP32 IoT gateway or the built-in hardware simulator.

## 2. Installation and Execution

### Step 1: Install Dependencies
```bash
pip install -r requirements.txt
```

### Step 2: Configure Environment
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

### Step 3: Launch Server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
Open [http://localhost:8000/docs](http://localhost:8000/docs) in your browser to inspect interactive Swagger / OpenAPI documentation.

### Step 4: Run Automated Tests
```bash
pytest tests/ -v
```
