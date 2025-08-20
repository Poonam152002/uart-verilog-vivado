`timescale 1ns/1ps
// ============================================================
// Baud Rate Generator (16x oversampling)
// Generates oversample_tick (16x) and bit_tick (1x)
// ============================================================
module baud_gen #( 
    parameter CLK_FREQ = 50000000,  // Hz
    parameter BAUD     = 115200
)(
    input  wire clk,
    input  wire reset,
    output reg  oversample_tick,
    output reg  bit_tick
);

    localparam integer DIVISOR = CLK_FREQ / (BAUD * 16);
    localparam integer WIDTH   = $clog2(DIVISOR);

    reg [WIDTH-1:0] count;
    reg [3:0]       os_count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count            <= 0;
            os_count         <= 0;
            oversample_tick  <= 0;
            bit_tick         <= 0;
        end else begin
            oversample_tick <= 0;
            bit_tick        <= 0;
            if (count == DIVISOR-1) begin
                count <= 0;
                oversample_tick <= 1;
                if (os_count == 15) begin
                    os_count <= 0;
                    bit_tick <= 1;
                end else begin
                    os_count <= os_count + 1;
                end
            end else begin
                count <= count + 1;
            end
        end
    end
endmodule

