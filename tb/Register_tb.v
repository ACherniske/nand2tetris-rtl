`timescale 1ns / 1ps

module Register_tb;

    reg clk;
    reg load;
    reg [15:0] in;
    wire [15:0] out;

    Register uut (
        .clk(clk),
        .load(load),
        .in(in),
        .out(out)
    );

    // Clock generator (10ns period)
    always #5 clk = ~clk;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, Register_tb);

        clk = 0;
        load = 0;
        in = 16'd0;

        // Test 1: Load a value
        #10 in = 16'hABCD; load = 1;
        #10 load = 0; // Disable load
        
        // Test 2: Attempt to change input while load is low
        #10 in = 16'h1234; 
        
        // Test 3: Assert load again
        #10 load = 1;
        #10 load = 0;

        $display("Register Test Finished.");
        $finish;
    end

endmodule
