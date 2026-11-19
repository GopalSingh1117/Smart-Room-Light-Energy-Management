## ============================================================================
## Vivado XDC Constraints File: Digilent Basys 3 (XC7A35T-1CPG236C)
## Project: Smart Automatic Room Light and Energy Management System
## ============================================================================

## Clock Signal (100 MHz Master Oscillator)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Reset Button (BTNU - Push Button Up)
set_property PACKAGE_PIN T18 [get_ports rst_btn]
set_property IOSTANDARD LVCMOS33 [get_ports rst_btn]

## Local User Pushbuttons & Switches
## BTNC (Center Button) -> Mode Toggle
set_property PACKAGE_PIN U18 [get_ports btn_mode_raw]
set_property IOSTANDARD LVCMOS33 [get_ports btn_mode_raw]

## BTND (Down Button) -> Manual Brightness Step
set_property PACKAGE_PIN U17 [get_ports btn_bright_raw]
set_property IOSTANDARD LVCMOS33 [get_ports btn_bright_raw]

## SW0 -> Emergency Force OFF Switch
set_property PACKAGE_PIN V17 [get_ports sw_force_off_raw]
set_property IOSTANDARD LVCMOS33 [get_ports sw_force_off_raw]

## SW1 -> 7-Segment Display Select (0: Brightness %, 1: Remaining Seconds)
set_property PACKAGE_PIN V16 [get_ports sw_disp_mode_raw]
set_property IOSTANDARD LVCMOS33 [get_ports sw_disp_mode_raw]

## Pmod Header JA: Sensor Inputs & MCP3008 ADC SPI Interface
## JA1 -> PIR Motion Sensor Digital Input (HC-SR501)
set_property PACKAGE_PIN J1 [get_ports pir_raw_in]
set_property IOSTANDARD LVCMOS33 [get_ports pir_raw_in]

## JA2 -> ADC Chip Select (CS_N)
set_property PACKAGE_PIN L2 [get_ports adc_cs_n]
set_property IOSTANDARD LVCMOS33 [get_ports adc_cs_n]

## JA3 -> ADC MOSI (Data In to MCP3008)
set_property PACKAGE_PIN J2 [get_ports adc_mosi]
set_property IOSTANDARD LVCMOS33 [get_ports adc_mosi]

## JA4 -> ADC MISO (Data Out from MCP3008)
set_property PACKAGE_PIN G2 [get_ports adc_miso]
set_property IOSTANDARD LVCMOS33 [get_ports adc_miso]

## JA7 -> ADC SCLK (Serial SPI Clock)
set_property PACKAGE_PIN H1 [get_ports adc_sclk]
set_property IOSTANDARD LVCMOS33 [get_ports adc_sclk]

## Pmod Header JB: IoT UART Communication & PWM Driver Output
## JB1 -> UART TX Pin (FPGA TX -> ESP32 RX2 GPIO 16)
set_property PACKAGE_PIN A14 [get_ports uart_tx_pin]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx_pin]

## JB2 -> UART RX Pin (FPGA RX <- ESP32 TX2 GPIO 17)
set_property PACKAGE_PIN A16 [get_ports uart_rx_pin]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx_pin]

## JB3 -> PWM Output to MOSFET Gate Driver (Controls High-Power LED)
set_property PACKAGE_PIN B15 [get_ports pwm_led_out]
set_property IOSTANDARD LVCMOS33 [get_ports pwm_led_out]

## 4-Digit Seven Segment Display Cathodes (seg[6:0] active low: a, b, c, d, e, f, g)
set_property PACKAGE_PIN W7 [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
set_property PACKAGE_PIN W6 [get_ports {seg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
set_property PACKAGE_PIN U8 [get_ports {seg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
set_property PACKAGE_PIN V8 [get_ports {seg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
set_property PACKAGE_PIN U5 [get_ports {seg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
set_property PACKAGE_PIN U7 [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]

## Seven Segment Display Anodes (an[3:0] active low)
set_property PACKAGE_PIN U2 [get_ports {an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
set_property PACKAGE_PIN U4 [get_ports {an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
set_property PACKAGE_PIN V4 [get_ports {an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
set_property PACKAGE_PIN W4 [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]

## Diagnostic Status LEDs (LD0..LD3)
set_property PACKAGE_PIN U16 [get_ports {led_status[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_status[0]}]
set_property PACKAGE_PIN E19 [get_ports {led_status[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_status[1]}]
set_property PACKAGE_PIN U19 [get_ports {led_status[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_status[2]}]
set_property PACKAGE_PIN V19 [get_ports {led_status[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_status[3]}]
