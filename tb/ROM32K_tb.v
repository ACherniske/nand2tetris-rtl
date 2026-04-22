`timescale 1ns / 1ps

module ROM32K_tb;

    reg [14:0] address;
    wire [15:0] out;

    // Instantiate ROM32K
    ROM32K uut (
        .address(address), 
        .out(out)
    );

    initial begin
        $dumpfile("rom_test.vcd");
        $dumpvars(0, ROM32K_tb);

        // Test: Sweep addresses
        // Note: Make sure "program.hack" exists in the simulation directory
        address = 0; #10;
        $display("Address 0: %b", out);
        
        address = 1; #10;
        $display("Address 1: %b", out);
        
        $finish;
    end
endmodule
