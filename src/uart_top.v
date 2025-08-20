// ============================================================
// UART Top: TX/RX with FIFOs and loopback (for simulation/demo)
// - TX path: write into tx_fifo; data pops when uart_tx ready
// - RX path: uart_rx -> rx_fifo; read via rx_rd
// - Loopback: tx line is tied to rx line internally
// ============================================================
module uart_top #(
    parameter integer CLK_FREQ = 50_000_000,
    parameter integer BAUD     = 115200
)(
    input  wire clk,
    input  wire reset,
    // TX side
    input  wire        tx_wr,
    input  wire [7:0]  tx_data_in,
    output wire        tx_full,
    // RX side
    input  wire        rx_rd,
    output wire [7:0]  rx_data_out,
    output wire        rx_empty,
    // control
    input  wire parity_en,
    input  wire parity_odd,
    // status
    output wire [15:0] tx_level,
    output wire [15:0] rx_level,
    output wire        parity_err_flag,
    output wire        frame_err_flag
);
    wire oversample_tick, bit_tick;
    wire tx_line;
    wire rx_line = tx_line; // loopback

    // baud gen
    baud_gen #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) u_baud (
        .clk(clk), .reset(reset),
        .oversample_tick(oversample_tick),
        .bit_tick(bit_tick)
    );

    // TX FIFO
    wire [7:0] tx_fifo_out;
    wire       tx_fifo_empty;
    wire       tx_fifo_rd;
    fifo #(.DEPTH(16)) u_tx_fifo (
        .clk(clk), .reset(reset),
        .wr_en(tx_wr), .rd_en(tx_fifo_rd),
        .data_in(tx_data_in), .data_out(tx_fifo_out),
        .full(tx_full), .empty(tx_fifo_empty), .level(tx_level)
    );

    // UART TX
    wire tx_in_valid  = !tx_fifo_empty;
    wire tx_in_ready;
    wire tx_busy;
    assign tx_fifo_rd = tx_in_valid & tx_in_ready;

    uart_tx u_tx (
        .clk(clk), .reset(reset),
        .oversample_tick(oversample_tick),
        .in_valid(tx_in_valid), .in_ready(tx_in_ready),
        .in_data(tx_fifo_out),
        .parity_en(parity_en), .parity_odd(parity_odd),
        .tx(tx_line), .busy(tx_busy)
    );

    // UART RX
    wire       rx_valid;
    reg        rx_ready;
    wire [7:0] rx_data;
    wire       parity_err, frame_err;

    uart_rx u_rx (
        .clk(clk), .reset(reset),
        .oversample_tick(oversample_tick),
        .rx(rx_line),
        .parity_en(parity_en), .parity_odd(parity_odd),
        .rx_valid(rx_valid), .rx_ready(rx_ready),
        .rx_data(rx_data), .parity_err(parity_err), .frame_err(frame_err)
    );

    // RX FIFO
    wire rx_fifo_full;
    assign parity_err_flag = parity_err;
    assign frame_err_flag  = frame_err;

    fifo #(.DEPTH(16)) u_rx_fifo (
        .clk(clk), .reset(reset),
        .wr_en(rx_valid), .rd_en(rx_rd),
        .data_in(rx_data), .data_out(rx_data_out),
        .full(rx_fifo_full), .empty(rx_empty), .level(rx_level)
    );

    // Consume rx_valid (1-cycle ready) when we push to RX FIFO
    always @(posedge clk or posedge reset) begin
        if (reset) rx_ready <= 1'b0;
        else       rx_ready <= rx_valid; // single-cycle consume
    end
endmodule
