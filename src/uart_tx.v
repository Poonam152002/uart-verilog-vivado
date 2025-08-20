`timescale 1ns/1ps
// ============================================================
// UART Transmitter
// Sends: start + 8 data bits + parity (optional) + stop
// ============================================================
module uart_tx (
    input  wire       clk,
    input  wire       reset,
    input  wire       oversample_tick,
    input  wire       in_valid,
    output reg        in_ready,
    input  wire [7:0] in_data,
    input  wire       parity_en,
    input  wire       parity_odd,
    output reg        tx,
    output reg        busy
);

    // FSM states
    localparam [2:0] IDLE=0, START=1, DATA=2, PARITY=3, STOP=4;

    reg [2:0] state;
    reg [3:0] bit_idx;
    reg [7:0] shifter;
    reg parity_bit;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state    <= IDLE;
            tx       <= 1'b1;
            busy     <= 1'b0;
            in_ready <= 1'b1;
            bit_idx  <= 0;
        end else begin
            if (oversample_tick) begin
                case (state)
                    IDLE: begin
                        tx       <= 1'b1;
                        busy     <= 1'b0;
                        in_ready <= 1'b1;
                        if (in_valid) begin
                            shifter    <= in_data;
                            parity_bit <= ^in_data ^ parity_odd;
                            state      <= START;
                            busy       <= 1'b1;
                            in_ready   <= 1'b0;
                        end
                    end
                    START: begin
                        tx    <= 1'b0;
                        state <= DATA;
                        bit_idx <= 0;
                    end
                    DATA: begin
                        tx <= shifter[0];
                        shifter <= {1'b0, shifter[7:1]};
                        if (bit_idx == 7) begin
                            if (parity_en)
                                state <= PARITY;
                            else
                                state <= STOP;
                        end
                        bit_idx <= bit_idx + 1;
                    end
                    PARITY: begin
                        tx    <= parity_bit;
                        state <= STOP;
                    end
                    STOP: begin
                        tx    <= 1'b1;
                        state <= IDLE;
                    end
                endcase
            end
        end
    end
endmodule

