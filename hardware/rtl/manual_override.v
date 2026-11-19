// ============================================================================
// File: manual_override.v
// Module: manual_override
// Description: Arbitrates priority between local physical push-buttons/switches
//              and remote UART commands received from the web dashboard.
// Standard: IEEE 1364-2001 Synthesizable Verilog
// ============================================================================

`timescale 1ns / 1ps

module manual_override (
    input  wire       clk,
    input  wire       rst,
    
    // Local physical button pulses (post-debounced single-cycle pulses)
    input  wire       btn_mode_pulse,         // Cycle mode: AUTO -> ON -> OFF -> AUTO
    input  wire       btn_brightness_pulse,   // Step brightness: 30% -> 60% -> 100% -> 30%
    input  wire       sw_force_off,           // Physical emergency kill-switch
    
    // Remote UART command interfaces
    input  wire       uart_cmd_mode_valid,
    input  wire [1:0] uart_cmd_mode_data,     // 2'b00: AUTO, 2'b01: MANUAL_ON, 2'b10: MANUAL_OFF
    input  wire       uart_cmd_bright_valid,
    input  wire [6:0] uart_cmd_bright_data,   // 0 to 100 (%)
    input  wire       uart_cmd_esave_valid,
    input  wire       uart_cmd_esave_data,    // 0: Normal, 1: Aggressive Energy Saving
    
    // Arbitrated Outputs
    output reg  [1:0] current_mode,           // 2'b00: AUTO, 2'b01: MANUAL_ON, 2'b10: MANUAL_OFF
    output reg  [6:0] manual_brightness,      // Current manual setpoint (0-100)
    output reg        energy_saving_mode
);

    // Modes definition
    localparam MODE_AUTO       = 2'b00;
    localparam MODE_MANUAL_ON  = 2'b01;
    localparam MODE_MANUAL_OFF = 2'b10;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_mode       <= MODE_AUTO;
            manual_brightness  <= 7'd100; // Default 100% when manually turned on
            energy_saving_mode <= 1'b0;
        end else if (sw_force_off) begin
            // Hardware emergency switch overrides everything
            current_mode <= MODE_MANUAL_OFF;
        end else begin
            // 1. Process Remote UART Commands
            if (uart_cmd_mode_valid) begin
                if (uart_cmd_mode_data <= 2'b10)
                    current_mode <= uart_cmd_mode_data;
            end

            if (uart_cmd_bright_valid) begin
                if (uart_cmd_bright_data <= 7'd100)
                    manual_brightness <= uart_cmd_bright_data;
            end

            if (uart_cmd_esave_valid) begin
                energy_saving_mode <= uart_cmd_esave_data;
            end

            // 2. Process Local Hardware Button Events (Takes instantaneous user priority)
            if (btn_mode_pulse) begin
                case (current_mode)
                    MODE_AUTO:       current_mode <= MODE_MANUAL_ON;
                    MODE_MANUAL_ON:  current_mode <= MODE_MANUAL_OFF;
                    MODE_MANUAL_OFF: current_mode <= MODE_AUTO;
                    default:         current_mode <= MODE_AUTO;
                endcase
            end

            if (btn_brightness_pulse) begin
                case (manual_brightness)
                    7'd30:   manual_brightness <= 7'd60;
                    7'd60:   manual_brightness <= 7'd100;
                    7'd100:  manual_brightness <= 7'd30;
                    default: manual_brightness <= 7'd100;
                endcase
            end
        end
    end

endmodule
