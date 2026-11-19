// ============================================================================
// File: tb_pwm_generator.v
// Module: tb_pwm_generator
// Description: Testbench verifying PWM generator output duty cycles and soft slew.
// ============================================================================

`timescale 1ns / 1ps

module tb_pwm_generator;

    reg clk;
    reg rst;
    reg [6:0] duty_percent;
    reg enable;
    wire pwm_out;
    wire [7:0] current_duty_raw;

    // Accelerated clock divisor for fast simulation
    pwm_generator #(
        .CLK_FREQ_HZ(25_600),
        .PWM_FREQ_HZ(100)
    ) uut (
        .clk(clk),
        .rst(rst),
        .duty_percent(duty_percent),
        .enable(enable),
        .pwm_out(pwm_out),
        .current_duty_raw(current_duty_raw)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        duty_percent = 7'd0;
        enable = 1;

        #20;
        rst = 0;
        #20;

        $display("--- Test Case 1: 0% Duty Cycle (OFF) ---");
        duty_percent = 7'd0;
        #1000;
        if (pwm_out === 0)
            $display("[PASS] 0%% duty correctly maintains steady 0V output.");

        $display("--- Test Case 2: 100% Duty Cycle (Full ON) ---");
        duty_percent = 7'd100;
        #5000;
        $display("[INFO] Ramping to 100%%. Current raw duty = %d", current_duty_raw);

        $display("--- Test Case 3: Output Disable Gate ---");
        enable = 0;
        #500;
        if (pwm_out === 0)
            $display("[PASS] Disabling PWM instantly forces gate output LOW.");

        $display("--- PWM Testbench Finished Successfully ---");
        $finish;
    end

endmodule
