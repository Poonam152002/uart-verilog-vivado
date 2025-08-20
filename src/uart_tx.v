// ============================================================
// UART Transmitter
// Features:
//  - 8 data bits
//  - Optional parity (even/odd)
//  - 1 stop bit
//  - Valid/Ready handshake on input
//  - Uses oversample_tick: change output every 16 ticks
// ============================================================
module uart_tx #(
    parameter integer DATA_BITS = 8
)(
    input  wire clk,
    input  wire reset,
    input  wire oversample_tick,   // 16x tick
    // handshake
    input  wire        in_valid,
    output reg         in_ready,
    input  wire [7:0]  in_data,
    // parity control
    input  wire parity_en,
    input  wire parity_odd,
    // serial out
    output reg  tx,
    output reg  busy
);
    localparam [2:0] S_IDLE=0, S_START=1, S_DATA=2, S_PAR=3, S_STOP=4;

    reg [2:0] state;
    reg [3:0] bit_idx;
    reg [3:0] os_cnt; // 0..15
    reg [7:0] shreg;
    reg       par_bit;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
            tx <= 1'b1;
            in_ready <= 1'b1;
            busy <= 1'b0;
            bit_idx <= 0;
            os_cnt <= 0;
            shreg <= 0;
            par_bit <= 0;
        end else begin
            if (state == S_IDLE) begin
                tx <= 1'b1;
                busy <= 1'b0;
                in_ready <= 1'b1;
                if (in_valid) begin
                    shreg <= in_data;
                    par_bit <= parity_odd ? ~^in_data : ^in_data; // odd = invert even parity
                    bit_idx <= 0;
                    os_cnt <= 0;
                    state <= S_START;
                    in_ready <= 1'b0;
                    busy <= 1'b1;
                end
            end else if (oversample_tick) begin
                os_cnt <= os_cnt + 1;
                case (state)
                    S_START: begin
                        tx <= 1'b0; // start bit
                        if (os_cnt == 4'd15) begin
                            os_cnt <= 0;
                            state <= S_DATA;
                        end
                    end
                    S_DATA: begin
                        tx <= shreg[0];
                        if (os_cnt == 4'd15) begin
                            os_cnt <= 0;
                            shreg <= {1'b0, shreg[7:1]}; // shift right, LSB first
                            bit_idx <= bit_idx + 1;
                            if (bit_idx == (DATA_BITS-1)) begin
                                state <= (parity_en ? S_PAR : S_STOP);
                            end
                        end
                    end
                    S_PAR: begin
                        tx <= par_bit;
                        if (os_cnt == 4'd15) begin
                            os_cnt <= 0;
                            state <= S_STOP;
                        end
                    end
                    S_STOP: begin
                        tx <= 1'b1;
                        if (os_cnt == 4'd15) begin
                            os_cnt <= 0;
                            state <= S_IDLE;
                        end
                    end
                endcase
            end
        end
    end
endmodule
