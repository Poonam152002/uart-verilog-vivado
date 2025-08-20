`timescale 1ns/1ps
module tb_uart_tx;
    reg clk=0, reset=1;
    always #10 clk = ~clk; // 50 MHz

    wire oversample_tick, bit_tick;
    baud_gen #(.CLK_FREQ(50_000_000), .BAUD(115200)) u_baud (
        .clk(clk), .reset(reset), .oversample_tick(oversample_tick), .bit_tick(bit_tick)
    );

    reg  in_valid=0, parity_en=1'b1, parity_odd=1'b0;
    wire in_ready, tx;
    wire busy;
    reg  [7:0] in_data;

    uart_tx u_tx(
        .clk(clk), .reset(reset),
        .oversample_tick(oversample_tick),
        .in_valid(in_valid), .in_ready(in_ready), .in_data(in_data),
        .parity_en(parity_en), .parity_odd(parity_odd),
        .tx(tx), .busy(busy)
    );

    initial begin
        repeat(5) @(posedge clk);
        reset = 0;

        @(posedge clk); in_data = "A"; in_valid = 1;
        @(posedge clk); in_valid = 0;

        wait(!busy);
        repeat(1000) @(posedge clk);
        $finish;
    end
endmodule
