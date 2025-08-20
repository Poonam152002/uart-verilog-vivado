`timescale 1ns/1ps
module tb_uart_rx;
    reg clk=0, reset=1;
    always #10 clk = ~clk; // 50 MHz

    wire oversample_tick, bit_tick;
    baud_gen #(.CLK_FREQ(50_000_000), .BAUD(115200)) u_baud (
        .clk(clk), .reset(reset), .oversample_tick(oversample_tick), .bit_tick(bit_tick)
    );

    // TX to drive RX
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

    // RX under test
    wire rx_valid;
    reg  rx_ready=0;
    wire [7:0] rx_data;
    wire parity_err, frame_err;

    uart_rx u_rx(
        .clk(clk), .reset(reset),
        .oversample_tick(oversample_tick),
        .rx(tx),
        .parity_en(parity_en), .parity_odd(parity_odd),
        .rx_valid(rx_valid), .rx_ready(rx_ready),
        .rx_data(rx_data), .parity_err(parity_err), .frame_err(frame_err)
    );

    initial begin
        repeat(5) @(posedge clk);
        reset = 0;

        // send byte
        @(posedge clk); in_data = 8'h55; in_valid = 1;
        @(posedge clk); in_valid = 0;

        // consume when valid
        wait(rx_valid);
        $display("RX DATA = 0x%02h parity_err=%0b frame_err=%0b", rx_data, parity_err, frame_err);
        rx_ready = 1; @(posedge clk); rx_ready = 0;

        repeat(1000) @(posedge clk);
        $finish;
    end
endmodule
