`timescale 1ns / 1ps

module RAM16K_tb;

    reg clk;
    reg writeM;
    reg [13:0] address;
    reg [15:0] in;
    wire [15:0] out;

    // Instantiate RAM16K
    RAM16K uut (
        .clk(clk), 
        .writeM(writeM), 
        .address(address), 
        .in(in), 
        .out(out)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("ram_test.vcd");
        $dumpvars(0, RAM16K_tb);

        clk = 0;
        writeM = 0;
        address = 0;
        in = 0;

        // Test 1: Write and Read
        #10 address = 14'd100; in = 16'hABCD; writeM = 1;
        #10 writeM = 0;
        #10 if (out === 16'hABCD) $display("PASS: Read back correct value 0xABCD");
            else $display("FAIL: Expected 0xABCD, got %h", out);

        // Test 2: Write different value, verify no conflict
        #10 address = 14'd200; in = 16'h1234; writeM = 1;
        #10 writeM = 0;
        #10 address = 14'd100;
        #10 if (out === 16'hABCD) $display("PASS: Address 100 still holds 0xABCD");
        
        $finish;
    end
endmodule