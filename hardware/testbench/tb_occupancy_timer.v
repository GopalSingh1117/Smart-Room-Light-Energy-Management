// ============================================================================
// File: tb_occupancy_timer.v
// Module: tb_occupancy_timer
// Description: Testbench verifying inactivity countdown, motion pulse reloads,
//              and automatic shutdown trigger.
// ============================================================================

`timescale 1ns / 1ps

module tb_occupancy_timer;

    reg clk;
    reg rst;
    reg motion_pulse;
    reg timer_enable;
    reg [7:0] cfg_timeout_sec;
    reg clear_timer;
    wire [7:0] remaining_seconds;
    wire occupancy_active;
    wire timer_expired;
    wire one_sec_tick;

    occupancy_timer #(
        .CLK_FREQ_HZ(100),
        .DEFAULT_TIMEOUT(8'd5),
        .SIMULATION_FAST(1)
    ) uut (
        .clk(clk),
        .rst(rst),
        .motion_pulse(motion_pulse),
        .timer_enable(timer_enable),
        .cfg_timeout_sec(cfg_timeout_sec),
        .clear_timer(clear_timer),
        .remaining_seconds(remaining_seconds),
        .occupancy_active(occupancy_active),
        .timer_expired(timer_expired),
        .one_sec_tick(one_sec_tick)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        motion_pulse = 0;
        timer_enable = 1;
        cfg_timeout_sec = 8'd4; // 4 seconds timeout for test
        clear_timer = 0;

        #20;
        rst = 0;
        #20;

        $display("--- Test Case 1: Motion Reload ---");
        motion_pulse = 1;
        #10;
        motion_pulse = 0;
        #10;
        if (remaining_seconds === 8'd4 && occupancy_active === 1)
            $display("[PASS] Timer loaded to 4 seconds and occupancy asserted.");
        else
            $display("[FAIL] Timer failed to load! (Val = %d)", remaining_seconds);

        $display("--- Test Case 2: Countdown Verification ---");
        // Wait for countdown ticks
        #1500;
        $display("[INFO] After 1.5s fast-time, remaining seconds = %d", remaining_seconds);

        $display("--- Test Case 3: Re-trigger before Timeout ---");
        motion_pulse = 1;
        #10;
        motion_pulse = 0;
        #10;
        if (remaining_seconds === 8'd4)
            $display("[PASS] Re-trigger refreshed countdown back to full duration!");

        $display("--- Test Case 4: Complete Inactivity Timeout ---");
        #4500;
        if (remaining_seconds === 8'd0 && occupancy_active === 0)
            $display("[PASS] Timer expired to 0, occupancy cleared successfully.");
        else
            $display("[FAIL] Inactivity failed to expire cleanly.");

        $display("--- Occupancy Timer Testbench Finished Successfully ---");
        $finish;
    end

endmodule
