`timescale 1ns/1ps
// ============================================================
// UART Receiver
// Receives: start + 8 data + parity(optional) + stop
// ============================================================
module uart_rx (
    input  wire       clk,
    input  wire       reset,
    input  wire       oversample_tick,
    input  wire       rx,
    input  wire       parity_en,
    input  wire       parity_odd,
    output reg        rx_valid,
    input  wire       rx_ready,
    output reg [7:0]  rx_data,
    output reg        parity_err,
    output reg        frame_err
);

    localparam [2:0] IDLE=0, START=1, DATA=2, PARITY=3, STOP=4;

    reg [2:0] state;
    reg [3:0] bit_idx;
    reg [3:0] sample_cnt;
    reg [7:0] shifter;
    reg parity_bit;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state      <= IDLE;
            rx_valid   <= 0;
            bit_idx    <= 0;
            sample_cnt <= 0;
            rx_data    <= 0;
            parity_err <= 0;
            frame_err  <= 0;
        end else begin
            if (oversample_tick) begin
                case (state)
                    IDLE: begin
                        rx_valid <= 0;
                        if (rx == 0) begin // start bit detected
                            state      <= START;
                            sample_cnt <= 0;
                        end
                    end
                    START: begin
                        if (sample_cnt == 7) begin // mid start bit
                            if (rx == 0) begin
                                state      <= DATA;
                                bit_idx    <= 0;
                                sample_cnt <= 0;
                            end else
                                state <= IDLE;
                        end else
                            sample_cnt <= sample_cnt + 1;
                    end
                    DATA: begin
                        if (sample_cnt == 15) begin
                            shifter    <= {rx, shifter[7:1]};
                            bit_idx    <= bit_idx + 1;
                            sample_cnt <= 0;
                            if (bit_idx == 7) begin
                                if (parity_en)
                                    state <= PARITY;
                                else
                                    state <= STOP;
                            end
                        end else
                            sample_cnt <= sample_cnt + 1;
                    end
                    PARITY: begin
                        if (sample_cnt == 15) begin
                            parity_bit <= rx;
                            if (rx != (^shifter ^ parity_odd))
                                parity_err <= 1;
                            state      <= STOP;
                            sample_cnt <= 0;
                        end else
                            sample_cnt <= sample_cnt + 1;
                    end
                    STOP: begin
                        if (sample_cnt == 15) begin
                            if (rx == 1) begin
                                rx_data  <= shifter;
                                rx_valid <= 1;
                            end else
                                frame_err <= 1;
                            state <= IDLE;
                        end else
                            sample_cnt <= sample_cnt + 1;
                    end
                endcase
            end

            // Clear rx_valid when consumed
            if (rx_valid && rx_ready)
                rx_valid <= 0;
        end
    end
endmodule

