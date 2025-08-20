// ============================================================
// UART Receiver
// Features:
//  - 8 data bits
//  - Optional parity (even/odd)
//  - 1 stop bit
//  - Outputs rx_valid with data + error flags
//  - 16x oversampling, sample at mid-bit (count==8)
// ============================================================
module uart_rx #(
    parameter integer DATA_BITS = 8
)(
    input  wire clk,
    input  wire reset,
    input  wire oversample_tick, // 16x tick
    input  wire rx,
    input  wire parity_en,
    input  wire parity_odd,
    output reg  rx_valid,
    input  wire rx_ready,        // consumer handshake
    output reg  [7:0] rx_data,
    output reg  parity_err,
    output reg  frame_err
);
    localparam [2:0] S_IDLE=0, S_START=1, S_DATA=2, S_PAR=3, S_STOP=4;

    reg [2:0] state;
    reg [3:0] os_cnt;
    reg [3:0] bit_idx;
    reg [7:0] shreg;
    reg       par_bit_sampled;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
            os_cnt <= 0;
            bit_idx <= 0;
            shreg <= 0;
            rx_data <= 0;
            rx_valid <= 0;
            parity_err <= 0;
            frame_err <= 0;
            par_bit_sampled <= 0;
        end else begin
            if (rx_valid && rx_ready) rx_valid <= 0;

            case (state)
                S_IDLE: begin
                    os_cnt <= 0;
                    bit_idx <= 0;
                    if (rx == 1'b0) begin
                        state <= S_START; // start edge
                        parity_err <= 0;
                        frame_err <= 0;
                    end
                end
                S_START: begin
                    if (oversample_tick) begin
                        os_cnt <= os_cnt + 1;
                        // sample mid-start
                        if (os_cnt == 4'd7) begin
                            if (rx == 1'b0) begin
                                os_cnt <= 0;
                                state <= S_DATA;
                            end else begin
                                state <= S_IDLE; // false start
                            end
                        end
                    end
                end
                S_DATA: begin
                    if (oversample_tick) begin
                        os_cnt <= os_cnt + 1;
                        if (os_cnt == 4'd7) begin
                            shreg <= {rx, shreg[7:1]}; // LSB first
                        end
                        if (os_cnt == 4'd15) begin
                            os_cnt <= 0;
                            bit_idx <= bit_idx + 1;
                            if (bit_idx == (DATA_BITS-1)) begin
                                state <= (parity_en ? S_PAR : S_STOP);
                            end
                        end
                    end
                end
                S_PAR: begin
                    if (oversample_tick) begin
                        os_cnt <= os_cnt + 1;
                        if (os_cnt == 4'd7) par_bit_sampled <= rx;
                        if (os_cnt == 4'd15) begin
                            os_cnt <= 0;
                            state <= S_STOP;
                        end
                    end
                end
                S_STOP: begin
                    if (oversample_tick) begin
                        os_cnt <= os_cnt + 1;
                        if (os_cnt == 4'd7) begin
                            // stop bit should be 1
                            if (rx != 1'b1) frame_err <= 1;
                            rx_data <= shreg;
                            // parity check
                            if (parity_en) begin
                                if (parity_odd) begin
                                    if (par_bit_sampled != (~^shreg)) parity_err <= 1;
                                end else begin
                                    if (par_bit_sampled != (^shreg)) parity_err <= 1;
                                end
                            end
                            rx_valid <= 1;
                        end
                        if (os_cnt == 4'd15) begin
                            os_cnt <= 0;
                            state <= S_IDLE;
                        end
                    end
                end
            endcase
        end
    end
endmodule
