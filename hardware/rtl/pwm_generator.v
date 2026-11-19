// ============================================================================
// File: pwm_generator.v
// Module: pwm_generator
// Description: Flicker-free 8-bit PWM generator with soft brightness slew transition.
//              Converts duty percentage (0% to 100%) to high-frequency PWM output.
// Standard: IEEE 1364-2001 Synthesizable Verilog
// ============================================================================

`timescale 1ns / 1ps

module pwm_generator #(
    parameter CLK_FREQ_HZ = 100_000_000,
    parameter PWM_FREQ_HZ = 5_000        // 5 kHz flicker-free switching
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [6:0] duty_percent,      // Target duty cycle: 0 to 100 (%)
    input  wire       enable,            // Master output enable
    output reg        pwm_out,           // Output to MOSFET gate driver
    output reg  [7:0] current_duty_raw   // Direct 0-255 raw value for telemetry/energy counter
);

    // PWM counter calculations: 100MHz / 5kHz = 20,000 cycles per PWM period
    // 20,000 / 256 steps ≈ 78 clock cycles per PWM tick
    localparam TICK_DIV = CLK_FREQ_HZ / (PWM_FREQ_HZ * 256);

    reg [$clog2(TICK_DIV+1)-1:0] tick_counter;
    reg [7:0] pwm_counter;
    reg [7:0] target_duty_raw;
    reg [7:0] smoothed_duty_raw;
    reg [19:0] slew_counter; // Slew rate limiter for smooth transitions

    // Convert duty percentage (0-100) to 8-bit raw value (0-255)
    // Formula: raw = (percent * 255) / 100
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            target_duty_raw <= 8'd0;
        end else begin
            if (duty_percent >= 7'd100)
                target_duty_raw <= 8'd255;
            else if (duty_percent == 7'd0)
                target_duty_raw <= 8'd0;
            else
                target_duty_raw <= (duty_percent * 8'd255) / 7'd100;
        end
    end

    // Smooth brightness transition (soft fade)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            smoothed_duty_raw <= 8'd0;
            slew_counter      <= 20'd0;
        end else begin
            slew_counter <= slew_counter + 1'b1;
            // Update smoothed duty every ~10ms (1,000,000 cycles at 100MHz)
            if (slew_counter >= 20'd1_000_000) begin
                slew_counter <= 20'd0;
                if (smoothed_duty_raw < target_duty_raw)
                    smoothed_duty_raw <= smoothed_duty_raw + 1'b1;
                else if (smoothed_duty_raw > target_duty_raw)
                    smoothed_duty_raw <= smoothed_duty_raw - 1'b1;
            end
        end
    end

    // High-frequency PWM counter & output comparator
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tick_counter     <= 0;
            pwm_counter      <= 8'd0;
            pwm_out          <= 1'b0;
            current_duty_raw <= 8'd0;
        end else if (!enable) begin
            pwm_out          <= 1'b0;
            current_duty_raw <= 8'd0;
        end else begin
            current_duty_raw <= smoothed_duty_raw;
            if (tick_counter >= (TICK_DIV - 1)) begin
                tick_counter <= 0;
                pwm_counter  <= pwm_counter + 1'b1;

                if (smoothed_duty_raw == 8'd0) begin
                    pwm_out <= 1'b0;
                end else if (smoothed_duty_raw == 8'd255) begin
                    pwm_out <= 1'b1;
                end else begin
                    pwm_out <= (pwm_counter < smoothed_duty_raw) ? 1'b1 : 1'b0;
                end
            end else begin
                tick_counter <= tick_counter + 1'b1;
            end
        end
    end

endmodule
