# System Architecture: Smart Automatic Room Light and Energy Management System

## 1. System Overview and Core Philosophy

The Smart Automatic Room Light and Energy Management System combines deterministic hardware real-time control (FPGA) with edge IoT telemetry (ESP32) and modern web technologies (FastAPI + React).

### Edge Autonomy Principle
The fundamental design rule of this cyber-physical system is **Autonomous Edge Priority**:
- The **FPGA is the primary, self-contained lighting controller**. It samples sensors (PIR and LDR via ADC), runs the 8-state lighting Finite State Machine (FSM), generates PWM brightness levels, regulates occupancy countdown timers, controls local seven-segment status displays, and responds instantly to physical button overrides.
- Lighting control, human presence response, and darkness detection **do not depend on Wi-Fi, internet connectivity, or backend servers**.
- If the ESP32 gateway loses Wi-Fi or the cloud server goes offline, the FPGA continues to operate automatically without interruption or latency.

---

## 2. Multi-Tier Structural Architecture

```
+-------------------------------------------------------------------------+
|                         PHYSICAL ROOM ENVIRONMENT                       |
|   +--------------------+     +-------------------+     +------------+   |
|   | PIR Motion Sensor  |     | LDR Light Sensor  |     | LED Load   |   |
|   |     (HC-SR501)     |     |    + MCP3008 ADC  |     | + MOSFET   |   |
|   +---------+----------+     +---------+---------+     +-----^------+   |
+-------------|--------------------------|---------------------|----------+
              |                          |                     |
              | 3.3V Digital Pulse       | SPI Bus (10-bit)    | PWM (0-100%)
              v                          v                     |
+--------------------------------------------------------------+----------+
|                  FPGA HARDWARE TIER (Verilog HDL Core)                  |
|                                                                         |
|   +---------------------+   +-----------------------+                   |
|   | Synchronizer/Debounce|   | ldr_adc_interface.v   |                   |
|   +----------+----------+   +-----------+-----------+                   |
|              |                          |                               |
|              v                          v                               |
|   +---------------------+   +-----------------------+                   |
|   |   pir_detector.v    |   |light_sensor_classifier|                   |
|   +----------+----------+   +-----------+-----------+                   |
|              |                          |                               |
|              +------------+   +---------+                               |
|                           |   |                                         |
|                           v   v                                         |
|                 +-----------------------+                               |
|                 |   light_controller.v  |<----+ manual_override.v       |
|                 |      (8-State FSM)    |     | (Local btn / UART cmd)  |
|                 +-----+-----------+-----+     +-------------------------+
|                       |           |                                     |
|                       v           v                                     |
|              +------------+  +-----------------+  +-------------------+ |
|              |pwm_generatr|  |occupancy_timer.v|  |seven_segment_dec.v| |
|              +-----+------+  +-----------------+  +-------------------+ |
|                    |                  |                                 |
|                    v                  v                                 |
|              +------------+  +-----------------+                        |
|              |energy_count|  |uart_tx / uart_rx|                        |
|              +------------+  +--------+--------+                        |
+---------------------------------------|---------------------------------+
                                        | 115200 Baud Full-Duplex UART
                                        | Framed binary packets with XOR CRC
                                        v
+-------------------------------------------------------------------------+
|                 IOT GATEWAY TIER (ESP32 Microcontroller)               |
|                                                                         |
|   +-----------------------------------------------------------------+   |
|   | Hardware UART Packet Parser <-> Validation Engine               |   |
|   +--------------------------------+--------------------------------+   |
|                                    |                                    |
|   +--------------------------------+--------------------------------+   |
|   | Wi-Fi 802.11 b/g/n Client <-> JSON Serialization / Deserializer |   |
|   +--------------------------------+--------------------------------+   |
|                                    |                                    |
|   +--------------------------------+--------------------------------+   |
|   | WebSocket Client (/ws/dashboard) & HTTP REST Telemetry Push     |   |
|   +-----------------------------------------------------------------+   |
+------------------------------------|------------------------------------+
                                     | WebSocket WSS / HTTP REST
                                     | JSON Telemetry & Control Packets
                                     v
+-------------------------------------------------------------------------+
|                BACKEND TIER (Python FastAPI + SQLite)                   |
|                                                                         |
|   +-----------------------------------------------------------------+   |
|   | FastAPI ASGI Server (Uvicorn) with Lifespan Tasks               |   |
|   +--------------------------------+--------------------------------+   |
|   | Central WebSocket Broadcast Hub (/ws/dashboard)                 |   |
|   +--------------------------------+--------------------------------+   |
|   | REST Endpoints: /api/lighting, /api/sensors, /api/analytics     |   |
|   +--------------------------------+--------------------------------+   |
|   | Energy Calculation Engine (P = P_rated * Duty, Wh = P * dt / 3600)| |
|   +--------------------------------+--------------------------------+   |
|   | SQLAlchemy ORM Models (Users, Devices, Sensors, History, Energy)|   |
|   +--------------------------------+--------------------------------+   |
|   | Virtual Hardware Simulation Engine (Fallback & Test Mode)       |   |
|   +-----------------------------------------------------------------+   |
+------------------------------------|------------------------------------+
                                     | Bidirectional WebSocket & REST
                                     v
+-------------------------------------------------------------------------+
|               FRONTEND TIER (React 19 + Vite + Tailwind CSS)            |
|                                                                         |
|   +-----------------------------------------------------------------+   |
|   | Dashboard Overview (Room Visualizer, Light Bulb SVG, Quick Ctrl)|   |
|   | Live Monitoring (Real-time lux and brightness line charts)      |   |
|   | Lighting Control Panel (Auto / Manual ON / Manual OFF, Sliders) |   |
|   | Energy Analytics (Recharts Daily/Weekly/Monthly Bars, Savings %) |   |
|   | Device Management (Hardware connection status & diagnostics)    |   |
|   | System Settings (Thresholds, Timeouts, Energy power ratings)    |   |
|   | Virtual Simulation Dock (Interactive hardware test control bar) |   |
|   +-----------------------------------------------------------------+   |
+-------------------------------------------------------------------------+
```

---

## 3. Finite State Machine (FSM) Design

The primary lighting logic resides in `light_controller.v` as an 8-state Moore/Mealy hybrid FSM:

1. **`IDLE` (State 000):** Initial state upon reset. Room unoccupied, lights OFF ($0\%$). Inactivity counter cleared.
2. **`DAYLIGHT` (State 001):** Room occupied or vacant, but ambient light reading exceeds `BRIGHT_THRESHOLD`. Lighting remains OFF ($0\%$) to conserve energy.
3. **`OCCUPIED` (State 010):** Motion pulse detected by PIR while ambient light is Dark or Medium. Transition stage where the system initializes occupancy timer and transitions to active lighting.
4. **`LIGHT_ON` (State 011):** Room is occupied in a dark environment. PWM output set to $100\%$ (HIGH brightness). Occupancy timer reloaded to configured timeout (e.g., 30 seconds).
5. **`DIMMED` (State 100):** Medium ambient light detected while occupied, OR auto-shutdown inactivity pre-warning phase (when remaining timeout $\le 20\%$). PWM output set to $30\%$ (LOW) or $60\%$ (MEDIUM).
6. **`TIMEOUT` (State 101):** Occupancy timer reaches zero without further motion pulses. Lights switch OFF ($0\%$) and system returns to `IDLE`.
7. **`MANUAL_ON` (State 110):** User forces lights ON via dashboard or hardware toggle switch. Sensor overrides are bypassed; PWM is set to user-selected brightness ($10\%-100\%$).
8. **`MANUAL_OFF` (State 111):** User forces lights OFF via dashboard or hardware toggle switch. Sensor triggers are ignored; PWM output is clamped at $0\%$.

---

## 4. Hardware Parameters & Timing Constants

- **System Clock:** Default $100\text{ MHz}$ ($T_{clk} = 10\text{ ns}$). Can be scaled down to $50\text{ MHz}$ for Altera/Intel boards via Verilog parameters.
- **Debounce Period:** $20\text{ ms}$ ($2,000,000$ clock cycles at $100\text{ MHz}$).
- **PWM Frequency:** $1\text{ kHz}$ to $20\text{ kHz}$ (8-bit resolution, $256$ steps, prescaled clock). Completely flicker-free and silent.
- **Seven-Segment Multiplexing Frequency:** $1\text{ kHz}$ total display refresh ($250\text{ Hz}$ per digit refresh rate, avoiding visual flicker).
- **UART Baud Rate:** 115,200 baud ($\text{Divisor} = 100,000,000 / 115200 \approx 868$).
- **Telemetry Update Interval:** Periodic transmission at $2\text{ Hz}$ or immediate transmission upon state/event change.
