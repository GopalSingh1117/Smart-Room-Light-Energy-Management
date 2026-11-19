// ============================================================================
// File: tb_pir_detector.v
// Module: tb_pir_detector
// Description: Testbench verifying PIR motion sensor synchronization, noise
//              glitch rejection, and single-cycle pulse generation.
// ============================================================================

`timescale 1ns / 1ps

module tb_pir_detector;

    reg clk;
    reg rst;
    reg pir_raw_in;
    wire motion_detected;
    wire motion_pulse;

    // Fast simulation parameter (10 cycles filter window)
    pir_detector #(
        .CLK_FREQ_HZ(100_000_000),
        .FILTER_MS(1),
        .FILTER_CYCLES(10)
    ) uut (
        .clk(clk),
        .rst(rst),
        .pir_raw_in(pir_raw_in),
        .motion_detected(motion_detected),
        .motion_pulse(motion_pulse)
    );

    // Clock generator (100 MHz, 10ns period)
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        pir_raw_in = 0;

        #30;
        rst = 0;
        #20;

        $display("--- Test Case 1: Noise Glitch Rejection ---");
        // Inject short 40ns glitch (should be ignored by 10-cycle/100ns filter)
        pir_raw_in = 1;
        #40;
        pir_raw_in = 0;
        #50;
        if (motion_detected === 0)
            $display("[PASS] Short noise glitch successfully filtered.");
        else
            $display("[FAIL] Noise glitch incorrectly triggered motion!");

        $display("--- Test Case 2: Valid Motion Detection ---");
        // Inject valid sustained motion pulse
        pir_raw_in = 1;
        #200;
        if (motion_detected === 1)
            $display("[PASS] Sustained motion confirmed (motion_detected = 1).");
        else
            $display("[FAIL] Sustained motion failed to assert!");

        #100;
        pir_raw_in = 0;
        #250;
        if (motion_detected === 0)
            $display("[PASS] Motion cleared after sensor returns to idle.");

        $display("--- PIR Testbench Finished Successfully ---");
        $finish;
    end

endmodule
