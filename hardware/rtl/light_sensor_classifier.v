// ============================================================================
// File: light_sensor_classifier.v
// Module: light_sensor_classifier
// Description: Classifies ambient light into Dark, Medium, and Bright zones with
//              digital hysteresis to prevent oscillating/flickering decisions.
// Standard: IEEE 1364-2001 Synthesizable Verilog
// ============================================================================

`timescale 1ns / 1ps

module light_sensor_classifier #(
    parameter DEFAULT_THRESH_DARK   = 10'd350, // Below this is Dark
    parameter DEFAULT_THRESH_BRIGHT = 10'd700, // Above this is Bright
    parameter HYSTERESIS_BAND       = 10'd30   // Noise margin
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [9:0]  adc_value,
    input  wire        adc_valid,
    
    // Dynamic runtime configurable thresholds (from UART/dashboard)
    input  wire [9:0]  cfg_thresh_dark,
    input  wire [9:0]  cfg_thresh_bright,
    
    // Classified Output
    output reg  [1:0]  light_zone, // 2'b00: Dark, 2'b01: Medium, 2'b10: Bright
    output reg         is_dark,
    output reg         is_medium,
    output reg         is_bright
);

    wire [9:0] thresh_d = (cfg_thresh_dark != 10'd0) ? cfg_thresh_dark : DEFAULT_THRESH_DARK;
    wire [9:0] thresh_b = (cfg_thresh_bright != 10'd0) ? cfg_thresh_bright : DEFAULT_THRESH_BRIGHT;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            light_zone <= 2'b00; // Default Dark
            is_dark    <= 1'b1;
            is_medium  <= 1'b0;
            is_bright  <= 1'b0;
        end else if (adc_valid) begin
            case (light_zone)
                2'b00: begin // Currently DARK
                    if (adc_value > (thresh_d + HYSTERESIS_BAND)) begin
                        if (adc_value > thresh_b) begin
                            light_zone <= 2'b10; // Jump to Bright
                            is_dark    <= 1'b0;
                            is_medium  <= 1'b0;
                            is_bright  <= 1'b1;
                        end else begin
                            light_zone <= 2'b01; // Transition to Medium
                            is_dark    <= 1'b0;
                            is_medium  <= 1'b1;
                            is_bright  <= 1'b0;
                        end
                    end
                end

                2'b01: begin // Currently MEDIUM
                    if (adc_value < (thresh_d - HYSTERESIS_BAND)) begin
                        light_zone <= 2'b00; // Drop to Dark
                        is_dark    <= 1'b1;
                        is_medium  <= 1'b0;
                        is_bright  <= 1'b0;
                    end else if (adc_value > (thresh_b + HYSTERESIS_BAND)) begin
                        light_zone <= 2'b10; // Elevate to Bright
                        is_dark    <= 1'b0;
                        is_medium  <= 1'b0;
                        is_bright  <= 1'b1;
                    end
                end

                2'b10: begin // Currently BRIGHT
                    if (adc_value < (thresh_b - HYSTERESIS_BAND)) begin
                        if (adc_value < thresh_d) begin
                            light_zone <= 2'b00; // Drop straight to Dark
                            is_dark    <= 1'b1;
                            is_medium  <= 1'b0;
                            is_bright  <= 1'b0;
                        end else begin
                            light_zone <= 2'b01; // Drop to Medium
                            is_dark    <= 1'b0;
                            is_medium  <= 1'b1;
                            is_bright  <= 1'b0;
                        end
                    end
                end

                default: light_zone <= 2'b00;
            endcase
        end
    end

endmodule
