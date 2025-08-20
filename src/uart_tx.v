// ============================================================
// UART Transmitter (8N1 format, no parity) - Verilog
// ============================================================
module uart_tx #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD     = 115200
)(
    input  wire clk,
    input  wire reset,
    input  wire tx_start,       // Start transmission
    input  wire [7:0] tx_data,  // Byte to send
    output reg  tx,             // Serial output
    output reg  tx_busy         // High when transmitting
);

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;
    reg [3:0] bit_index;
    reg [7:0] shift_reg;

    wire bit_tick;
    baud_gen #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) baud_inst (
        .clk(clk),
        .reset(reset),
        .oversample_tick(),
        .bit_tick(bit_tick)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            tx <= 1;
            tx_busy <= 0;
            bit_index <= 0;
            shift_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1;
                    tx_busy <= 0;
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        state <= START;
                        tx_busy <= 1;
                    end
                end
                START: if (bit_tick) begin
                    tx <= 0;
                    state <= DATA;
                    bit_index <= 0;
                end
                DATA: if (bit_tick) begin
                    tx <= shift_reg[bit_index];
                    if (bit_index == 7) state <= STOP;
                    else bit_index <= bit_index + 1;
                end
                STOP: if (bit_tick) begin
                    tx <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule


