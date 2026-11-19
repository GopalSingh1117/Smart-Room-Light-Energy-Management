// ============================================================================
// File: occupancy_timer.v
// Module: occupancy_timer
// Description: Programmable inactivity countdown timer. Resets upon motion detection.
//              Generates expiration strobe when no motion is observed for the
//              configured timeout duration.
// Standard: IEEE 1364-2001 Synthesizable Verilog
// ============================================================================

`timescale 1ns / 1ps

module occupancy_timer #(
    parameter CLK_FREQ_HZ      = 100_000_000,
    parameter DEFAULT_TIMEOUT  = 8'd30,         // Default 30 seconds
    parameter SIMULATION_FAST  = 0              // If 1, 1-sec tick = 100 clock cycles
)(
    input  wire        clk,
    input  wire        rst,
    
    // Control inputs
    input  wire        motion_pulse,            // Reloads timer
    input  wire        timer_enable,            // Enables countdown
    input  wire [7:0]  cfg_timeout_sec,         // Runtime configurable timeout in seconds
    input  wire        clear_timer,             // Immediate reset to 0
    
    // Status outputs
    output reg  [7:0]  remaining_seconds,
    output reg         occupancy_active,
    output reg         timer_expired,
    output wire        one_sec_tick
);

    localparam ONE_SEC_CYCLES = (SIMULATION_FAST == 1) ? 100 : CLK_FREQ_HZ;

    reg [$clog2(ONE_SEC_CYCLES+1)-1:0] prescaler_counter;
    reg sec_pulse;

    assign one_sec_tick = sec_pulse;

    wire [7:0] active_timeout = (cfg_timeout_sec != 8'd0) ? cfg_timeout_sec : DEFAULT_TIMEOUT;

    // 1-Second Prescaler Generator
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prescaler_counter <= 0;
            sec_pulse         <= 1'b0;
        end else if (prescaler_counter >= (ONE_SEC_CYCLES - 1)) begin
            prescaler_counter <= 0;
            sec_pulse         <= 1'b1;
        end else begin
            prescaler_counter <= prescaler_counter + 1'b1;
            sec_pulse         <= 1'b0;
        end
    end

    // Countdown Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            remaining_seconds <= 8'd0;
            occupancy_active  <= 1'b0;
            timer_expired     <= 1'b0;
        end else begin
            timer_expired <= 1'b0;

            if (clear_timer) begin
                remaining_seconds <= 8'd0;
                occupancy_active  <= 1'b0;
            end else if (motion_pulse) begin
                // Motion event detected: reload timer and assert occupancy
                remaining_seconds <= active_timeout;
                occupancy_active  <= 1'b1;
            end else if (timer_enable && sec_pulse) begin
                if (remaining_seconds > 8'd1) begin
                    remaining_seconds <= remaining_seconds - 1'b1;
                    occupancy_active  <= 1'b1;
                end else if (remaining_seconds == 8'd1) begin
                    remaining_seconds <= 8'd0;
                    occupancy_active  <= 1'b0;
                    timer_expired     <= 1'b1; // Strobe on transition to 0
                end else begin
                    remaining_seconds <= 8'd0;
                    occupancy_active  <= 1'b0;
                end
            end
        end
    end

endmodule
