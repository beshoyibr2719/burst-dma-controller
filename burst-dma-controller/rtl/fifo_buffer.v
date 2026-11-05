`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 08/01/2026 03:07:36 PM
// Design Name:
// Module Name: fifo_buffer
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
module fifo_buffer #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 16,
    parameter PTR_WIDTH  = 4  // log2(DEPTH)
)(
    input clk,
    input reset,

    // Write Interface (Push)
    input wr_en,
    input [DATA_WIDTH-1:0] din,
    output full,

    // Read Interface (Pop)
    input rd_en,
    output reg [DATA_WIDTH-1:0] dout,
    output empty,

    // Status
    output reg [PTR_WIDTH:0] count
);

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Pointers
    reg [PTR_WIDTH-1:0] wr_ptr;
    reg [PTR_WIDTH-1:0] rd_ptr;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    // Write Logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr      <= wr_ptr + 1'b1;
        end
    end

    // Read Logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rd_ptr <= 0;
            dout   <= 0;
        end else if (rd_en && !empty) begin
            dout   <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // Counter Tracking Logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
        end else begin
            case ({ (wr_en && !full), (rd_en && !empty) })
                2'b10:  count <= count + 1'b1; // Push only
                2'b01:  count <= count - 1'b1; // Pop only
                default: count <= count;       // No-op or simultaneous push/pop
            endcase
        end
    end

endmodule
