// ============================================================
// UART Receiver (8N1 format, no parity) - Verilog
// ============================================================
module uart_rx #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD     = 115200
)(
    input  wire clk,
    input  wire reset,
    input  wire rx,             // Serial input
    output reg  [7:0] rx_data,  // Received byte
    output reg  rx_ready        // High when new data is valid
);

    localparam IDLE   = 2'b00;
    localparam START  = 2'b01;
    localparam DATA   = 2'b10;
    localparam STOP   = 2'b11;

    reg [1:0] state;
    reg [3:0] bit_index;
    reg [7:0] shift_reg;

    wire oversample_tick, bit_tick;
    baud_gen #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) baud_inst (
        .clk(clk),
        .reset(reset),
        .oversample_tick(oversample_tick),
        .bit_tick(bit_tick)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            rx_ready <= 0;
            rx_data <= 0;
            shift_reg <= 0;
            bit_index <= 0;
        end else begin
            case (state)
                IDLE: begin
                    rx_ready <= 0;
                    if (~rx) state <= START;
                end
                START: if (bit_tick) begin
                    state <= DATA;
                    bit_index <= 0;
                end
                DATA: if (bit_tick) begin
                    shift_reg[bit_index] <= rx;
                    if (bit_index == 7) state <= STOP;
                    else bit_index <= bit_index + 1;
                end
                STOP: if (bit_tick) begin
                    rx_data <= shift_reg;
                    rx_ready <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule


