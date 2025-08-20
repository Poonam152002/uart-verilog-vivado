// ============================================================
// Simple Synchronous FIFO (byte-wide)
// Parameters:
//   DEPTH : number of entries (power of two recommended)
// Ports:
//   wr_en : write enable (when !full)
//   rd_en : read  enable (when !empty)
//   full  : asserted when no more writes allowed
//   empty : asserted when no more reads allowed
// ============================================================
module fifo #(
    parameter integer DEPTH = 16
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        wr_en,
    input  wire        rd_en,
    input  wire [7:0]  data_in,
    output reg  [7:0]  data_out,
    output wire        full,
    output wire        empty,
    output reg  [15:0] level // occupancy for debug
);
    localparam PTR_W = $clog2(DEPTH);
    reg [7:0] mem [0:DEPTH-1];
    reg [PTR_W:0] wr_ptr; // extra bit for full/empty distinction
    reg [PTR_W:0] rd_ptr;

    wire [PTR_W:0] wr_ptr_next = wr_ptr + (wr_en && !full);
    wire [PTR_W:0] rd_ptr_next = rd_ptr + (rd_en && !empty);

    assign empty = (wr_ptr == rd_ptr);
    assign full  = ( (wr_ptr[PTR_W]    != rd_ptr[PTR_W]) &&
                     (wr_ptr[PTR_W-1:0] == rd_ptr[PTR_W-1:0]) );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[PTR_W-1:0]] <= data_in;
            wr_ptr <= wr_ptr_next;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rd_ptr  <= 0;
            data_out <= 8'h00;
        end else if (rd_en && !empty) begin
            data_out <= mem[rd_ptr[PTR_W-1:0]];
            rd_ptr <= rd_ptr_next;
        end
    end

    // occupancy
    always @(*) begin
        level = wr_ptr - rd_ptr;
    end
endmodule
