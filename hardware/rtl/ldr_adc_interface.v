// ============================================================================
// File: ldr_adc_interface.v
// Module: ldr_adc_interface
// Description: SPI Master interface for 10-bit ADC (e.g. MCP3008/Pmod ADC).
//              Periodically samples Channel 0 (connected to LDR voltage divider)
//              and outputs 10-bit digital brightness reading (0 to 1023).
// Standard: IEEE 1364-2001 Synthesizable Verilog
// ============================================================================

`timescale 1ns / 1ps

module ldr_adc_interface #(
    parameter CLK_FREQ_HZ   = 100_000_000,
    parameter SPI_SCLK_HZ   = 1_000_000,     // 1 MHz SPI clock
    parameter SAMPLE_RATE_HZ= 50            // 50 samples per second
)(
    input  wire        clk,
    input  wire        rst,
    
    // SPI Physical Interface
    output reg         spi_cs_n,
    output reg         spi_sclk,
    output reg         spi_mosi,
    input  wire        spi_miso,

    // Optional direct parallel override for testbench / internal XADC
    input  wire        sim_mode_override,
    input  wire [9:0]  sim_adc_val,
    
    // Processed Output
    output reg  [9:0]  adc_value,
    output reg         adc_data_valid
);

    // Timing counters
    localparam SCLK_DIV = CLK_FREQ_HZ / (2 * SPI_SCLK_HZ);
    localparam SAMPLE_INTERVAL = CLK_FREQ_HZ / SAMPLE_RATE_HZ;

    reg [$clog2(SCLK_DIV+1)-1:0] sclk_counter;
    reg [$clog2(SAMPLE_INTERVAL+1)-1:0] sample_timer;
    reg sclk_tick;
    reg trigger_sample;

    // SPI Controller FSM
    localparam STATE_IDLE   = 3'd0;
    localparam STATE_START  = 3'd1;
    localparam STATE_TX_CMD = 3'd2;
    localparam STATE_RX_DAT = 3'd3;
    localparam STATE_DONE   = 3'd4;

    reg [2:0] state;
    reg [4:0] bit_counter;
    reg [4:0] tx_cmd;       // MCP3008 CH0 Single-ended: Start(1), SGL(1), D2(0), D1(0), D0(0)
    reg [9:0] rx_shift_reg;
    reg miso_sync1, miso_sync2;

    // Input synchronizer for MISO
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            miso_sync1 <= 1'b0;
            miso_sync2 <= 1'b0;
        end else begin
            miso_sync1 <= spi_miso;
            miso_sync2 <= miso_sync1;
        end
    end

    // Generate SPI tick clock
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sclk_counter <= 0;
            sclk_tick    <= 1'b0;
        end else if (sclk_counter >= (SCLK_DIV - 1)) begin
            sclk_counter <= 0;
            sclk_tick    <= 1'b1;
        end else begin
            sclk_counter <= sclk_counter + 1'b1;
            sclk_tick    <= 1'b0;
        end
    end

    // Periodic sample trigger
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sample_timer   <= 0;
            trigger_sample <= 1'b0;
        end else if (sample_timer >= (SAMPLE_INTERVAL - 1)) begin
            sample_timer   <= 0;
            trigger_sample <= 1'b1;
        end else begin
            sample_timer   <= sample_timer + 1'b1;
            trigger_sample <= 1'b0;
        end
    end

    // Main SPI State Machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state          <= STATE_IDLE;
            spi_cs_n       <= 1'b1;
            spi_sclk       <= 1'b0;
            spi_mosi       <= 1'b0;
            bit_counter    <= 0;
            tx_cmd         <= 5'b11000;
            rx_shift_reg   <= 10'd0;
            adc_value      <= 10'd512; // Nominal mid-scale default
            adc_data_valid <= 1'b0;
        end else if (sim_mode_override) begin
            // Simulation override mode for testbench or hardware emulator
            adc_value      <= sim_adc_val;
            adc_data_valid <= 1'b1;
            spi_cs_n       <= 1'b1;
            spi_sclk       <= 1'b0;
        end else begin
            adc_data_valid <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    spi_cs_n <= 1'b1;
                    spi_sclk <= 1'b0;
                    if (trigger_sample) begin
                        state       <= STATE_START;
                        spi_cs_n    <= 1'b0; // Assert CS
                        tx_cmd      <= 5'b11000;
                        bit_counter <= 0;
                    end
                end

                STATE_START: begin
                    if (sclk_tick) begin
                        state    <= STATE_TX_CMD;
                        spi_mosi <= tx_cmd[4];
                    end
                end

                STATE_TX_CMD: begin
                    if (sclk_tick) begin
                        spi_sclk <= ~spi_sclk;
                        if (spi_sclk) begin
                            // Falling edge of SCLK: shift next bit
                            if (bit_counter < 4) begin
                                bit_counter <= bit_counter + 1'b1;
                                spi_mosi    <= tx_cmd[3 - bit_counter];
                            end else begin
                                bit_counter <= 0;
                                state       <= STATE_RX_DAT;
                            end
                        end
                    end
                end

                STATE_RX_DAT: begin
                    if (sclk_tick) begin
                        spi_sclk <= ~spi_sclk;
                        if (!spi_sclk) begin
                            // Rising edge of SCLK: sample MISO
                            rx_shift_reg <= {rx_shift_reg[8:0], miso_sync2};
                            if (bit_counter < 9) begin
                                bit_counter <= bit_counter + 1'b1;
                            end else begin
                                state <= STATE_DONE;
                            end
                        end
                    end
                end

                STATE_DONE: begin
                    if (sclk_tick) begin
                        spi_cs_n       <= 1'b1;
                        spi_sclk       <= 1'b0;
                        adc_value      <= rx_shift_reg;
                        adc_data_valid <= 1'b1;
                        state          <= STATE_IDLE;
                    end
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule
