// ============================================================
// Baud Rate Generator (16x oversampling)
// Generates a 16x oversample tick and a 1x bit tick.
// Parameters:
//   CLK_FREQ: Input clock frequency in Hz
//   BAUD    : Desired baud rate (e.g., 9600, 115200)
// Notes:
//   - oversample_tick: pulses at 16*BAUD
//   - bit_tick       : pulses at BAUD (one per data bit)
// ============================================================
module baud_gen #(
    parameter integer CLK_FREQ = 50_000_000,
    parameter integer BAUD     = 115200
)(
    input  wire clk,
    input  wire reset,
    output reg  oversample_tick, // 16x tick
    output reg  bit_tick         // 1x bit tick
);
    localparam integer DIV_16X = CLK_FREQ / (BAUD * 16);
    localparam integer DIV_1X  = CLK_FREQ / (BAUD);

    integer cnt_16x;
    integer cnt_1x;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt_16x <= 0;
            oversample_tick <= 1'b0;
        end else begin
            if (cnt_16x >= (DIV_16X - 1)) begin
                cnt_16x <= 0;
                oversample_tick <= 1'b1;
            end else begin
                cnt_16x <= cnt_16x + 1;
                oversample_tick <= 1'b0;
            end
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt_1x <= 0;
            bit_tick <= 1'b0;
        end else begin
            if (cnt_1x >= (DIV_1X - 1)) begin
                cnt_1x <= 0;
                bit_tick <= 1'b1;
            end else begin
                cnt_1x <= cnt_1x + 1;
                bit_tick <= 1'b0;
            end
        end
    end
endmodule
