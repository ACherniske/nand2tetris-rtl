`timescale 1ns / 1ps

module PC_tb;

    reg clk, reset, load, inc;
    reg [15:0] in;
    wire [15:0] out;

    // Golden Model reference
    reg [15:0] expected_out;
    reg error_found = 0;

    PC uut (
        .clk(clk), .reset(reset), .load(load), .inc(inc), .in(in), .out(out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, PC_tb);

        clk = 0; reset = 0; load = 0; inc = 0; in = 16'd0;
        expected_out = 16'd0;

        $display("Starting PC Verification...");
        repeat(2) @(posedge clk);

        // 1. Test Increment
        @(negedge clk) begin inc = 1; expected_out = expected_out + 1; end
        @(negedge clk) begin inc = 1; expected_out = expected_out + 1; end
        
        // 2. Test Load (Overriding Inc)
        @(negedge clk) begin inc = 0; load = 1; in = 16'hAAAA; expected_out = 16'hAAAA; end
        
        // 3. Test Increment again
        @(negedge clk) begin load = 0; inc = 1; expected_out = expected_out + 1; end
        
        // 4. Test Reset (Highest Priority)
        @(negedge clk) begin reset = 1; expected_out = 16'd0; end
        
        // 5. Release Reset
        @(negedge clk) begin reset = 0; inc = 1; expected_out = expected_out + 1; end

        #20;
        if (error_found == 0) $display("PC Verification Complete. No errors found.");
        else $display("PC Verification FAILED.");
        $finish;
    end

    always @(posedge clk) begin
        #1;
        `ifdef VERBOSE
            $display("Time=%0t | Reset=%b Load=%b Inc=%b | In=%h | Out=%h | Expected=%h", 
                      $time, reset, load, inc, in, out, expected_out);
        `endif

        if (out !== expected_out) begin
            $display("FAIL: Expected %h, Got %h", expected_out, out);
            error_found = 1;
            $finish;
        end
    end

endmodule
