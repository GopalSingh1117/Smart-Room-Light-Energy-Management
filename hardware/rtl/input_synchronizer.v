// ============================================================================
// File: input_synchronizer.v
// Module: input_synchronizer
// Description: Two-stage D-type flip-flop synchronizer to prevent metastability
//              on external asynchronous digital inputs (PIR, buttons, RX).
// Standard: IEEE 1364-2001 Synthesizable Verilog
// ============================================================================

`timescale 1ns / 1ps

module input_synchronizer #(
    parameter WIDTH = 1
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [WIDTH-1:0] async_in,
    output reg  [WIDTH-1:0] sync_out
);

    reg [WIDTH-1:0] sync_stage1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_stage1 <= {WIDTH{1'b0}};
            sync_out    <= {WIDTH{1'b0}};
        end else begin
            sync_stage1 <= async_in;
            sync_out    <= sync_stage1;
        end
    end

endmodule
