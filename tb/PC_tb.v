`timescale 1ns / 1ps

module PC_tb;

    reg clk, reset, load, inc;
    reg [15:0] in;
    wire [15:0] out;

    // Use a reg to track expected value internally
    reg [15:0] expected_out = 0;
    reg error_found = 0;

    PC uut (.clk(clk), .reset(reset), .load(load), .inc(inc), .in(in), .out(out));

    always #5 clk = ~clk;

    // The Golden Model Logic: Lives here, not in the initial block
    always @(posedge clk) begin
        if (reset) expected_out <= 0;
        else if (load) expected_out <= in;
        else if (inc) expected_out <= expected_out + 1;
    end

    initial begin
        $dumpfile("test.vcd"); $dumpvars(0, PC_tb);
        clk = 0; reset = 0; load = 0; inc = 0; in = 0;
        
        $display("Starting PC Verification...");
        repeat(2) @(posedge clk);

        // Just define the inputs; the 'always' block above handles the 'expected_out'
        @(negedge clk) inc = 1; 
        repeat(3) @(negedge clk); // Let it count for 3 cycles
        
        @(negedge clk) begin inc = 0; load = 1; in = 16'hAAAA; end
        @(negedge clk) begin load = 0; inc = 1; end
        @(negedge clk) reset = 1;
        @(negedge clk) begin reset = 0; inc = 0; end
        @(negedge clk) inc = 1;
        repeat(3) @(negedge clk);

        #20;
        if (!error_found) $display("PC Verification Complete. No errors found.");
        $finish;
    end

    always @(posedge clk) begin
        #1;
        if (out !== expected_out) begin
            $display("FAIL: Expected %h, Got %h", expected_out, out);
            error_found = 1; $finish;
        end
    end
endmodule
