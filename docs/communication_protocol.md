# Communication Protocol Specification: FPGA <-> ESP32 <-> Backend

## 1. Physical Layer Specifications
- **Interface:** Asynchronous Serial (UART)
- **Baud Rate:** 115,200 bps
- **Data Bits:** 8
- **Parity:** None (N)
- **Stop Bits:** 1
- **Flow Control:** None (Hardware pacing handled via checksum verification and ACK responses)
- **Signal Logic Level:** 3.3V LVCMOS

---

## 2. FPGA <-> ESP32 Binary Packet Protocol

To ensure reliability without relying on complex string parsing inside the FPGA Verilog logic, communication over the UART wire uses a **fixed-structure framed binary protocol**.

### Frame Structure

```
+--------+--------+--------+--------+------------------+----------+--------+--------+
| SOF 1  | SOF 2  | LENGTH | OPCODE | PAYLOAD (N bytes)| CHECKSUM | EOF 1  | EOF 2  |
| (0xAA) | (0x55) | 1 Byte | 1 Byte |      0..16 B     |  1 Byte  | (0x0D) | (0x0A) |
+--------+--------+--------+--------+------------------+----------+--------+--------+
```

### Field Definitions
1. **SOF 1 & 2 (`0xAA 0x55`):** Two constant synchronization bytes. If a receiver gets out of sync, it shifts bytes until it re-detects the `0xAA 0x55` header sequence.
2. **LENGTH (1 Byte):** Defines the exact number of bytes in the `PAYLOAD` field ($N$). Maximum length = 16 bytes.
3. **OPCODE (1 Byte):** Command or telemetry message identifier.
4. **PAYLOAD ($N$ Bytes):** Command parameters or telemetry sensor fields.
5. **CHECKSUM (1 Byte):** Longitudinal Redundancy Check (LRC) calculated as:
   $$\text{Checksum} = \text{LENGTH} \oplus \text{OPCODE} \oplus \bigoplus_{i=0}^{N-1} \text{PAYLOAD}[i]$$
6. **EOF 1 & 2 (`0x0D 0x0A` / `\r\n`):** End-of-frame markers.

---

## 3. Opcode & Payload Tables

### A. Telemetry Packet (`OPCODE = 0x01` | Direction: FPGA -> ESP32)
- **Length:** `0x08` (8 bytes)
- **Transmission:** Sent periodically every 500 ms or immediately upon sensor state transition.

| Byte Offset | Field Name | Data Type | Value Range | Description |
| :--- | :--- | :--- | :--- | :--- |
| `0` | `motion_detected` | `uint8` | `0` or `1` | Real-time PIR motion output |
| `1` | `occupancy_state` | `uint8` | `0` or `1` | Filtered room occupancy condition |
| `2` | `ambient_lux_msb` | `uint8` | `0x00 - 0x03` | Upper 2 bits of 10-bit ADC reading |
| `3` | `ambient_lux_lsb` | `uint8` | `0x00 - 0xFF` | Lower 8 bits of 10-bit ADC reading |
| `4` | `light_status` | `uint8` | `0` (OFF), `1` (ON) | Current physical lighting state |
| `5` | `brightness_pct` | `uint8` | `0` to `100` | PWM duty cycle percentage |
| `6` | `operating_mode` | `uint8` | `0`, `1`, `2` | `0`=AUTO, `1`=MANUAL_ON, `2`=MANUAL_OFF |
| `7` | `timer_remaining`| `uint8` | `0` to `255` | Countdown seconds remaining before shutdown |

### B. Mode Control Command (`OPCODE = 0x02` | Direction: ESP32 -> FPGA)
- **Length:** `0x01` (1 byte)
- **Payload[0]:** `0x00` (AUTO), `0x01` (MANUAL_ON), `0x02` (MANUAL_OFF)

### C. Brightness Control Command (`OPCODE = 0x03` | Direction: ESP32 -> FPGA)
- **Length:** `0x01` (1 byte)
- **Payload[0]:** Duty cycle percentage (`0` to `100`).

### D. Inactivity Timeout Command (`OPCODE = 0x04` | Direction: ESP32 -> FPGA)
- **Length:** `0x02` (2 bytes, 16-bit Big-Endian integer)
- **Payload[0..1]:** Timeout duration in seconds ($5$ to $1800\text{ s}$).

### E. Energy-Saving Mode Command (`OPCODE = 0x05` | Direction: ESP32 -> FPGA)
- **Length:** `0x01` (1 byte)
- **Payload[0]:** `0x01` (Enable aggressive daylight dimming), `0x00` (Standard dimming).

### F. Command Acknowledgement (`OPCODE = 0x06` | Direction: FPGA -> ESP32)
- **Length:** `0x02` (2 bytes)
- **Payload[0]:** Acknowledged Opcode.
- **Payload[1]:** Status (`0x00` = Success/Applied, `0xFF` = Invalid/Rejected).

---

## 4. ESP32 <-> Backend JSON Schema

### A. Live Telemetry Stream (`/ws/dashboard` or HTTP POST `/api/devices/telemetry`)
```json
{
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
```

### B. Dashboard Control Command (Sent via WebSocket or REST)
```json
{
  "command": "SET_MODE",
  "device_id": "ROOM_001",
  "mode": "MANUAL_ON",
  "request_id": "req-9821"
}
```
Supported commands:
- `SET_MODE`: payload `{"mode": "AUTO" | "MANUAL_ON" | "MANUAL_OFF"}`
- `SET_BRIGHTNESS`: payload `{"brightness": 0..100}`
- `SET_TIMEOUT`: payload `{"timeout_seconds": 5..1800}`
- `SET_ENERGY_SAVING`: payload `{"enabled": true | false}`
