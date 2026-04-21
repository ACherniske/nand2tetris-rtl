// Boilerplate template for /tb/Module_tb.v
`timescale 1ns / 1ps

module Module_tb;
    // 1. Define signals (reg for inputs, wire for outputs)
    // 2. Instantiate Unit Under Test (UUT)
    // 3. Logic to drive inputs
    
    initial begin
        // ALWAYS use the filename as the VCD name
        $dumpfile("test.vcd"); 
        $dumpvars(0, Module_tb);
    end
endmodule