// ============================================================================
// File: tb_ldr_classifier.v
// Module: tb_ldr_classifier
// Description: Testbench verifying ambient light classification with hysteresis.
// ============================================================================

`timescale 1ns / 1ps

module tb_ldr_classifier;

    reg clk;
    reg rst;
    reg [9:0] adc_value;
    reg adc_valid;
    wire [1:0] light_zone;
    wire is_dark;
    wire is_medium;
    wire is_bright;

    light_sensor_classifier #(
        .DEFAULT_THRESH_DARK(10'd350),
        .DEFAULT_THRESH_BRIGHT(10'd700),
        .HYSTERESIS_BAND(10'd30)
    ) uut (
        .clk(clk),
        .rst(rst),
        .adc_value(adc_value),
        .adc_valid(adc_valid),
        .cfg_thresh_dark(10'd350),
        .cfg_thresh_bright(10'd700),
        .light_zone(light_zone),
        .is_dark(is_dark),
        .is_medium(is_medium),
        .is_bright(is_bright)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        adc_value = 10'd200; // Dark initially
        adc_valid = 0;

        #20;
        rst = 0;
        #20;

        $display("--- Test Case 1: Dark Environment ---");
        adc_value = 10'd200;
        adc_valid = 1;
        #10;
        adc_valid = 0;
        #20;
        if (light_zone === 2'b00 && is_dark === 1)
            $display("[PASS] Correctly classified as DARK (200 ADC)");
        else
            $display("[FAIL] Incorrect classification for DARK!");

        $display("--- Test Case 2: Medium Environment ---");
        adc_value = 10'd500;
        adc_valid = 1;
        #10;
        adc_valid = 0;
        #20;
        if (light_zone === 2'b01 && is_medium === 1)
            $display("[PASS] Correctly transitioned to MEDIUM (500 ADC)");
        else
            $display("[FAIL] Incorrect classification for MEDIUM!");

        $display("--- Test Case 3: Bright Environment ---");
        adc_value = 10'd850;
        adc_valid = 1;
        #10;
        adc_valid = 0;
        #20;
        if (light_zone === 2'b10 && is_bright === 1)
            $display("[PASS] Correctly transitioned to BRIGHT (850 ADC)");
        else
            $display("[FAIL] Incorrect classification for BRIGHT!");

        $display("--- Test Case 4: Hysteresis Margin Verification ---");
        // Drop to 680 (below 700, but within hysteresis 700 - 30 = 670)
        adc_value = 10'd685;
        adc_valid = 1;
        #10;
        adc_valid = 0;
        #20;
        if (light_zone === 2'b10)
            $display("[PASS] Hysteresis prevented false downward chatter!");
        else
            $display("[FAIL] Premature state transition violated hysteresis band!");

        $display("--- LDR Classifier Testbench Finished Successfully ---");
        $finish;
    end

endmodule
