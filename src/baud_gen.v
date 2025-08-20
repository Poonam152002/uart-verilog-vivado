// ============================================================
// Baud Rate Generator (16x oversampling) - Verilog
// ============================================================
module baud_gen #(
    parameter CLK_FREQ = 50000000,  // input clock frequency
    parameter BAUD     = 115200     // baud rate
)(
    input  wire clk,
    input  wire reset,
    output reg  oversample_tick, // 16x tick
    output reg  bit_tick         // 1x tick
);

    // Divider values
    localparam DIV_16X = CLK_FREQ / (BAUD * 16);
    localparam DIV_1X  = CLK_FREQ / BAUD;

    integer cnt_16x;
    integer cnt_1x;

    // 16x tick generator
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt_16x <= 0;
            oversample_tick <= 0;
        end else begin
            if (cnt_16x >= DIV_16X - 1) begin
                cnt_16x <= 0;
                oversample_tick <= 1;
            end else begin
                cnt_16x <= cnt_16x + 1;
                oversample_tick <= 0;
            end
        end
    end

    // 1x tick generator
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt_1x <= 0;
            bit_tick <= 0;
        end else begin
            if (cnt_1x >= DIV_1X - 1) begin
                cnt_1x <= 0;
                bit_tick <= 1;
            end else begin
                cnt_1x <= cnt_1x + 1;
                bit_tick <= 0;
            end
        end
    end

endmodule

       
