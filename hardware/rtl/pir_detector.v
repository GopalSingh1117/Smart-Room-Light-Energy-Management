// ============================================================================
// File: pir_detector.v
// Module: pir_detector
// Description: PIR motion sensor signal conditioning. Provides digital filtering,
//              edge detection for occupancy timer reload, and occupancy status.
// Standard: IEEE 1364-2001 Synthesizable Verilog
// ============================================================================

`timescale 1ns / 1ps

module pir_detector #(
    parameter CLK_FREQ_HZ    = 100_000_000,
    parameter FILTER_MS      = 10,
    parameter FILTER_CYCLES  = (CLK_FREQ_HZ / 1000) * FILTER_MS
)(
    input  wire clk,
    input  wire rst,
    input  wire pir_raw_in,          // Raw input from HC-SR501 sensor
    output reg  motion_detected,     // Steady filtered presence signal
    output reg  motion_pulse         // Single-clock pulse on new motion event
);

    // Two-stage synchronizer
    reg sync_1, sync_2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_1 <= 1'b0;
            sync_2 <= 1'b0;
        end else begin
            sync_1 <= pir_raw_in;
            sync_2 <= sync_1;
        end
    end

    // Noise filter counter
    reg [$clog2(FILTER_CYCLES+1)-1:0] filter_counter;
    reg filtered_state;
    reg prev_filtered_state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            filter_counter      <= 0;
            filtered_state      <= 1'b0;
            prev_filtered_state <= 1'b0;
            motion_detected     <= 1'b0;
            motion_pulse        <= 1'b0;
        end else begin
            // Filter logic
            if (sync_2 != filtered_state) begin
                if (filter_counter >= FILTER_CYCLES) begin
                    filtered_state <= sync_2;
                    filter_counter <= 0;
                end else begin
                    filter_counter <= filter_counter + 1'b1;
                end
            end else begin
                filter_counter <= 0;
            end

            // Registered outputs
            motion_detected     <= filtered_state;
            prev_filtered_state <= filtered_state;
            motion_pulse        <= (filtered_state & ~prev_filtered_state);
        end
    end

endmodule
