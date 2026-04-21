`timescale 1ns / 1ps

module ALU_tb;

    // Inputs
    reg [15:0] x, y;
    reg zx, nx, zy, ny, f, no;

    // Outputs
    wire [15:0] out;
    wire zr, ng;

    // Instantiate the Unit Under Test (UUT)
    ALU uut (
        .x(x), 
        .y(y),
        .zx(zx), 
        .nx(nx),
        .zy(zy), 
        .ny(ny),
        .f(f),
        .no(no),
        .out(out),
        .zr(zr),
        .ng(ng)
    );

    // GTKWave signal dump
    initial begin
        $dumpfile("ALU.vcd");
        $dumpvars(0, ALU_tb);
    end

    // Test sequence
    initial begin
        $display("Starting ALU Test...");

        // Define a simple test format: {zx, nx, zy, ny, f, no}
        // Test 1: Zero (zx=1, nx=0, zy=1, ny=0, f=1, no=0) -> 0 + 0 = 0
        {x, y, zx, nx, zy, ny, f, no} = {16'd10, 16'd20, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0};
        #10;
        
        // Test 2: Add 1 (zx=1, nx=1, zy=1, ny=1, f=1, no=1) -> -(0+0) + 1 = 1
        {x, y, zx, nx, zy, ny, f, no} = {16'd10, 16'd20, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1};
        #10;

        // Test 3: Bitwise AND (f=0, all others 0) -> 10 & 20
        {x, y, zx, nx, zy, ny, f, no} = {16'd10, 16'd20, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
        #10;

        // Test 4: Negate X (zx=0, nx=1, zy=1, ny=0, f=0, no=0) -> (~10) & 0 = 0
        {x, y, zx, nx, zy, ny, f, no} = {16'd10, 16'd20, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0};
        #10;
        
        // Test 5: Negative result check (e.g., -1)
        // Set to -1 (1111...1111)
        {x, y, zx, nx, zy, ny, f, no} = {16'd0, 16'd0, 1'b1, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0};
        #10;

        $display("Test Finished.");
        $finish;
    end

endmodule
