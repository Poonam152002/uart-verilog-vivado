`timescale 1ns/1ps
// ------------------------------------------------------------
// Testbench: UART Transmitter
// ------------------------------------------------------------
module tb_uart_tx;

    reg clk = 0;
    always #10 clk = ~clk;   // 50 MHz clock

    reg reset = 1;

    // Baud generator
    wire oversample_tick, bit_tick;
    baud_gen #(.CLK_FREQ(50_000_000), .BAUD(115200)) u_baud (
        .clk(clk),
        .reset(reset),
        .oversample_tick(oversample_tick),
        .bit_tick(bit_tick)
    );

    // DUT: uart_tx
    reg in_valid;
    wire in_ready;
    reg [7:0] in_data;
    reg parity_en, parity_odd;
    wire tx;
    wire busy;

    uart_tx u_tx (
        .clk(clk),
        .reset(reset),
        .oversample_tick(oversample_tick),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .in_data(in_data),
        .parity_en(parity_en),
        .parity_odd(parity_odd),
        .tx(tx),
        .busy(busy)
    );

    initial begin
        // reset
        reset = 1; in_valid = 0; in_data = 8'h00;
        parity_en = 1; parity_odd = 0;
        repeat (8) @(posedge clk);
        reset = 0;

        // Send "A"
        @(posedge clk);
        in_data  = 8'h41;   // ASCII 'A'
        in_valid = 1'b1;

        @(posedge clk);
        in_valid = 1'b0;

        wait (!busy);
        repeat (2000) @(posedge clk);
        $finish;
    end
endmodule

