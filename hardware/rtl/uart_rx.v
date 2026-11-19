// ============================================================================
// File: uart_rx.v
// Module: uart_rx
// Description: Standard 8-N-1 UART Receiver with center-sample synchronization
//              and false-start bit rejection.
// Standard: IEEE 1364-2001 Synthesizable Verilog
// ============================================================================

`timescale 1ns / 1ps

module uart_rx #(
    parameter CLK_FREQ_HZ = 100_000_000,
    parameter BAUD_RATE   = 115_200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx_pin,
    output reg  [7:0] rx_data,
    output reg        rx_valid_pulse,
    output reg        frame_error
);

    localparam CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE;

    localparam STATE_IDLE  = 3'd0;
    localparam STATE_START = 3'd1;
    localparam STATE_DATA  = 3'd2;
    localparam STATE_STOP  = 3'd3;

    reg [2:0] state;
    reg [$clog2(CLKS_PER_BIT+1)-1:0] clk_counter;
    reg [2:0] bit_index;
    reg [7:0] rx_shift_reg;

    // Two-stage synchronizer for asynchronous RX line
    reg rx_sync1, rx_sync2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx_pin;
            rx_sync2 <= rx_sync1;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state          <= STATE_IDLE;
            rx_data        <= 8'd0;
            rx_valid_pulse <= 1'b0;
            frame_error    <= 1'b0;
            clk_counter    <= 0;
            bit_index      <= 3'd0;
            rx_shift_reg   <= 8'd0;
        end else begin
            rx_valid_pulse <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    clk_counter <= 0;
                    bit_index   <= 3'd0;
                    frame_error <= 1'b0;
                    // Detect falling edge of start bit
                    if (rx_sync2 == 1'b0) begin
                        state <= STATE_START;
                    end
                end

                STATE_START: begin
                    // Sample at the middle of the start bit to reject glitches
                    if (clk_counter == ((CLKS_PER_BIT / 2) - 1)) begin
                        if (rx_sync2 == 1'b0) begin
                            clk_counter <= 0; // Reset counter for full-bit timing
                            state       <= STATE_DATA;
                        end else begin
                            state <= STATE_IDLE; // False start glitch
                        end
                    end else begin
                        clk_counter <= clk_counter + 1'b1;
                    end
                end

                STATE_DATA: begin
                    if (clk_counter < (CLKS_PER_BIT - 1)) begin
                        clk_counter <= clk_counter + 1'b1;
                    end else begin
                        clk_counter <= 0;
                        rx_shift_reg[bit_index] <= rx_sync2;
                        if (bit_index < 3'd7) begin
                            bit_index <= bit_index + 1'b1;
                        end else begin
                            bit_index <= 3'd0;
                            state     <= STATE_STOP;
                        end
                    end
                end

                STATE_STOP: begin
                    if (clk_counter < (CLKS_PER_BIT - 1)) begin
                        clk_counter <= clk_counter + 1'b1;
                    end else begin
                        clk_counter <= 0;
                        if (rx_sync2 == 1'b1) begin
                            rx_data        <= rx_shift_reg;
                            rx_valid_pulse <= 1'b1; // Valid byte received
                        end else begin
                            frame_error <= 1'b1; // Missing stop bit
                        end
                        state <= STATE_IDLE;
                    end
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule
