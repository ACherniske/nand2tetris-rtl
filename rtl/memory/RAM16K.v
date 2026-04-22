`timescale 1ns / 1ps

module RAM16K (
    input wire clk,
    input wire writeM,            // Write enable
    input wire [13:0] address,    // 14-bit address (0 to 16383)
    input wire [15:0] in,         // Data to write
    output reg [15:0] out         // Data output
);

    // 1. Declare the memory array (16,384 words of 16-bit each)
    reg [15:0] ram [0:16383];

    // 2. Synchronous Write logic
    always @(posedge clk) begin
        if (writeM) begin
            ram[address] <= in;
        end
    end

    // 3. Asynchronous Read logic (output changes as address changes)
    always @(*) begin
        out = ram[address];
    end

endmodule
