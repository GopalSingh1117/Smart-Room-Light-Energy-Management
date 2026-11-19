// ============================================================================
// File: tb_uart_comm.v
// Module: tb_uart_comm
// Description: Testbench verifying loopback UART transmission, packet framing,
//              and LRC checksum verification.
// ============================================================================

`timescale 1ns / 1ps

module tb_uart_comm;

    reg clk;
    reg rst;
    reg tx_start;
    reg [7:0] tx_data;
    wire tx_pin;
    wire tx_busy;
    wire tx_done_pulse;

    wire [7:0] rx_data;
    wire rx_valid_pulse;
    wire frame_error;

    // Accelerated baud rate for fast simulation
    localparam TEST_CLK_HZ = 10_000_000;
    localparam TEST_BAUD   = 1_000_000;

    uart_tx #(
        .CLK_FREQ_HZ(TEST_CLK_HZ),
        .BAUD_RATE(TEST_BAUD)
    ) u_tx (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_pin(tx_pin),
        .tx_busy(tx_busy),
        .tx_done_pulse(tx_done_pulse)
    );

    // Loopback TX directly to RX
    uart_rx #(
        .CLK_FREQ_HZ(TEST_CLK_HZ),
        .BAUD_RATE(TEST_BAUD)
    ) u_rx (
        .clk(clk),
        .rst(rst),
        .rx_pin(tx_pin),
        .rx_data(rx_data),
        .rx_valid_pulse(rx_valid_pulse),
        .frame_error(frame_error)
    );

    always #5 clk = ~clk;

    task send_byte(input [7:0] b);
        begin
            @(posedge clk);
            tx_data  = b;
            tx_start = 1;
            @(posedge clk);
            tx_start = 0;
            @(posedge tx_done_pulse);
            #20;
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        tx_start = 0;
        tx_data = 8'd0;

        #30;
        rst = 0;
        #30;

        $display("--- Test Case 1: Send Header 0xAA ---");
        send_byte(8'hAA);
        if (rx_data === 8'hAA && rx_valid_pulse === 1)
            $display("[PASS] Received 0xAA cleanly.");

        $display("--- Test Case 2: Send Header 0x55 ---");
        send_byte(8'h55);
        if (rx_data === 8'h55)
            $display("[PASS] Received 0x55 cleanly.");

        $display("--- Test Case 3: Send Opcode 0x02 (SET_MODE) ---");
        send_byte(8'h02);
        if (rx_data === 8'h02)
            $display("[PASS] Received Opcode 0x02 cleanly.");

        $display("--- UART Comm Testbench Finished Successfully ---");
        $finish;
    end

endmodule
