# ESP32 IoT Gateway for FPGA Smart Room Lighting System

## 1. Overview
The ESP32 module acts as the bridging gateway between the physical FPGA UART bus (115200 baud) and the local Wi-Fi network, translating binary packets into JSON for the FastAPI backend and React web dashboard.

## 2. Hardware Wiring to FPGA
- `ESP32 GPIO 16 (RX2)` <---> `FPGA Pmod JB Pin 1 (UART TX)`
- `ESP32 GPIO 17 (TX2)` <---> `FPGA Pmod JB Pin 2 (UART RX)`
- `ESP32 GND`           <---> `FPGA GND (Common Ground)`

## 3. Flashing Instructions (PlatformIO / Arduino IDE)
1. In `src/config.h`, set your local Wi-Fi SSID and Password, and replace `BACKEND_HOST` with your computer's local IP address (e.g. `192.168.1.100`).
2. Build and upload using PlatformIO:
   ```bash
   pio run --target upload
   pio device monitor
   ```
   Or open `src/main.cpp` in Arduino IDE, install libraries (`ArduinoJson`, `WebSockets`), select board "ESP32 Dev Module", and click **Upload**.
