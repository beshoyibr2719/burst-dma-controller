`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05/12/2026 11:18:51 PM
// Design Name:
// Module Name: dma_controller_tb
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
module dma_controller_tb();

// 1. Signals we need to drive to the DMA

    reg clk;
    reg reset;
    reg start;
    reg[31:0] src_addr;
    reg[31:0] dest_addr;
    reg[31:0] data_in;
    reg peripheral_ready;
    reg[7:0] burst_size;

// 2. Wires we want to watch the DMA/ Outputs

    wire [31:0] data_out;
    wire done;
    wire dma_valid;

// 3. Instantiate the Unit Under Test (UUT)
    dma_controller uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .src_addr(src_addr),
        .dest_addr(dest_addr),
        .burst_size(burst_size),
        .data_in(data_in),
        .data_out(data_out),
        .peripheral_ready(peripheral_ready),
        .dma_valid(dma_valid),
        .done(done)
    );

// 4. Clock Generation (100 MHz -> 10ns period)
    always #5 clk = ~clk;

// 5. Data Generator: Feed incrementing dummy data whenever FIFO accepts reads
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_in <= 32'h1111_1111;
        end else if (uut.fifo_wr_en) begin
            data_in <= data_in + 32'h1111_1111; // 11111111, 22222222, 33333333...
        end
    end

// 6. Stimulus Block (The Test Script)
    initial begin
        // Initialize inputs
        clk = 0;
        reset = 1;
        start = 0;
        peripheral_ready = 0; // Keep peripheral ready so we can watch smooth continuous bursts
        burst_size = 8'd6; // Request a burst of 6 words
        src_addr = 32'h1000_0000;
        dest_addr = 32'h2000_0000;

        // Hold reset for 20ns
        #20;
        reset = 0;
        #10;

        // --- Phase 1: Trigger DMA Start ---
        start = 1;
        #10;
        start = 0;

        // --- Phase 2: Simulate Peripheral Stall ---
        // Notice peripheral_ready is STILL 0 here!
        // Watch the FIFO fill up while destination is unready.
        #40;

        // --- Phase 3: Destination becomes ready ---
        peripheral_ready = 1;
        #30;

        // --- Phase 4: Inject a Mid-Burst Stall ---
        // Peripheral suddenly gets busy for 2 clock cycles
        peripheral_ready = 0;
        #20;
        peripheral_ready = 1;

        // Wait for transfer completion
        wait(done);
        #30;

        $display("SUCCESS: FIFO DMA Burst Transfer Completed!");
        $finish;
    end

endmodule
