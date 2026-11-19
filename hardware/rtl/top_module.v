// ============================================================================
// File: top_module.v
// Module: top_module
// Description: Top-Level System Integration for Smart Automatic Room Light and
//              Energy Management System. Connects all sensor interfaces, FSM,
//              PWM dimming, 7-segment display, and framed UART IoT bridge.
// Standard: IEEE 1364-2001 Synthesizable Verilog
// ============================================================================

`timescale 1ns / 1ps

module top_module #(
    parameter CLK_FREQ_HZ = 100_000_000,
    parameter BAUD_RATE   = 115_200,
    parameter SIMULATION  = 0
)(
    // Clock & Master Reset
    input  wire        clk,
    input  wire        rst_btn,               // Active high reset pushbutton

    // Physical Sensor & Button Inputs
    input  wire        pir_raw_in,            // Digital PIR motion sensor (HC-SR501)
    input  wire        btn_mode_raw,          // Pushbutton: Mode toggle
    input  wire        btn_bright_raw,        // Pushbutton: Manual brightness step
    input  wire        sw_force_off_raw,      // Slide switch: Emergency force off
    input  wire        sw_disp_mode_raw,      // Slide switch: 7-seg shows Timeout if 1, Brightness if 0

    // ADC SPI Interface (LDR reading via MCP3008)
    output wire        adc_cs_n,
    output wire        adc_sclk,
    output wire        adc_mosi,
    input  wire        adc_miso,

    // Simulation / Direct ADC Override (for testbenches)
    input  wire        sim_adc_override,
    input  wire [9:0]  sim_adc_val,

    // UART Serial Port to ESP32 Gateway
    input  wire        uart_rx_pin,
    output wire        uart_tx_pin,

    // Actuator & Physical Display Outputs
    output wire        pwm_led_out,           // PWM output to MOSFET gate driving LED
    output wire [6:0]  seg,                   // 7-segment cathodes [6:0]
    output wire [3:0]  an,                    // 7-segment digit anodes [3:0]
    output wire [3:0]  led_status             // Onboard diagnostic status LEDs
);

    // -------------------------------------------------------------------------
    // 1. Reset & Input Conditioning (Synchronizers and Debouncers)
    // -------------------------------------------------------------------------
    wire rst_clean;
    debounce_filter #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .DEBOUNCE_MS((SIMULATION == 1) ? 1 : 20)
    ) db_rst (
        .clk(clk),
        .rst(1'b0),
        .noisy_in(rst_btn),
        .clean_out(rst_clean),
        .pulse_posedge()
    );

    wire btn_mode_pulse;
    debounce_filter #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .DEBOUNCE_MS((SIMULATION == 1) ? 1 : 20)
    ) db_btn_mode (
        .clk(clk),
        .rst(rst_clean),
        .noisy_in(btn_mode_raw),
        .clean_out(),
        .pulse_posedge(btn_mode_pulse)
    );

    wire btn_bright_pulse;
    debounce_filter #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .DEBOUNCE_MS((SIMULATION == 1) ? 1 : 20)
    ) db_btn_bright (
        .clk(clk),
        .rst(rst_clean),
        .noisy_in(btn_bright_raw),
        .clean_out(),
        .pulse_posedge(btn_bright_pulse)
    );

    wire sw_force_off;
    input_synchronizer #(.WIDTH(2)) sync_switches (
        .clk(clk),
        .rst(rst_clean),
        .async_in({sw_disp_mode_raw, sw_force_off_raw}),
        .sync_out({sw_disp_mode, sw_force_off})
    );
    wire sw_disp_mode;

    // -------------------------------------------------------------------------
    // 2. Sensor Processing Modules
    // -------------------------------------------------------------------------
    wire pir_motion_detected;
    wire pir_motion_pulse;
    pir_detector #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .FILTER_MS((SIMULATION == 1) ? 1 : 10)
    ) u_pir (
        .clk(clk),
        .rst(rst_clean),
        .pir_raw_in(pir_raw_in),
        .motion_detected(pir_motion_detected),
        .motion_pulse(pir_motion_pulse)
    );

    wire [9:0] adc_value;
    wire       adc_data_valid;
    ldr_adc_interface #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .SPI_SCLK_HZ(1_000_000),
        .SAMPLE_RATE_HZ((SIMULATION == 1) ? 1000 : 50)
    ) u_adc (
        .clk(clk),
        .rst(rst_clean),
        .spi_cs_n(adc_cs_n),
        .spi_sclk(adc_sclk),
        .spi_mosi(adc_mosi),
        .spi_miso(adc_miso),
        .sim_mode_override(sim_adc_override),
        .sim_adc_val(sim_adc_val),
        .adc_value(adc_value),
        .adc_data_valid(adc_data_valid)
    );

    wire [1:0] light_zone;
    wire is_dark, is_medium, is_bright;
    reg [9:0] cfg_thresh_dark;
    reg [9:0] cfg_thresh_bright;
    light_sensor_classifier u_classifier (
        .clk(clk),
        .rst(rst_clean),
        .adc_value(adc_value),
        .adc_valid(adc_data_valid),
        .cfg_thresh_dark(cfg_thresh_dark),
        .cfg_thresh_bright(cfg_thresh_bright),
        .light_zone(light_zone),
        .is_dark(is_dark),
        .is_medium(is_medium),
        .is_bright(is_bright)
    );

    // -------------------------------------------------------------------------
    // 3. Occupancy Inactivity Timer
    // -------------------------------------------------------------------------
    wire [7:0] remaining_seconds;
    wire       occupancy_timer_active;
    wire       occupancy_timer_expired;
    wire       one_sec_tick;
    wire       timer_enable;
    wire       timer_clear;
    reg  [7:0] cfg_timeout_sec;

    occupancy_timer #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .DEFAULT_TIMEOUT(8'd30),
        .SIMULATION_FAST(SIMULATION)
    ) u_timer (
        .clk(clk),
        .rst(rst_clean),
        .motion_pulse(pir_motion_pulse),
        .timer_enable(timer_enable),
        .cfg_timeout_sec(cfg_timeout_sec),
        .clear_timer(timer_clear),
        .remaining_seconds(remaining_seconds),
        .occupancy_active(occupancy_timer_active),
        .timer_expired(occupancy_timer_expired),
        .one_sec_tick(one_sec_tick)
    );

    // -------------------------------------------------------------------------
    // 4. Manual Override & Arbitration
    // -------------------------------------------------------------------------
    reg        uart_cmd_mode_valid;
    reg  [1:0] uart_cmd_mode_data;
    reg        uart_cmd_bright_valid;
    reg  [6:0] uart_cmd_bright_data;
    reg        uart_cmd_esave_valid;
    reg        uart_cmd_esave_data;

    wire [1:0] current_mode;
    wire [6:0] manual_brightness;
    wire       energy_saving_mode;

    manual_override u_override (
        .clk(clk),
        .rst(rst_clean),
        .btn_mode_pulse(btn_mode_pulse),
        .btn_brightness_pulse(btn_bright_pulse),
        .sw_force_off(sw_force_off),
        .uart_cmd_mode_valid(uart_cmd_mode_valid),
        .uart_cmd_mode_data(uart_cmd_mode_data),
        .uart_cmd_bright_valid(uart_cmd_bright_valid),
        .uart_cmd_bright_data(uart_cmd_bright_data),
        .uart_cmd_esave_valid(uart_cmd_esave_valid),
        .uart_cmd_esave_data(uart_cmd_esave_data),
        .current_mode(current_mode),
        .manual_brightness(manual_brightness),
        .energy_saving_mode(energy_saving_mode)
    );

    // -------------------------------------------------------------------------
    // 5. Master Lighting Finite State Machine
    // -------------------------------------------------------------------------
    wire [2:0] fsm_state;
    wire [6:0] duty_percent;
    wire       lighting_active;
    wire       status_occupied;

    light_controller u_fsm (
        .clk(clk),
        .rst(rst_clean),
        .pir_motion_detected(pir_motion_detected),
        .pir_motion_pulse(pir_motion_pulse),
        .light_zone(light_zone),
        .occupancy_timer_active(occupancy_timer_active),
        .occupancy_timer_expired(occupancy_timer_expired),
        .remaining_seconds(remaining_seconds),
        .current_mode(current_mode),
        .manual_brightness(manual_brightness),
        .energy_saving_mode(energy_saving_mode),
        .fsm_state(fsm_state),
        .duty_percent(duty_percent),
        .lighting_active(lighting_active),
        .timer_enable(timer_enable),
        .timer_clear(timer_clear),
        .status_occupied(status_occupied)
    );

    // -------------------------------------------------------------------------
    // 6. PWM Generator
    // -------------------------------------------------------------------------
    wire [7:0] current_duty_raw;
    pwm_generator #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .PWM_FREQ_HZ(5_000)
    ) u_pwm (
        .clk(clk),
        .rst(rst_clean),
        .duty_percent(duty_percent),
        .enable(lighting_active),
        .pwm_out(pwm_led_out),
        .current_duty_raw(current_duty_raw)
    );

    // -------------------------------------------------------------------------
    // 7. Energy Metric Counter
    // -------------------------------------------------------------------------
    wire [31:0] active_runtime_sec;
    wire [31:0] energy_units_accum;
    energy_counter u_energy (
        .clk(clk),
        .rst(rst_clean),
        .one_sec_tick(one_sec_tick),
        .lighting_active(lighting_active),
        .duty_percent(duty_percent),
        .rst_energy_accum(1'b0),
        .active_runtime_sec(active_runtime_sec),
        .energy_units_accum(energy_units_accum)
    );

    // -------------------------------------------------------------------------
    // 8. Seven-Segment Multiplexed Display
    // -------------------------------------------------------------------------
    seven_segment_decoder #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) u_ssd (
        .clk(clk),
        .rst(rst_clean),
        .current_mode(current_mode),
        .duty_percent(duty_percent),
        .timeout_sec(remaining_seconds),
        .display_timeout(sw_disp_mode),
        .seg(seg),
        .an(an)
    );

    // Diagnostic LEDs
    assign led_status[0] = pir_motion_detected;
    assign led_status[1] = status_occupied;
    assign led_status[2] = lighting_active;
    assign led_status[3] = (current_mode == 2'b00); // ON if in AUTO mode

    // -------------------------------------------------------------------------
    // 9. UART IoT Transceiver & Packet Parser / Serializer
    // -------------------------------------------------------------------------
    wire [7:0] rx_byte;
    wire       rx_valid;
    wire       rx_err;
    uart_rx #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) u_uart_rx (
        .clk(clk),
        .rst(rst_clean),
        .rx_pin(uart_rx_pin),
        .rx_data(rx_byte),
        .rx_valid_pulse(rx_valid),
        .frame_error(rx_err)
    );

    reg        tx_start;
    reg  [7:0] tx_byte;
    wire       tx_busy;
    wire       tx_done;
    uart_tx #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) u_uart_tx (
        .clk(clk),
        .rst(rst_clean),
        .tx_start(tx_start),
        .tx_data(tx_byte),
        .tx_pin(uart_tx_pin),
        .tx_busy(tx_busy),
        .tx_done_pulse(tx_done)
    );

    // --- RX Packet Parser State Machine ---
    localparam RX_IDLE   = 3'd0;
    localparam RX_SOF2   = 3'd1;
    localparam RX_LEN    = 3'd2;
    localparam RX_OPCODE = 3'd3;
    localparam RX_PAYLOAD= 3'd4;
    localparam RX_CRC    = 3'd5;
    localparam RX_EOF1   = 3'd6;
    localparam RX_EOF2   = 3'd7;

    reg [2:0] rx_state;
    reg [7:0] rx_expected_len;
    reg [7:0] rx_opcode;
    reg [7:0] rx_payload_buf [0:3];
    reg [2:0] rx_byte_idx;
    reg [7:0] rx_calc_crc;

    // Send ACK trigger
    reg send_ack_pending;
    reg [7:0] ack_opcode;
    reg [7:0] ack_status;

    always @(posedge clk or posedge rst_clean) begin
        if (rst_clean) begin
            rx_state              <= RX_IDLE;
            rx_expected_len       <= 8'd0;
            rx_opcode             <= 8'd0;
            rx_byte_idx           <= 3'd0;
            rx_calc_crc           <= 8'd0;
            uart_cmd_mode_valid   <= 1'b0;
            uart_cmd_mode_data    <= 2'b00;
            uart_cmd_bright_valid <= 1'b0;
            uart_cmd_bright_data  <= 7'd0;
            uart_cmd_esave_valid  <= 1'b0;
            uart_cmd_esave_data   <= 1'b0;
            cfg_timeout_sec       <= 8'd30;
            cfg_thresh_dark       <= 10'd350;
            cfg_thresh_bright     <= 10'd700;
            send_ack_pending      <= 1'b0;
            ack_opcode            <= 8'd0;
            ack_status            <= 8'd0;
        end else begin
            uart_cmd_mode_valid   <= 1'b0;
            uart_cmd_bright_valid <= 1'b0;
            uart_cmd_esave_valid  <= 1'b0;

            if (rx_valid) begin
                case (rx_state)
                    RX_IDLE: begin
                        if (rx_byte == 8'hAA)
                            rx_state <= RX_SOF2;
                    end

                    RX_SOF2: begin
                        if (rx_byte == 8'h55)
                            rx_state <= RX_LEN;
                        else
                            rx_state <= RX_IDLE;
                    end

                    RX_LEN: begin
                        rx_expected_len <= rx_byte;
                        rx_calc_crc     <= rx_byte;
                        rx_state        <= RX_OPCODE;
                    end

                    RX_OPCODE: begin
                        rx_opcode   <= rx_byte;
                        rx_calc_crc <= rx_calc_crc ^ rx_byte;
                        rx_byte_idx <= 3'd0;
                        if (rx_expected_len == 8'd0)
                            rx_state <= RX_CRC;
                        else
                            rx_state <= RX_PAYLOAD;
                    end

                    RX_PAYLOAD: begin
                        rx_payload_buf[rx_byte_idx] <= rx_byte;
                        rx_calc_crc <= rx_calc_crc ^ rx_byte;
                        if (rx_byte_idx < (rx_expected_len - 1'b1)) begin
                            rx_byte_idx <= rx_byte_idx + 1'b1;
                        end else begin
                            rx_state <= RX_CRC;
                        end
                    end

                    RX_CRC: begin
                        if (rx_byte == rx_calc_crc)
                            rx_state <= RX_EOF1;
                        else
                            rx_state <= RX_IDLE; // CRC mismatch, reject
                    end

                    RX_EOF1: begin
                        if (rx_byte == 8'h0D) // '\r'
                            rx_state <= RX_EOF2;
                        else
                            rx_state <= RX_IDLE;
                    end

                    RX_EOF2: begin
                        if (rx_byte == 8'h0A) begin // '\n' - Packet successfully verified!
                            case (rx_opcode)
                                8'h02: begin // SET_MODE
                                    uart_cmd_mode_valid <= 1'b1;
                                    uart_cmd_mode_data  <= rx_payload_buf[0][1:0];
                                    send_ack_pending    <= 1'b1;
                                    ack_opcode          <= 8'h02;
                                    ack_status          <= 8'h00;
                                end
                                8'h03: begin // SET_BRIGHTNESS
                                    uart_cmd_bright_valid <= 1'b1;
                                    uart_cmd_bright_data  <= rx_payload_buf[0][6:0];
                                    send_ack_pending      <= 1'b1;
                                    ack_opcode            <= 8'h03;
                                    ack_status            <= 8'h00;
                                end
                                8'h04: begin // SET_TIMEOUT
                                    cfg_timeout_sec  <= rx_payload_buf[0];
                                    send_ack_pending <= 1'b1;
                                    ack_opcode       <= 8'h04;
                                    ack_status       <= 8'h00;
                                end
                                8'h05: begin // SET_ENERGY_SAVING
                                    uart_cmd_esave_valid <= 1'b1;
                                    uart_cmd_esave_data  <= rx_payload_buf[0][0];
                                    send_ack_pending     <= 1'b1;
                                    ack_opcode           <= 8'h05;
                                    ack_status           <= 8'h00;
                                end
                                default: ;
                            endcase
                        end
                        rx_state <= RX_IDLE;
                    end

                    default: rx_state <= RX_IDLE;
                endcase
            end
        end
    end

    // --- TX Packet Serializer Engine ---
    // Periodically sends 8-byte Telemetry frame (Opcode 0x01) or ACK frame (Opcode 0x06)
    localparam TX_INTERVAL = (SIMULATION == 1) ? 2000 : (CLK_FREQ_HZ / 2); // 2 Hz telemetry
    reg [$clog2(TX_INTERVAL+1)-1:0] tx_timer;
    reg [4:0] tx_seq_idx;
    reg [7:0] tx_packet [0:13];
    reg [7:0] tx_crc_calc;
    reg is_transmitting;

    always @(posedge clk or posedge rst_clean) begin
        if (rst_clean) begin
            tx_timer        <= 0;
            tx_seq_idx      <= 5'd0;
            tx_start        <= 1'b0;
            tx_byte         <= 8'd0;
            is_transmitting <= 1'b0;
        end else begin
            tx_start <= 1'b0;

            if (!is_transmitting) begin
                if (send_ack_pending && !tx_busy) begin
                    // Build ACK Frame: [0xAA, 0x55, 0x02, 0x06, ACK_OP, ACK_STAT, CRC, 0x0D, 0x0A]
                    tx_packet[0] <= 8'hAA;
                    tx_packet[1] <= 8'h55;
                    tx_packet[2] <= 8'h02; // Length
                    tx_packet[3] <= 8'h06; // Opcode ACK
                    tx_packet[4] <= ack_opcode;
                    tx_packet[5] <= ack_status;
                    tx_packet[6] <= 8'h02 ^ 8'h06 ^ ack_opcode ^ ack_status; // CRC
                    tx_packet[7] <= 8'h0D;
                    tx_packet[8] <= 8'h0A;

                    is_transmitting <= 1'b1;
                    tx_seq_idx      <= 5'd0;
                end else if (tx_timer >= (TX_INTERVAL - 1) && !tx_busy) begin
                    // Build Telemetry Frame: [0xAA, 0x55, 0x08, 0x01, M, O, LuxH, LuxL, S, B, Mode, Rem, CRC, \r, \n]
                    tx_timer     <= 0;
                    tx_packet[0] <= 8'hAA;
                    tx_packet[1] <= 8'h55;
                    tx_packet[2] <= 8'h08; // Length 8 bytes
                    tx_packet[3] <= 8'h01; // Opcode TELEMETRY
                    tx_packet[4] <= {7'd0, pir_motion_detected};
                    tx_packet[5] <= {7'd0, status_occupied};
                    tx_packet[6] <= {6'd0, adc_value[9:8]};
                    tx_packet[7] <= adc_value[7:0];
                    tx_packet[8] <= {7'd0, lighting_active};
                    tx_packet[9] <= {1'b0, duty_percent};
                    tx_packet[10]<= {6'd0, current_mode};
                    tx_packet[11]<= remaining_seconds;
                    
                    // XOR CRC across Length, Opcode, and all 8 payload bytes
                    tx_packet[12] <= 8'h08 ^ 8'h01 ^ {7'd0, pir_motion_detected} ^ {7'd0, status_occupied} ^
                                     {6'd0, adc_value[9:8]} ^ adc_value[7:0] ^ {7'd0, lighting_active} ^
                                     {1'b0, duty_percent} ^ {6'd0, current_mode} ^ remaining_seconds;
                    tx_packet[13] <= 8'h0D;
                    tx_packet[14] <= 8'h0A;

                    is_transmitting <= 1'b1;
                    tx_seq_idx      <= 5'd0;
                end else begin
                    tx_timer <= tx_timer + 1'b1;
                end
            end else begin
                // Stream packet bytes one by one
                if (!tx_busy && !tx_start) begin
                    tx_byte  <= tx_packet[tx_seq_idx];
                    tx_start <= 1'b1;
                    if (tx_seq_idx == ((tx_packet[3] == 8'h06) ? 5'd8 : 5'd14)) begin
                        is_transmitting <= 1'b0;
                        tx_seq_idx      <= 5'd0;
                    end else begin
                        tx_seq_idx <= tx_seq_idx + 1'b1;
                    end
                end
            end
        end
    end

endmodule
