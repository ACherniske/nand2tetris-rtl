`timescale 1ns / 1ps

module Computer_tb;
    reg clk, reset;
    
    Computer uut (.clk(clk), .reset(reset));

    always #5 clk = ~clk; // 100MHz clock

    initial begin
        $dumpfile("computer_test.vcd");
        $dumpvars(0, Computer_tb);

        clk = 0;
        reset = 1;
        #20 reset = 0; // Release reset

        // Run for enough cycles to complete the Add program (~10 cycles)
        #100;
        
        $display("Final result in RAM[0]: %d", uut.ram.ram[0]);
        
        $finish;
    end
endmodule
