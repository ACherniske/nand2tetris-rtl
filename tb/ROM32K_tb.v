`timescale 1ns / 1ps

module ROM32K_tb;

    // Inputs
    reg clk;
    reg [14:0] cpu_address;
    reg [14:0] load_address;
    reg [15:0] load_data;
    reg load_we;

    // Outputs
    wire [15:0] cpu_instruction;

    // Instantiate the Unit Under Test (UUT)
    ROM32K uut (
        .clk(clk),
        .cpu_address(cpu_address),
        .cpu_instruction(cpu_instruction),
        .load_address(load_address),
        .load_data(load_data),
        .load_we(load_we)
    );

    // Clock generation (12MHz)
    always #41.67 clk = ~clk; 

    initial begin
        // Setup monitoring
        $dumpfile("rom_test.vcd");
        $dumpvars(0, ROM32K_tb);

        // Initialize signals
        clk = 0;
        cpu_address = 0;
        load_address = 0;
        load_data = 0;
        load_we = 0;

        #100;

        // --- TEST 1: Write to ROM via Loader Port ---
        $display("Writing 0xABCD to address 5...");
        load_address = 15'd5;
        load_data = 16'hABCD;
        load_we = 1;
        
        #83.34; // Wait one clock cycle
        load_we = 0;
        
        // --- TEST 2: Read from ROM via CPU Port ---
        #10;
        $display("Reading from address 5...");
        cpu_address = 15'd5;
        
        #83.34; // Wait for synchronous read
        $display("Value at address 5: %h (Expected: abcd)", cpu_instruction);

        #100;
        $finish;
    end
endmodule
