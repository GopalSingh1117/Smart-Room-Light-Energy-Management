// ============================================================================
// File: energy_counter.v
// Module: energy_counter
// Description: Integrates active lighting duty cycles over time.
//              Provides total active seconds and integrated energy metrics
//              for upstream backend power analysis.
// Standard: IEEE 1364-2001 Synthesizable Verilog
// ============================================================================

`timescale 1ns / 1ps

module energy_counter (
    input  wire        clk,
    input  wire        rst,
    input  wire        one_sec_tick,         // 1 Hz strobe from occupancy_timer
    input  wire        lighting_active,      // Light is ON
    input  wire [6:0]  duty_percent,         // Current duty cycle 0 to 100 (%)
    input  wire        rst_energy_accum,     // Clears energy accumulator
    
    // Telemetry Outputs
    output reg  [31:0] active_runtime_sec,   // Cumulative active operating seconds
    output reg  [31:0] energy_units_accum    // Scaled energy counter: sum of (duty% * 1s)
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            active_runtime_sec <= 32'd0;
            energy_units_accum <= 32'd0;
        end else if (rst_energy_accum) begin
            active_runtime_sec <= 32'd0;
            energy_units_accum <= 32'd0;
        end else if (one_sec_tick && lighting_active) begin
            active_runtime_sec <= active_runtime_sec + 1'b1;
            energy_units_accum <= energy_units_accum + duty_percent;
        end
    end

endmodule
