# Smart Automatic Room Light and Energy Management System
### *Verilog HDL • FPGA (Artix-7) • IoT Gateway (ESP32) • Python FastAPI • React 19 Dashboard*

![Project Architecture](https://img.shields.io/badge/Architecture-Cyber--Physical%20Edge%20IoT-indigo)
![Verilog HDL](https://img.shields.io/badge/Hardware-Verilog%20HDL%20(IEEE%201364--2001)-blue)
![Backend](https://img.shields.io/badge/Backend-FastAPI%20%2B%20SQLAlchemy-emerald)
![Frontend](https://img.shields.io/badge/Frontend-React%2019%20%2B%20Tailwind-sky)
![Tests](https://img.shields.io/badge/Tests-11%2F11%20Passed-brightgreen)

A complete, production-grade academic engineering project demonstrating the seamless integration of **Digital Logic Design (FPGA)**, **Embedded Systems & IoT (ESP32)**, **Cloud API Backends (FastAPI)**, and **Interactive Web User Interfaces (React)**.

---

## 1. System Architecture Overview

```
 [ PIR Motion Sensor ]          [ LDR Lux Sensor + MCP3008 ADC ]
          │                                   │
          ▼                                   ▼
 ┌──────────────────────────────────────────────────────────────┐
 │             FPGA HARDWARE CORE (Verilog HDL)                 │
 │  • 2-Stage Synchronizers & Debouncers                        │
 │  • 8-State Lighting Finite State Machine (FSM)               │
 │  • 5 kHz Flicker-Free PWM Generator (0%, 30%, 60%, 100%)     │
 │  • Programmable Inactivity Countdown Timer                   │
 │  • 4-Digit 7-Segment Multiplexed Status Display              │
 │  • Framed Binary UART Transceiver (115,200 baud, XOR CRC)    │
 └──────────────────────────────┬───────────────────────────────┘
                                │ Full-Duplex UART
                                ▼
 ┌──────────────────────────────────────────────────────────────┐
 │              ESP32 IoT COMMUNICATIONS GATEWAY                │
 │  • Binary Frame Parser & CRC Validator                       │
 │  • Bidirectional Wi-Fi WebSocket & REST Bridge               │
 └──────────────────────────────┬───────────────────────────────┘
                                │ WSS / HTTP REST
                                ▼
 ┌──────────────────────────────────────────────────────────────┐
 │            PYTHON FASTAPI BACKEND & SQLITE DATABASE          │
 │  • Relational Telemetry & Energy Persistence                 │
 │  • Real-Time Broadcast Hub (/ws/dashboard)                   │
 │  • High-Fidelity Virtual Hardware Simulator (Fallback Mode)  │
 └──────────────────────────────┬───────────────────────────────┘
                                │ Live Bi-directional Sync
                                ▼
 ┌──────────────────────────────────────────────────────────────┐
 │              REACT 19 + VITE + TAILWIND DASHBOARD            │
 │  • Room Digital Twin & Glowing Bulb Graphic Visualizer       │
 │  • Live Strip Charts (Lux vs PWM Dimming)                    │
 │  • Dedicated Control Console (Auto / Manual ON / Manual OFF) │
 │  • Recharts Energy Analytics & Estimated Cost Savings        │
 │  • Interactive Virtual Hardware Test Dock (Simulation Bar)   │
 └──────────────────────────────────────────────────────────────┘
```

---

## 2. Project Directory Structure

```
smart-room-light-system/
│
├── hardware/                    # FPGA Verilog Design & Simulation
│   ├── rtl/                     # 12 Modular synthesizable Verilog modules
│   ├── testbench/               # Complete behavioral simulation testbenches
│   ├── constraints/             # Digilent Basys 3 XDC & generic pinouts
│   └── README.md
│
├── esp32_gateway/               # ESP32 IoT Communication Gateway
│   ├── src/                     # C++ PlatformIO firmware & UART bridge
│   ├── platformio.ini           # Build and upload settings
│   └── README.md
│
├── backend/                     # Python FastAPI Backend & Emulator
│   ├── app/                     # Routers, ORM models, schemas, services
│   ├── tests/                   # Automated pytest suite (11/11 passing)
│   ├── requirements.txt
│   ├── .env.example
│   └── README.md
│
├── frontend/                    # Modern React 19 + Vite Web Dashboard
│   ├── src/                     # 6 pages, context providers, layout, components
│   ├── package.json
│   ├── vite.config.js
│   ├── tailwind.config.js
│   └── README.md
│
├── docs/                        # Complete Academic Documentation
│   ├── architecture.md          # Multi-tier system architecture
│   ├── circuit_diagram.md       # Full electrical schematic & pinout guide
│   ├── communication_protocol.md# Framed binary UART and JSON protocol
│   ├── api_documentation.md     # OpenAPI & WebSocket reference
│   └── project_report.md        # Comprehensive 24-section B.Tech project report
│
└── README.md                    # Master overview and quickstart guide
```

---

## 3. Quick Start Guide

### A. Run Backend Server (FastAPI)
```bash
cd smart-room-light-system/backend
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
- API Docs: [http://localhost:8000/docs](http://localhost:8000/docs)
- WebSocket: `ws://localhost:8000/ws/dashboard`

### B. Run Frontend Dashboard (React + Vite)
```bash
cd smart-room-light-system/frontend
npm install
npm run dev
```
- Open [http://localhost:5173](http://localhost:5173) in your browser.

### C. Run Backend Automated Test Suite
```bash
cd smart-room-light-system/backend
pytest tests/ -v
```

### D. Simulate Verilog Hardware in Vivado
1. Create a project in Xilinx Vivado targeting Digilent Basys 3 (`xc7a35tcpg236-1`).
2. Add all `.v` files from `hardware/rtl/` and testbenches from `hardware/testbench/`.
3. Set `tb_top_system` as the top simulation module and run behavioral simulation.

---

## 4. Key Highlights & Features
- **Deterministic Edge Priority:** Even if Wi-Fi or backend disconnects, the FPGA continues autonomous room lighting and motion countdowns without delay.
- **Dual-Mode Operation:** Built-in **Simulation Mode** allows live interactive testing directly from the web browser without requiring physical FPGA hardware attached!
- **Over 75% Energy Reduction:** Proportional PWM dimming combined with occupancy timeouts drastically lowers kilowatt-hour consumption.
