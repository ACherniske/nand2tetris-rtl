`timescale 1ns / 1ps

module Decoder_tb;

    reg [15:0] instruction;
    reg zr, ng;
    wire is_c_instr, load_a, load_d, write_m, jump;
    wire [5:0] alu_ctrl;

    // Instantiate UUT
    Decoder uut (
        .instruction(instruction), .zr(zr), .ng(ng),
        .is_c_instr(is_c_instr), .alu_ctrl(alu_ctrl),
        .load_a(load_a), .load_d(load_d), .write_m(write_m), .jump(jump)
    );

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, Decoder_tb);
        
        $display("Starting Decoder Verification...");

        // 1. Test A-Instruction (0vvv...)
        instruction = 16'b0000000000000001; // Constant 1
        #10;
        if (is_c_instr !== 0 || load_a !== 1) $display("FAIL: A-Instruction decode error");

        // 2. Test C-Instruction (111a cccc ccdd djjj)
        // Set Dest=D (010), ALU=111111 (0x3F), Jump=000
        instruction = 16'b1110111111010000; 
        #10;
        if (is_c_instr !== 1 || load_d !== 1 || alu_ctrl !== 6'b111111) 
            $display("FAIL: C-Instruction decode error");

        // 3. Test Jump Logic
        // Instruction: JGT (Jump if > 0), ALU output: zr=0, ng=0
        instruction = 16'b1110000000000001;
        zr = 0; ng = 0;
        #10;
        if (jump !== 1) $display("FAIL: JGT jump error");

        // 4. Test No-Jump
        // Instruction: JGT, ALU output: zr=1, ng=0
        zr = 1; ng = 0;
        #10;
        if (jump !== 0) $display("FAIL: False jump error");

        $display("Decoder Verification Complete. No errors found.");
        $finish;
    end

endmodule
