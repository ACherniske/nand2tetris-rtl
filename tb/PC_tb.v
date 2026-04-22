`timescale 1ns / 1ps

module PC_tb;

    reg clk, reset, load, inc;
    reg [15:0] in;
    wire [15:0] out;

    // Use a reg to track expected value internally
    reg [15:0] expected_out;
    reg error_found = 0;

    PC uut (.clk(clk), .reset(reset), .load(load), .inc(inc), .in(in), .out(out));

    always #5 clk = ~clk;

    // The Golden Model Logic: Lives here, not in the initial block
    always @(posedge clk) begin
        if (reset) 
            expected_out <= 16'd0;
        else if (load) 
            expected_out <= in;
        else if (inc) 
            expected_out <= expected_out + 16'd1;
    end

    initial begin
        $dumpfile("test.vcd"); 
        $dumpvars(0, PC_tb);
        
        // Initialize all signals
        clk = 0; 
        reset = 0; 
        load = 0; 
        inc = 0; 
        in = 16'd0;
        
        // Explicitly initialize expected_out to match PC's initial value
        expected_out = 16'd0;
        
        $display("Starting PC Verification...");
        repeat(2) @(posedge clk);

        // Test sequence: define inputs on negedge
        @(negedge clk) inc = 1; 
        repeat(3) @(negedge clk); // Let it count for 3 cycles
        
        @(negedge clk) begin inc = 0; load = 1; in = 16'hAAAA; end
        @(negedge clk) begin load = 0; inc = 1; end
        @(negedge clk) reset = 1;
        @(negedge clk) begin reset = 0; inc = 0; end
        @(negedge clk) inc = 1;
        repeat(3) @(negedge clk);

        #20;
        if (!error_found) begin
            $display("PC Verification Complete. No errors found.");
        end else begin
            $display("PC Verification FAILED.");
        end
        $finish;
    end

    // Assertion block with verbose output
    always @(posedge clk) begin
        #1; // Sample after clock edge settles
        
        `ifdef VERBOSE
            $display("Time=%0t | Reset=%b | Load=%b | Inc=%b | In=%h | Out=%h | Expected=%h",
                     $time, reset, load, inc, in, out, expected_out);
        `endif
        
        if (out !== expected_out) begin
            $display("FAIL at time %0t: Expected %h, Got %h", $time, expected_out, out);
            error_found = 1; 
            $finish;
        end
    end
    
endmodule
