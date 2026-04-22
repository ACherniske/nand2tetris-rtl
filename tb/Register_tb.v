`timescale 1ns / 1ps

module Register_tb;

    reg clk;
    reg load;
    reg [15:0] in;
    wire [15:0] out;
    reg [15:0] expected_out;
    reg error_found = 0;

    Register uut (
        .clk(clk),
        .load(load),
        .in(in),
        .out(out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, Register_tb);

        clk = 0; load = 0; in = 16'd0; expected_out = 16'd0;
        $display("Starting Register Verification...");

        repeat(5) @(posedge clk); 

        // Test 1: Load ABCD
        @(negedge clk) begin 
            in = 16'hABCD; 
            load = 1;
            expected_out = 16'hABCD; // Update expected BEFORE next posedge
        end
        
        // Test 2: Try to load 1234 but load=0, should retain ABCD
        @(negedge clk) begin 
            in = 16'h1234; 
            load = 0; 
            expected_out = 16'hABCD; // Should still be ABCD
        end
        
        // Test 3: Now load 1234 with load=1
        @(negedge clk) begin 
            load = 1;
            expected_out = 16'h1234; // Now expect 1234
        end
        
        // Test 4: Disable load again
        @(negedge clk) begin
            load = 0;
            in = 16'hFFFF;
            expected_out = 16'h1234; // Should still be 1234
        end
        
        #20; 

        // Final Report
        if (error_found == 0) begin
            $display("Register Verification Complete. No errors found.");
        end else begin
            $display("Register Verification FAILED.");
        end
        $finish;
    end

    // --- Verbose Monitor & Assertion ---
    always @(posedge clk) begin
        #1; // Sample output after clock edge
        `ifdef VERBOSE
            $display("Time=%0t | Load=%b | In=%h | Out=%h | Expected=%h", 
                      $time, load, in, out, expected_out);
        `endif

        if (out !== expected_out) begin
            $display("FAIL: Expected %h, Got %h", expected_out, out);
            error_found = 1;
            $finish;
        end
    end

endmodule
