`timescale 1ns/1ps
// ============================================================
// Testbench for UART Top (loopback)
// - Sends "HELLO\n" into TX FIFO
// - Reads back from RX FIFO and checks data
// ============================================================
module tb_uart;
    // 50 MHz clock => 20 ns period
    reg clk = 0;
    always #10 clk = ~clk;

    reg reset = 1;

    // DUT IO
    reg        tx_wr;
    reg  [7:0] tx_data_in;
    wire       tx_full;

    reg        rx_rd;
    wire [7:0] rx_data_out;
    wire       rx_empty;

    reg        parity_en;
    reg        parity_odd;

    wire [15:0] tx_level, rx_level;
    wire parity_err_flag, frame_err_flag;

    // Instantiate DUT
    uart_top #(.CLK_FREQ(50_000_000), .BAUD(115200)) DUT (
        .clk(clk), .reset(reset),
        .tx_wr(tx_wr), .tx_data_in(tx_data_in), .tx_full(tx_full),
        .rx_rd(rx_rd), .rx_data_out(rx_data_out), .rx_empty(rx_empty),
        .parity_en(parity_en), .parity_odd(parity_odd),
        .tx_level(tx_level), .rx_level(rx_level),
        .parity_err_flag(parity_err_flag), .frame_err_flag(frame_err_flag)
    );

    task write_tx(input [7:0] b);
    begin
        @(posedge clk);
        tx_data_in <= b;
        tx_wr <= 1'b1;
        @(posedge clk);
        tx_wr <= 1'b0;
    end
    endtask

    task read_rx(output [7:0] b);
    begin
        while (rx_empty) @(posedge clk);
        rx_rd <= 1'b1;
        @(posedge clk);
        b = rx_data_out;
        rx_rd <= 1'b0;
    end
    endtask

    integer i;
    reg [7:0] ch;

    initial begin
        // init
        tx_wr = 0; rx_rd = 0; tx_data_in = 0;
        parity_en = 1'b1; parity_odd = 1'b0; // even parity
        // release reset
        repeat(10) @(posedge clk);
        reset = 0;

        // send "HELLO\n"
        write_tx("H");
        write_tx("E");
        write_tx("L");
        write_tx("L");
        write_tx("O");
        write_tx("\n");

        // read back
        for (i=0; i<6; i=i+1) begin
            read_rx(ch);
            $display("RX[%0d] = 0x%02h (%s)  parity_err=%0b frame_err=%0b  levels: TX=%0d RX=%0d",
                     i, ch, (ch>=32 && ch<127)? {ch} : " ", parity_err_flag, frame_err_flag, tx_level, rx_level);
        end

        if (parity_err_flag || frame_err_flag) $display("ERROR flags set!");
        else $display("PASS: Received string OK.");

        repeat(10000) @(posedge clk); // extra time to view waveforms
        $finish;
    end
endmodule
