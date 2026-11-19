# Circuit Diagram and Electrical Hardware Interfacing

## 1. Schematic and Interconnection Overview

This document details the physical electrical wiring, signal levels, component ratings, and circuit interfaces connecting the FPGA board (e.g. Digilent Basys 3 Artix-7), the ESP32 IoT Gateway, external sensors, and the LED power driver stage.

```
                            +-------------------------------------------+
                            |            +12V DC External Supply        |
                            +-----+-------------------------------------+
                                  |
                                  | (+) 12V Rail
                                  v
                            +-------------+
                            |  12V LED    |
                            | Light Strip |
                            +------+------+
                                   | (-)
                                   v
             +3.3V FPGA     +-------------+ Drain
             Power Rail     | IRLZ44N     |
                  |         | Power       |
                  |         | MOSFET      |
                  |         +------+------+
     +------------+------+         | Source
     |                   |         v
     |   FPGA I/O Pin    |---> [220 Ohm] ---> Gate
     |   (PWM Output)    |         |
     |                   |     [10k Ohm] Pull-Down to GND
     +-------------------+         |
                                   v
                             System GND (Common Ground)
```

---

## 2. Sensor & Actuator Interfacing Details

### A. PIR Motion Sensor (HC-SR501)
- **Operating Voltage:** $4.5\text{V} - 12\text{V}$ (powered from the FPGA board's $5\text{V}$ pin or external $5\text{V}$).
- **Output Logic Level:** $3.3\text{V}$ TTL HIGH when motion is detected, $0\text{V}$ LOW when idle.
- **Connection to FPGA:** Direct connection to an FPGA $3.3\text{V}$ LVCMOS Pmod digital input pin.
- **Protection & Conditioning:**
  - Input passes through an internal 2-stage D-type flip-flop synchronizer inside the FPGA to eliminate metastability.
  - A digital filter rejects noise spikes shorter than $10\text{ ms}$.

### B. Ambient Light Sensor (GL5528 LDR + MCP3008 10-bit SPI ADC)
Because FPGAs do not have internal general-purpose analog inputs (or XADC setup requires custom analog headers), a standard Microchip MCP3008 8-channel 10-bit SPI ADC is used.
- **LDR Voltage Divider:**
  - $V_{CC} = 3.3\text{V}$.
  - $10\text{ k}\Omega$ metal film precision resistor in series with GL5528 LDR to GND.
  - Junction node connected to `CH0` (Pin 1) of the MCP3008 ADC.
  - Dark condition: LDR resistance $\approx 1\text{ M}\Omega \to V_{in} \approx 0.03\text{V}$ (ADC counts $< 100$).
  - Bright condition: LDR resistance $\approx 1-2\text{ k}\Omega \to V_{in} \approx 2.7\text{V}-3.0\text{V}$ (ADC counts $> 850$).
- **MCP3008 to FPGA SPI Connection:**
  - `CS_N` (Chip Select, active low) $\to$ FPGA Pmod Pin 1
  - `MOSI` (Master Out Slave In) $\to$ FPGA Pmod Pin 2
  - `MISO` (Master In Slave Out) $\to$ FPGA Pmod Pin 3
  - `SCLK` (SPI Serial Clock, $1\text{ MHz}$) $\to$ FPGA Pmod Pin 4
  - $V_{DD}$ and $V_{REF} \to +3.3\text{V}$
  - $AGND$ and $DGND \to \text{GND}$

### C. High-Power LED Dimming Driver Stage
- **Component:** Logic-level N-channel Power MOSFET (IRLZ44N or AO3400).
- **Threshold Voltage:** $V_{GS(th)} = 1.0\text{V} - 2.0\text{V}$ ensures full conduction directly from the FPGA $3.3\text{V}$ logic pin without requiring a separate pre-driver transistor.
- **Gate Resistor:** $220\,\Omega$ series resistor limits transient peak charging current drawn from the FPGA I/O pin.
- **Gate-to-Source Pull-Down:** $10\text{ k}\Omega$ resistor ensures the MOSFET remains securely OFF during FPGA power-on reset and bitstream configuration.
- **Flyback Diode (Optional / Inductive loads):** 1N4007 or SS34 across LED terminals if driving inductive fixtures.

### D. 4-Digit Seven-Segment Display
- **Type:** Multiplexed Common Anode or Common Cathode display (Default: Basys 3 onboard Common Anode).
- **Cathode Segment Lines (`seg[6:0]`, `dp`):** 7 segment lines connected through $330\,\Omega$ current-limiting resistors ($I_{segment} \approx 5\text{ mA}$).
- **Anode Enable Lines (`an[3:0]`):** 4 active-low PNP transistor/P-channel MOSFET drivers on the board.

### E. FPGA to ESP32 UART Serial Gateway
- **Logic Level:** Both FPGA (Artix-7 LVCMOS33) and ESP32 operate at $3.3\text{V}$ logic levels. **No voltage level-shifter is required.**
- **Wiring:**
  - `FPGA_TX` (Pmod pin) $\to$ `ESP32_RX` (GPIO 16 / RX2)
  - `FPGA_RX` (Pmod pin) $\leftarrow$ `ESP32_TX` (GPIO 17 / TX2)
  - `COMMON GROUND`: FPGA GND connected directly to ESP32 GND to guarantee a shared reference potential.

---

## 3. Recommended Pin Allocation (Digilent Basys 3 Master Guide)

| FPGA Pin | Function | Direction | Basys 3 Feature | Description |
| :--- | :--- | :--- | :--- | :--- |
| `W5` | `clk_100mhz` | Input | 100 MHz Oscillator | Master system clock |
| `V17` | `rst_btn` | Input | Push Button Up (`BTNU`) | Master synchronous reset (active high) |
| `J1` | `pir_sensor_in` | Input | Pmod Header JA Pin 1 | PIR digital motion signal |
| `J2` | `adc_cs_n` | Output | Pmod Header JA Pin 2 | MCP3008 ADC SPI Chip Select |
| `G2` | `adc_mosi` | Output | Pmod Header JA Pin 3 | MCP3008 ADC SPI MOSI |
| `H1` | `adc_miso` | Input | Pmod Header JA Pin 4 | MCP3008 ADC SPI MISO |
| `K2` | `adc_sclk` | Output | Pmod Header JA Pin 7 | MCP3008 ADC SPI SCLK |
| `A14` | `uart_tx_pin` | Output | Pmod Header JB Pin 1 | UART TX to ESP32 RX2 |
| `A16` | `uart_rx_pin` | Input | Pmod Header JB Pin 2 | UART RX from ESP32 TX2 |
| `B15` | `pwm_led_out` | Output | Pmod Header JB Pin 3 | PWM signal to MOSFET gate driver |
| `U18` | `btn_mode_toggle` | Input | Push Button Center (`BTNC`)| Local manual mode toggle |
| `T18` | `btn_brightness_up`| Input | Push Button Down (`BTND`) | Step brightness manual increment |
| `U16` | `led_occupied` | Output | Onboard LED LD0 | Real-time motion detection indicator |
| `E19` | `led_light_on` | Output | Onboard LED LD1 | Lighting active indicator |
| `U19` | `led_mode_auto` | Output | Onboard LED LD2 | Auto mode active indicator |
| `V19` | `led_mode_manual`| Output | Onboard LED LD3 | Manual mode active indicator |
| `W7..U7`| `seg[6:0]` | Output | 7-Segment Cathodes | Segment lines (A, B, C, D, E, F, G) |
| `W4..W4`| `an[3:0]` | Output | 7-Segment Anodes | 4 digit select enables |
