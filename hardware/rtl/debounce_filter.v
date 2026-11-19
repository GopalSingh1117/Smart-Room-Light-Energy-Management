// ============================================================================
// File: debounce_filter.v
// Module: debounce_filter
// Description: Debounce filter for mechanical push-buttons and noisy digital sensors.
//              Samples input and requires state to be stable for DEBOUNCE_CYCLES.
// Standard: IEEE 1364-2001 Synthesizable Verilog
// ============================================================================

`timescale 1ns / 1ps

module debounce_filter #(
    parameter CLK_FREQ_HZ     = 100_000_000,
    parameter DEBOUNCE_MS     = 20,
    parameter DEBOUNCE_CYCLES = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS
)(
    input  wire clk,
    input  wire rst,
    input  wire noisy_in,
    output reg  clean_out,
    output reg  pulse_posedge
);

    reg [$clog2(DEBOUNCE_CYCLES+1)-1:0] counter;
    reg state_reg;
    reg prev_clean_out;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter        <= 0;
            state_reg      <= 1'b0;
            clean_out      <= 1'b0;
            prev_clean_out <= 1'b0;
            pulse_posedge  <= 1'b0;
        end else begin
            // Single-cycle pulse on positive edge of debounced output
            prev_clean_out <= clean_out;
            pulse_posedge  <= clean_out & ~prev_clean_out;

            if (noisy_in != state_reg) begin
                state_reg <= noisy_in;
                counter   <= 0;
            end else if (counter < DEBOUNCE_CYCLES) begin
                counter <= counter + 1'b1;
            end else begin
                clean_out <= state_reg;
            end
        end
    end

endmodule
