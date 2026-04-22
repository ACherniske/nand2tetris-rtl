`timescale 1ns / 1ps

module ROM32K (
    input  wire [14:0] address, // 15-bit address for 32K memory
    output wire [15:0] out      // 16-bit instruction output
);

    // Declare the memory array (32768 words of 16-bit each)
    reg [15:0] rom [0:32767];

    // Load the binary file into the array at simulation start
    // The file "program.hack" must be in your project folder
    initial begin
        $readmemb("program.hack", rom);
    end

    // Continuous read (ROM is always active)
    assign out = rom[address];

endmodule