`timescale 1ns/1ps
// ------------------------------------------------------------
// Testbench: UART Receiver
// Connects TX → RX
// ------------------------------------------------------------
module tb_uart_rx;

    reg clk = 0;
    always #10 clk = ~clk;   // 50 MHz

    reg reset = 1;

    wire oversample_tick, bit_tick;
    baud_gen #(.CLK_FREQ(50_000_000), .BAUD(115200)) u_baud (
        .clk(clk),
        .reset(reset),
        .oversample_tick(oversample_tick),
        .bit_tick(bit_tick)
    );

    // TX side
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

    // RX side
    wire rx_valid;
    reg rx_ready;
    wire [7:0] rx_data;
    wire parity_err, frame_err;

    uart_rx u_rx (
        .clk(clk),
        .reset(reset),
        .oversample_tick(oversample_tick),
        .rx(tx),
        .parity_en(parity_en),
        .parity_odd(parity_odd),
        .rx_valid(rx_valid),
        .rx_ready(rx_ready),
        .rx_data(rx_data),
        .parity_err(parity_err),
        .frame_err(frame_err)
    );

    initial begin
        reset = 1; in_valid = 0; in_data = 0;
        rx_ready = 0; parity_en = 1; parity_odd = 0;
        repeat (8) @(posedge clk);
        reset = 0;

        // send 0x55
        @(posedge clk);
        in_data  = 8'h55;
        in_valid = 1;

        @(posedge clk);
        in_valid = 0;

        wait(rx_valid);
        $display("RX DATA = %h parity_err=%b frame_err=%b", rx_data, parity_err, frame_err);
        rx_ready = 1;
        @(posedge clk);
        rx_ready = 0;

        repeat (2000) @(posedge clk);
        $finish;
    end
endmodule

