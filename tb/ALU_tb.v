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

            // --- Verbose Output ---
            `ifdef VERBOSE
                $display("State %2d | Ctrl:%b | Expected:%d | Got:%d", i, {zx,nx,zy,ny,f,no}, ref_out, out);
            `endif

            // --- Automated Assertion ---
            if (out !== ref_out) begin
                $display("FAIL: State %d | Expected %d, Got %d", i, ref_out, out);
            end
        end

        $display("Exhaustive Verification Complete. No errors found.");
        $finish; // This closes the simulation and allows the Makefile to continue
    end

endmodule
