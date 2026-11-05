`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 04/02/2026 10:39:37 PM
// Design Name:
// Module Name: dma_controller
// Project Name: DMA Controller
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

module dma_controller(
    input clk,
    input reset,
    input start,
    input peripheral_ready,
    input [7:0] burst_size,
    input [31:0] src_addr,
    input [31:0] dest_addr,
    input [31:0] data_in,
    output[31:0] data_out,
    output reg dma_valid,
    output reg done
    );

    // FIFO Control Signals
    reg  fifo_wr_en;
    reg  fifo_rd_en;
    wire fifo_full;
    wire fifo_empty;
    wire [4:0] fifo_count;

    // Instantiate Internal FIFO
    fifo_buffer #(
        .DATA_WIDTH(32),
        .DEPTH(16),
        .PTR_WIDTH(4)
    ) internal_fifo (
        .clk(clk),
        .reset(reset),
        .wr_en(fifo_wr_en),
        .din(data_in),
        .full(fifo_full),
        .rd_en(fifo_rd_en),
        .dout(data_out),
        .empty(fifo_empty),
        .count(fifo_count)
    );


// State Machine Registers & Counters
    reg [7:0] read_count;
    reg [7:0] write_count;
// 1. Internal Constants (State Definitions)
    localparam IDLE = 2'b00;
    localparam RUN = 2'b01;
    localparam DONE = 2'b10;

// 2. Internal Registers (Flip- Flops)

    reg[1:0] state;


    // Beginning of Logic
    // Main Control FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state       <= IDLE;
            read_count  <= 8'd0;
            write_count <= 8'd0;
            done        <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        read_count  <= 8'd0;
                        write_count <= 8'd0;
                        state       <= RUN;
                    end
                end

                RUN: begin
                    // Increment Read Counter when pushing into FIFO
                    if (fifo_wr_en) begin
                        read_count <= read_count + 1'b1;
                    end

                    // Increment Write Counter when popping from FIFO
                    if (fifo_rd_en) begin
                        write_count <= write_count + 1'b1;
                    end

                    // Completion Check: All requested words popped from FIFO
                    if (write_count == burst_size - 1'b1 && fifo_rd_en) begin
                        state <= DONE;
                    end
                end

                DONE: begin
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    // -------------------------------------------------------------
    // FIFO Interface Control Logic (Combinational)
    // -------------------------------------------------------------
    always @(*) begin
        // Push logic: Active during RUN if FIFO isn't full and we haven't read all burst words
        fifo_wr_en = (state == RUN) && (!fifo_full) && (read_count < burst_size);

        // Pop logic: Active during RUN if FIFO isn't empty and destination is ready
        fifo_rd_en = (state == RUN) && (!fifo_empty) && peripheral_ready;

        // Valid signal driven whenever data is available to be popped
        dma_valid  = (!fifo_empty);
    end

endmodule
