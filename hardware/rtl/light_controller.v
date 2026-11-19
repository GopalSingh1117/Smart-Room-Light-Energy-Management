// ============================================================================
// File: light_controller.v
// Module: light_controller
// Description: Central 8-State Finite State Machine (FSM) governing lighting logic,
//              energy-saving adaptation, occupancy timeouts, and manual overrides.
// Standard: IEEE 1364-2001 Synthesizable Verilog
// ============================================================================

`timescale 1ns / 1ps

module light_controller (
    input  wire        clk,
    input  wire        rst,
    
    // Sensor & Classifier inputs
    input  wire        pir_motion_detected,
    input  wire        pir_motion_pulse,
    input  wire [1:0]  light_zone,              // 2'b00: Dark, 2'b01: Medium, 2'b10: Bright
    
    // Occupancy Timer status
    input  wire        occupancy_timer_active,
    input  wire        occupancy_timer_expired,
    input  wire [7:0]  remaining_seconds,
    
    // Mode & Override inputs
    input  wire [1:0]  current_mode,            // 0: AUTO, 1: MANUAL_ON, 2: MANUAL_OFF
    input  wire [6:0]  manual_brightness,       // Manual brightness (0-100)
    input  wire        energy_saving_mode,      // Flag for aggressive daylight throttling
    
    // FSM Control Outputs
    output reg  [2:0]  fsm_state,
    output reg  [6:0]  duty_percent,            // 0%, 30%, 60%, 100% or manual %
    output reg         lighting_active,
    output reg         timer_enable,
    output reg         timer_clear,
    output reg         status_occupied
);

    // FSM States
    localparam IDLE       = 3'b000;
    localparam DAYLIGHT   = 3'b001;
    localparam OCCUPIED   = 3'b010;
    localparam LIGHT_ON   = 3'b011;
    localparam DIMMED     = 3'b100;
    localparam TIMEOUT    = 3'b101;
    localparam MANUAL_ON  = 3'b110;
    localparam MANUAL_OFF = 3'b111;

    // Operating Modes
    localparam MODE_AUTO       = 2'b00;
    localparam MODE_MANUAL_ON  = 2'b01;
    localparam MODE_MANUAL_OFF = 2'b10;

    // Light Zones
    localparam ZONE_DARK   = 2'b00;
    localparam ZONE_MEDIUM = 2'b01;
    localparam ZONE_BRIGHT = 2'b10;

    reg [2:0] next_state;

    // State Register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fsm_state <= IDLE;
        end else begin
            fsm_state <= next_state;
        end
    end

    // Next-State Combinational Logic
    always @(*) begin
        // Default transition
        next_state = fsm_state;

        // Global manual mode priority
        if (current_mode == MODE_MANUAL_ON) begin
            next_state = MANUAL_ON;
        end else if (current_mode == MODE_MANUAL_OFF) begin
            next_state = MANUAL_OFF;
        end else begin
            // Automatic Mode Transitions
            case (fsm_state)
                IDLE: begin
                    if (pir_motion_pulse || pir_motion_detected) begin
                        if (light_zone == ZONE_BRIGHT)
                            next_state = DAYLIGHT;
                        else
                            next_state = OCCUPIED;
                    end
                end

                DAYLIGHT: begin
                    // Room is occupied or motion occurred, but ambient light is Bright
                    if (light_zone != ZONE_BRIGHT && (pir_motion_detected || occupancy_timer_active)) begin
                        // Environment darkened while still occupied
                        next_state = OCCUPIED;
                    end else if (!occupancy_timer_active && !pir_motion_detected) begin
                        next_state = IDLE;
                    end
                end

                OCCUPIED: begin
                    // Room occupancy confirmed: evaluate light level
                    if (light_zone == ZONE_BRIGHT) begin
                        next_state = DAYLIGHT;
                    end else if (light_zone == ZONE_DARK) begin
                        next_state = LIGHT_ON;
                    end else begin
                        next_state = DIMMED;
                    end
                end

                LIGHT_ON: begin
                    if (occupancy_timer_expired) begin
                        next_state = TIMEOUT;
                    end else if (light_zone == ZONE_BRIGHT && energy_saving_mode) begin
                        next_state = DAYLIGHT;
                    end else if (light_zone == ZONE_MEDIUM) begin
                        next_state = DIMMED;
                    end else if (remaining_seconds <= 8'd5 && remaining_seconds > 8'd0) begin
                        // Inactivity warning phase: pre-dim light before full shutdown
                        next_state = DIMMED;
                    end
                end

                DIMMED: begin
                    if (occupancy_timer_expired) begin
                        next_state = TIMEOUT;
                    end else if (pir_motion_pulse && (light_zone == ZONE_DARK)) begin
                        // Fresh motion restores full brightness in dark room
                        next_state = LIGHT_ON;
                    end else if (light_zone == ZONE_BRIGHT) begin
                        next_state = DAYLIGHT;
                    end
                end

                TIMEOUT: begin
                    // One-cycle transition state signaling shutdown
                    next_state = IDLE;
                end

                MANUAL_ON: begin
                    if (current_mode != MODE_MANUAL_ON)
                        next_state = (current_mode == MODE_MANUAL_OFF) ? MANUAL_OFF : IDLE;
                end

                MANUAL_OFF: begin
                    if (current_mode != MODE_MANUAL_OFF)
                        next_state = (current_mode == MODE_MANUAL_ON) ? MANUAL_ON : IDLE;
                end

                default: next_state = IDLE;
            endcase
        end
    end

    // Output Logic (Moore/Mealy registered)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            duty_percent    <= 7'd0;
            lighting_active <= 1'b0;
            timer_enable    <= 1'b0;
            timer_clear     <= 1'b1;
            status_occupied <= 1'b0;
        end else begin
            timer_clear <= 1'b0;

            case (next_state)
                IDLE: begin
                    duty_percent    <= 7'd0;
                    lighting_active <= 1'b0;
                    timer_enable    <= 1'b0;
                    status_occupied <= 1'b0;
                end

                DAYLIGHT: begin
                    duty_percent    <= 7'd0;
                    lighting_active <= 1'b0;
                    timer_enable    <= 1'b1; // Keep timer ticking
                    status_occupied <= pir_motion_detected || occupancy_timer_active;
                end

                OCCUPIED: begin
                    timer_enable    <= 1'b1;
                    status_occupied <= 1'b1;
                    if (light_zone == ZONE_DARK) begin
                        duty_percent    <= 7'd100; // 100% High
                        lighting_active <= 1'b1;
                    end else if (light_zone == ZONE_MEDIUM) begin
                        duty_percent    <= (energy_saving_mode) ? 7'd30 : 7'd60; // 30% or 60%
                        lighting_active <= 1'b1;
                    end else begin
                        duty_percent    <= 7'd0;
                        lighting_active <= 1'b0;
                    end
                end

                LIGHT_ON: begin
                    duty_percent    <= 7'd100; // 100% High
                    lighting_active <= 1'b1;
                    timer_enable    <= 1'b1;
                    status_occupied <= 1'b1;
                end

                DIMMED: begin
                    // Reduced brightness: 30% or 60% based on energy saving
                    duty_percent    <= (energy_saving_mode) ? 7'd30 : 7'd60;
                    lighting_active <= 1'b1;
                    timer_enable    <= 1'b1;
                    status_occupied <= 1'b1;
                end

                TIMEOUT: begin
                    duty_percent    <= 7'd0;
                    lighting_active <= 1'b0;
                    timer_enable    <= 1'b0;
                    timer_clear     <= 1'b1;
                    status_occupied <= 1'b0;
                end

                MANUAL_ON: begin
                    duty_percent    <= (manual_brightness > 7'd0) ? manual_brightness : 7'd100;
                    lighting_active <= 1'b1;
                    timer_enable    <= 1'b0; // Manual ON bypasses inactivity timer
                    status_occupied <= 1'b1;
                end

                MANUAL_OFF: begin
                    duty_percent    <= 7'd0;
                    lighting_active <= 1'b0;
                    timer_enable    <= 1'b0;
                    status_occupied <= 1'b0;
                end

                default: begin
                    duty_percent    <= 7'd0;
                    lighting_active <= 1'b0;
                    timer_enable    <= 1'b0;
                    status_occupied <= 1'b0;
                end
            endcase
        end
    end

endmodule
