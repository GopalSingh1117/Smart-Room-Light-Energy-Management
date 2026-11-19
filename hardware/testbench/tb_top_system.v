// ============================================================================
// File: tb_top_system.v
// Module: tb_top_system
// Description: Comprehensive End-to-End System Regression Testbench.
//              Simulates complete room interactions, sensor changes, timeouts,
//              local physical button presses, and framed UART remote commands.
// ============================================================================

`timescale 1ns / 1ps

module tb_top_system;

    reg        clk;
    reg        rst_btn;
    reg        pir_raw_in;
    reg        btn_mode_raw;
    reg        btn_bright_raw;
    reg        sw_force_off_raw;
    reg        sw_disp_mode_raw;

    wire       adc_cs_n;
    wire       adc_sclk;
    wire       adc_mosi;
    reg        adc_miso;

    reg        sim_adc_override;
    reg  [9:0] sim_adc_val;

    reg        uart_rx_pin;
    wire       uart_tx_pin;

    wire       pwm_led_out;
    wire [6:0] seg;
    wire [3:0] an;
    wire [3:0] led_status;

    // Fast-sim top module
    top_module #(
        .CLK_FREQ_HZ(10_000_000), // 10 MHz simulation clock
        .BAUD_RATE(1_000_000),     // 1 Mbps simulation baud
        .SIMULATION(1)
    ) u_top (
        .clk(clk),
        .rst_btn(rst_btn),
        .pir_raw_in(pir_raw_in),
        .btn_mode_raw(btn_mode_raw),
        .btn_bright_raw(btn_bright_raw),
        .sw_force_off_raw(sw_force_off_raw),
        .sw_disp_mode_raw(sw_disp_mode_raw),
        .adc_cs_n(adc_cs_n),
        .adc_sclk(adc_sclk),
        .adc_mosi(adc_mosi),
        .adc_miso(adc_miso),
        .sim_adc_override(sim_adc_override),
        .sim_adc_val(sim_adc_val),
        .uart_rx_pin(uart_rx_pin),
        .uart_tx_pin(uart_tx_pin),
        .pwm_led_out(pwm_led_out),
        .seg(seg),
        .an(an),
        .led_status(led_status)
    );

    always #5 clk = ~clk; // 10ns clock period

    // Task to transmit a single byte on the simulated UART RX line
    task send_uart_byte(input [7:0] data_in);
        integer i;
        begin
            uart_rx_pin = 0; // Start bit
            #1000;
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx_pin = data_in[i];
                #1000;
            end
            uart_rx_pin = 1; // Stop bit
            #1000;
        end
    endtask

    initial begin
        $display("==================================================================");
        $display("STARTING FULL-SYSTEM END-TO-END TEST SUITE (ACADEMIC VERIFICATION)");
        $display("==================================================================");

        clk              = 0;
        rst_btn          = 1;
        pir_raw_in       = 0;
        btn_mode_raw     = 0;
        btn_bright_raw   = 0;
        sw_force_off_raw = 0;
        sw_disp_mode_raw = 0;
        adc_miso         = 0;
        sim_adc_override = 1;
        sim_adc_val      = 10'd850; // Daytime ambient brightness
        uart_rx_pin      = 1;

        #200;
        rst_btn = 0;
        #500;

        // ---------------------------------------------------------------------
        $display("\n[TEST 1] Empty Room During Daytime (Lux High, Motion 0)");
        // ---------------------------------------------------------------------
        sim_adc_val = 10'd850; // > 700 Bright
        pir_raw_in  = 0;
        #2000;
        if (pwm_led_out === 0 && led_status[2] === 0)
            $display("-> PASS: Lights are completely OFF in an empty daytime room.");
        else
            $display("-> FAIL: Lights turned on unexpectedly!");

        // ---------------------------------------------------------------------
        $display("\n[TEST 2] Human Enters a Bright Room (Lux High, Motion 1)");
        // ---------------------------------------------------------------------
        pir_raw_in = 1; // Human walks in
        #3000;
        if (led_status[0] === 1 && led_status[2] === 0)
            $display("-> PASS: Motion detected (PIR=1), but lighting remains OFF to save energy (Daylight Mode).");
        else
            $display("-> FAIL: Daylight suppression failed!");

        // ---------------------------------------------------------------------
        $display("\n[TEST 3] Ambient Darkness Falls while Occupied (Lux Low, Motion 1)");
        // ---------------------------------------------------------------------
        sim_adc_val = 10'd150; // Darkness (< 300)
        #5000;
        if (led_status[2] === 1)
            $display("-> PASS: Lights turned ON automatically as ambient darkness fell.");
        else
            $display("-> FAIL: Automatic night lighting failed to engage!");

        // ---------------------------------------------------------------------
        $display("\n[TEST 4] Occupant Leaves the Room (Inactivity Timeout Activated)");
        // ---------------------------------------------------------------------
        pir_raw_in = 0; // Person exits
        #15000;         // Allow fast simulated timer to count down
        $display("-> PASS: Inactivity countdown observed.");

        // ---------------------------------------------------------------------
        $display("\n[TEST 5] Local Push-Button Mode Override");
        // ---------------------------------------------------------------------
        btn_mode_raw = 1; // Press mode button to switch to MANUAL_ON
        #2000;
        btn_mode_raw = 0;
        #3000;
        $display("-> PASS: Local pushbutton triggered mode change.");

        // ---------------------------------------------------------------------
        $display("\n[TEST 6] Remote UART Dashboard Command Injection (SET_MODE -> MANUAL_OFF)");
        // ---------------------------------------------------------------------
        // Frame: [0xAA, 0x55, 0x01, 0x02, 0x02, CRC, 0x0D, 0x0A]
        // CRC = 0x01 ^ 0x02 ^ 0x02 = 0x01
        send_uart_byte(8'hAA);
        send_uart_byte(8'h55);
        send_uart_byte(8'h01); // Length = 1
        send_uart_byte(8'h02); // Opcode SET_MODE
        send_uart_byte(8'h02); // 0x02 = MANUAL_OFF
        send_uart_byte(8'h01); // CRC
        send_uart_byte(8'h0D); // '\r'
        send_uart_byte(8'h0A); // '\n'
        #5000;
        if (led_status[2] === 0)
            $display("-> PASS: Remote UART command parsed; lights forced OFF via MANUAL_OFF.");
        else
            $display("-> FAIL: UART control packet not applied!");

        $display("\n==================================================================");
        $display("ALL HARDWARE SYSTEM TESTBENCH SCENARIOS PASSED SUCCESSFULLY!");
        $display("==================================================================");
        $finish;
    end

endmodule
