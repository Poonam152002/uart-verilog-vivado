`timescale 1ns/1ps
// ============================================================
// UART Top-Level with FIFO for TX and RX
// ============================================================
module uart_top #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD     = 115200
)(
    input  wire       clk,
    input  wire       reset,
    // UART pins
    input  wire       rx,
    output wire       tx,
    // Application interface
    input  wire       tx_wr_en,
    input  wire [7:0] tx_wr_data,
    output wire       tx_full,
    output wire       tx_busy,

    input  wire       rx_rd_en,
    output wire [7:0] rx_rd_data,
    output wire       rx_empty,
    output wire       rx_valid,
    output wire       parity_err,
    output wire       frame_err,

    input  wire       parity_en,
    input  wire       parity_odd
);

    // ----------------------------------------------------------
    // Baud generator
    // ----------------------------------------------------------
    wire oversample_tick, bit_tick;
    baud_gen #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD(BAUD)
    ) baud_gen_inst (
        .clk(clk),
        .reset(reset),
        .oversample_tick(oversample_tick),
        .bit_tick(bit_tick)
    );

    // ----------------------------------------------------------
    // TX FIFO
    // ----------------------------------------------------------
    wire [7:0] tx_data;
    wire       tx_fifo_empty;
    wire       tx_fifo_rd_en;

    fifo #(.DEPTH(16), .WIDTH(8)) tx_fifo (
        .clk(clk),
        .reset(reset),
        .wr_en(tx_wr_en),
        .wr_data(tx_wr_data),
        .rd_en(tx_fifo_rd_en),
        .rd_data(tx_data),
        .full(tx_full),
        .empty(tx_fifo_empty)
    );

    // ----------------------------------------------------------
    // UART TX
    // ----------------------------------------------------------
    wire tx_in_ready;
    uart_tx tx_inst (
        .clk(clk),
        .reset(reset),
        .oversample_tick(bit_tick),
        .in_valid(!tx_fifo_empty),
        .in_ready(tx_in_ready),
        .in_data(tx_data),
        .parity_en(parity_en),
        .parity_odd(parity_odd),
        .tx(tx),
        .busy(tx_busy)
    );

    assign tx_fifo_rd_en = tx_in_ready & !tx_fifo_empty;

    // ----------------------------------------------------------
    // UART RX
    // ----------------------------------------------------------
    wire [7:0] rx_data;
    wire       rx_valid_int;

    uart_rx rx_inst (
        .clk(clk),
        .reset(reset),
        .oversample_tick(oversample_tick),
        .rx(rx),
        .parity_en(parity_en),
        .parity_odd(parity_odd),
        .rx_valid(rx_valid_int),
        .rx_ready(!rx_empty),  // automatically push to FIFO
        .rx_data(rx_data),
        .parity_err(parity_err),
        .frame_err(frame_err)
    );

    // ----------------------------------------------------------
    // RX FIFO
    // ----------------------------------------------------------
    fifo #(.DEPTH(16), .WIDTH(8)) rx_fifo (
        .clk(clk),
        .reset(reset),
        .wr_en(rx_valid_int),
        .wr_data(rx_data),
        .rd_en(rx_rd_en),
        .rd_data(rx_rd_data),
        .full(),       // not used
        .empty(rx_empty)
    );

    assign rx_valid = !rx_empty;

endmodule




