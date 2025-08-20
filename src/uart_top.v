// ============================================================
// UART Top Module (with TX, RX, Baud Generator, and FIFOs)
// ============================================================

module uart_top #(
    parameter CLK_FREQ = 50000000,   // 50 MHz clock
    parameter BAUD     = 9600
)(
    input  wire clk,
    input  wire rst,
    input  wire rx,
    input  wire [7:0] tx_data_in,
    input  wire tx_wr_en,
    output wire tx,
    output wire [7:0] rx_data_out,
    input  wire rx_rd_en,
    output wire tx_full,
    output wire rx_empty
);

    wire tick, bit_tick;
    wire tx_fifo_empty, tx_fifo_rd_en;
    wire rx_fifo_full, rx_fifo_wr_en;
    wire [7:0] tx_fifo_dout, rx_fifo_din;

    // Baud Generator
    baud_gen #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) baud_inst (
        .clk(clk),
        .rst(rst),
        .tick(tick),
        .bit_tick(bit_tick)
    );

    // TX FIFO
    uart_fifo tx_fifo (
        .clk(clk), .rst(rst),
        .wr_en(tx_wr_en), .rd_en(tx_fifo_rd_en),
        .din(tx_data_in), .dout(tx_fifo_dout),
        .full(tx_full), .empty(tx_fifo_empty)
    );

    // UART Transmitter
    uart_tx tx_inst (
        .clk(clk),
        .rst(rst),
        .bit_tick(bit_tick),
        .tx_data(tx_fifo_dout),
        .tx_start(~tx_fifo_empty),
        .tx(tx),
        .tx_done(tx_fifo_rd_en)
    );

    // RX FIFO
    uart_fifo rx_fifo (
        .clk(clk), .rst(rst),
        .wr_en(rx_fifo_wr_en), .rd_en(rx_rd_en),
        .din(rx_fifo_din), .dout(rx_data_out),
        .full(rx_fifo_full), .empty(rx_empty)
    );

    // UART Receiver
    uart_rx rx_inst (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .tick(tick),
        .rx_data(rx_fifo_din),
        .rx_done(rx_fifo_wr_en)
    );

endmodule

