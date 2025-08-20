`timescale 1ns/1ps
// ------------------------------------------------------------
// Combined UART Transceiver Testbench
// TX sends → RX receives, then check results
// ------------------------------------------------------------
module tb_uart;

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

    // TX
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

    // RX
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
        reset = 1; in_valid = 0; rx_ready = 0;
        in_data = 0; parity_en = 1; parity_odd = 0;
        repeat (8) @(posedge clk);
        reset = 0;

        // Transmit HELLO
        send_byte("H");
        send_byte("E");
        send_byte("L");
        send_byte("L");
        send_byte("O");

        repeat (4000) @(posedge clk);
        $finish;
    end

    task send_byte;
        input [7:0] b;
        begin
            @(posedge clk);
            in_data  = b;
            in_valid = 1;
            @(posedge clk);
            in_valid = 0;
            wait(rx_valid);
            $display("RX: %c (0x%02h), parity_err=%b, frame_err=%b",
                     rx_data, rx_data, parity_err, frame_err);
            rx_ready = 1;
            @(posedge clk);
            rx_ready = 0;
        end
    endtask

endmodule

