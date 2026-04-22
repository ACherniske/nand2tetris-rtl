`timescale 1ns / 1ps

module ROM32K (
    input wire clk,
    // CPU Instruction Fetch Port (Read-Only)
    input  wire [14:0] cpu_address,
    output reg  [15:0] cpu_instruction,
    
    // Loader Write Port (Write-Only during programming)
    input  wire [14:0] load_address,
    input  wire [15:0] load_data,
    input  wire        load_we
);

    // Declare the memory array (32768 words of 16-bit each)
    reg [15:0] rom [0:32767];

    // Initialize to zeros (or load a default program if desired)
    integer i;
    initial begin
        for (i = 0; i < 32768; i = i + 1) begin
            rom[i] = 16'h0000;
        end
    end

    // Dual-port access
    always @(posedge clk) begin
        // CPU read port (always active)
        cpu_instruction <= rom[cpu_address];
        
        // Loader write port (only during load mode)
        if (load_we) begin
            rom[load_address] <= load_data;
        end
    end

endmodule
