// ============================================================================
// File: seven_segment_decoder.v
// Module: seven_segment_decoder
// Description: 4-digit multiplexed seven-segment display controller.
//              Displays Operating Mode ('AU', 'On', 'OF') on Digits 3-2,
//              and Brightness percentage or Countdown Seconds on Digits 1-0.
// Standard: IEEE 1364-2001 Synthesizable Verilog
// ============================================================================

`timescale 1ns / 1ps

module seven_segment_decoder #(
    parameter CLK_FREQ_HZ = 100_000_000,
    parameter SCAN_DIV    = CLK_FREQ_HZ / 1000 // 1 kHz scan rate
)(
    input  wire       clk,
    input  wire       rst,
    
    // Status inputs
    input  wire [1:0] current_mode,      // 0: AUTO, 1: MANUAL_ON, 2: MANUAL_OFF
    input  wire [6:0] duty_percent,      // 0 to 100
    input  wire [7:0] timeout_sec,       // Remaining seconds
    input  wire       display_timeout,   // If 1, show seconds; if 0, show brightness %
    
    // Physical pins (Basys 3 active-low common anode)
    output reg  [6:0] seg,               // Segments a, b, c, d, e, f, g (active low)
    output reg  [3:0] an                 // Digit enables (active low)
);

    reg [$clog2(SCAN_DIV+1)-1:0] scan_counter;
    reg [1:0] digit_index;
    reg [3:0] bcd_val;
    reg is_char_mode;
    reg [6:0] char_pattern;

    // Scan prescaler (cycles through 4 digits)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scan_counter <= 0;
            digit_index  <= 2'b00;
        end else if (scan_counter >= (SCAN_DIV - 1)) begin
            scan_counter <= 0;
            digit_index  <= digit_index + 1'b1;
        end else begin
            scan_counter <= scan_counter + 1'b1;
        end
    end

    // Binary to BCD for 2 digits (Value 00 to 99)
    wire [6:0] disp_num = (display_timeout && timeout_sec < 8'd100) ? timeout_sec[6:0] : duty_percent;
    wire [3:0] tens_digit = disp_num / 10;
    wire [3:0] ones_digit = disp_num % 10;

    // Multiplexer for current digit
    always @(*) begin
        is_char_mode = 1'b0;
        char_pattern = 7'b1111111;
        bcd_val      = 4'd0;

        case (digit_index)
            2'b00: begin // Digit 0 (Rightmost): Ones of Brightness or Seconds
                an      = 4'b1110;
                bcd_val = ones_digit;
            end

            2'b01: begin // Digit 1: Tens of Brightness or Seconds
                an      = 4'b1101;
                bcd_val = tens_digit;
            end

            2'b10: begin // Digit 2: Mode Character 2 ('U', 'n', 'F')
                an           = 4'b1011;
                is_char_mode = 1'b1;
                case (current_mode)
                    2'b00: char_pattern = 7'b1000001; // 'U' (b,c,d,e,f on)
                    2'b01: char_pattern = 7'b0101011; // 'n' (c,e,g on)
                    2'b10: char_pattern = 7'b0001110; // 'F' (a,e,f,g on)
                    default: char_pattern = 7'b1111111;
                endcase
            end

            2'b11: begin // Digit 3 (Leftmost): Mode Character 1 ('A', 'O', 'O')
                an           = 4'b0111;
                is_char_mode = 1'b1;
                case (current_mode)
                    2'b00: char_pattern = 7'b0001000; // 'A'
                    2'b01: char_pattern = 7'b0000001; // 'O'
                    2'b10: char_pattern = 7'b0000001; // 'O'
                    default: char_pattern = 7'b1111111;
                endcase
            end
        endcase
    end

    // Standard BCD to 7-Segment Decoder (Active-Low Common Anode: 0 lights up segment)
    // Segments: {g, f, e, d, c, b, a}
    always @(*) begin
        if (is_char_mode) begin
            seg = char_pattern;
        end else begin
            case (bcd_val)
                4'd0: seg = 7'b1000000; // "0"
                4'd1: seg = 7'b1111001; // "1"
                4'd2: seg = 7'b0100100; // "2"
                4'd3: seg = 7'b0110000; // "3"
                4'd4: seg = 7'b0011001; // "4"
                4'd5: seg = 7'b0010010; // "5"
                4'd6: seg = 7'b0000010; // "6"
                4'd7: seg = 7'b1111000; // "7"
                4'd8: seg = 7'b0000000; // "8"
                4'd9: seg = 7'b0010000; // "9"
                default: seg = 7'b1111111;
            endcase
        end
    end

endmodule
