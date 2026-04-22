`timescale 1ns / 1ps

module ALU_tb;

    // Inputs
    reg [15:0] x, y;
    reg zx, nx, zy, ny, f, no;
    integer i; // Use integer to avoid register overflow/infinite loop

    // Outputs
    wire [15:0] out;
    wire zr, ng;

    // Golden Model internal registers
    reg [15:0] x_ref, y_ref, ref_out;
    reg ref_zr, ref_ng;
    
    // Error tracking
    reg error_found = 0;

    // Instantiate the Unit Under Test (UUT)
    ALU uut (
        .x(x), .y(y),
        .zx(zx), .nx(nx),
        .zy(zy), .ny(ny),
        .f(f),
        .no(no),
        .out(out),
        .zr(zr),
        .ng(ng)
    );

    // GTKWave signal dump
    initial begin
        // We use a constant filename here
        $dumpfile("test.vcd"); 
        $dumpvars(0, ALU_tb);
    end

    // Test sequence
    initial begin
        $display("Starting Exhaustive ALU Verification...");
        
        // Define static test values
        x = 16'd1234;
        y = 16'd5678;

        // Loop through all 64 control states
        for (i = 0; i < 64; i = i + 1) begin
            {zx, nx, zy, ny, f, no} = i[5:0]; // Slice the 6 bits
            #10;
            
            // --- Golden Model Calculation ---
            x_ref = zx ? 16'b0 : x;
            if (nx) x_ref = ~x_ref;
            y_ref = zy ? 16'b0 : y;
            if (ny) y_ref = ~y_ref;
            
            ref_out = f ? (x_ref + y_ref) : (x_ref & y_ref);
            if (no) ref_out = ~ref_out;
            
            // Calculate expected flags
            ref_zr = (ref_out == 16'b0) ? 1 : 0;
            ref_ng = ref_out[15];

            // --- Verbose Output ---
            `ifdef VERBOSE
                $display("State %2d | Ctrl:%b | Expected:%d | Got:%d | ZR:%b/%b | NG:%b/%b", 
                         i, {zx,nx,zy,ny,f,no}, ref_out, out, ref_zr, zr, ref_ng, ng);
            `endif

            // --- Automated Assertion ---
            if (out !== ref_out) begin
                $display("FAIL: State %d | Output mismatch | Expected %h, Got %h", i, ref_out, out);
                error_found = 1;
                $finish;
            end
            
            if (zr !== ref_zr) begin
                $display("FAIL: State %d | ZR flag mismatch | Expected %b, Got %b", i, ref_zr, zr);
                error_found = 1;
                $finish;
            end
            
            if (ng !== ref_ng) begin
                $display("FAIL: State %d | NG flag mismatch | Expected %b, Got %b", i, ref_ng, ng);
                error_found = 1;
                $finish;
            end
        end

        if (!error_found) begin
            $display("Exhaustive Verification Complete. No errors found.");
        end else begin
            $display("ALU Verification FAILED.");
        end
        $finish; // This closes the simulation and allows the Makefile to continue
    end

endmodule
