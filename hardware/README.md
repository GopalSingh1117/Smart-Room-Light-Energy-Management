# FPGA Verilog Hardware Design and Verification Guide

## 1. Directory Contents
- `rtl/`: 12 modular synthesizable Verilog modules (IEEE 1364-2001).
- `testbench/`: Complete behavioral simulation testbenches.
- `constraints/`: Xilinx Vivado XDC constraint file for Digilent Basys 3 and pin mapping notes.

## 2. Steps to Simulate in Vivado Simulator or ModelSim

### In Vivado GUI:
1. Open Vivado and select **Create Project** -> **RTL Project**.
2. Select target FPGA part: `xc7a35tcpg236-1` (or your specific board).
3. Add all Verilog design files from `hardware/rtl/`.
4. Add testbenches from `hardware/testbench/`.
5. Set `tb_top_system` as the top simulation module.
6. Click **Run Simulation** -> **Run Behavioral Simulation**.
7. Observe test output messages in the Tcl Console and inspect the waveform signals (`pwm_led_out`, `fsm_state`, `duty_percent`, `uart_tx_pin`).

### Using Command-Line Vivado:
```bash
xvlog rtl/*.v testbench/tb_top_system.v
xelab tb_top_system -s sim_snapshot
xsim sim_snapshot -R
```

## 3. Steps to Synthesize and Generate Bitstream
1. In the Vivado project, add `hardware/constraints/basys3_master.xdc`.
2. Set `top_module` as the top-level synthesis module.
3. Click **Run Synthesis**.
4. Click **Run Implementation**.
5. Click **Generate Bitstream** (`top_module.bit`).
6. Connect the Basys 3 board via USB, open the **Hardware Manager**, auto-connect to the target device, and program `top_module.bit`.
