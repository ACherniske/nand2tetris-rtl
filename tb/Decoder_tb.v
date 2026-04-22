`timescale 1ns / 1ps

module Decoder_tb;

    reg [15:0] instruction;
    reg zr, ng;
    wire is_c_instr, load_a, load_d, write_m, jump;
    wire [5:0] alu_ctrl;
    reg error_found = 0;

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

        // ===== A-INSTRUCTION TESTS =====
        $display("\n=== Testing A-Instructions ===");
        
        // Test 1: A-Instruction @1
        instruction = 16'b0000000000000001;
        zr = 0; ng = 0;
        #10;
        if (is_c_instr !== 0 || load_a !== 1 || load_d !== 0 || write_m !== 0 || jump !== 0) begin
            $display("FAIL: A-Instruction @1 decode error");
            $display("  Expected: is_c=0 load_a=1 load_d=0 write_m=0 jump=0");
            $display("  Got:      is_c=%b load_a=%b load_d=%b write_m=%b jump=%b", 
                     is_c_instr, load_a, load_d, write_m, jump);
            error_found = 1;
        end else begin
            $display("PASS: A-Instruction @1");
        end

        // Test 2: A-Instruction @32767 (max positive)
        instruction = 16'b0111111111111111;
        #10;
        if (is_c_instr !== 0 || load_a !== 1) begin
            $display("FAIL: A-Instruction @32767 decode error");
            error_found = 1;
        end else begin
            $display("PASS: A-Instruction @32767");
        end

        // ===== C-INSTRUCTION DECODE TESTS =====
        $display("\n=== Testing C-Instruction Decode ===");
        
        // Test 3: D=A (111 0 110000 010 000)
        instruction = 16'b1110110000010000;
        #10;
        if (is_c_instr !== 1 || load_d !== 1 || load_a !== 0 || write_m !== 0 || 
            alu_ctrl !== 6'b110000 || jump !== 0) begin
            $display("FAIL: D=A decode error");
            $display("  Expected: is_c=1 alu_ctrl=110000 load_a=0 load_d=1 write_m=0 jump=0");
            $display("  Got:      is_c=%b alu_ctrl=%b load_a=%b load_d=%b write_m=%b jump=%b",
                     is_c_instr, alu_ctrl, load_a, load_d, write_m, jump);
            error_found = 1;
        end else begin
            $display("PASS: D=A");
        end

        // Test 4: M=D+1 (111 0 011111 001 000)
        instruction = 16'b1110011111001000;
        #10;
        if (is_c_instr !== 1 || write_m !== 1 || load_d !== 0 || load_a !== 0 || 
            alu_ctrl !== 6'b011111 || jump !== 0) begin
            $display("FAIL: M=D+1 decode error");
            error_found = 1;
        end else begin
            $display("PASS: M=D+1");
        end

        // Test 5: AMD=D-A (111 0 010011 111 000)
        instruction = 16'b1110010011111000;
        #10;
        if (is_c_instr !== 1 || load_a !== 1 || load_d !== 1 || write_m !== 1 || 
            alu_ctrl !== 6'b010011 || jump !== 0) begin
            $display("FAIL: AMD=D-A decode error");
            $display("  Expected: load_a=1 load_d=1 write_m=1");
            $display("  Got:      load_a=%b load_d=%b write_m=%b", load_a, load_d, write_m);
            error_found = 1;
        end else begin
            $display("PASS: AMD=D-A");
        end

        // ===== JUMP CONDITION TESTS =====
        $display("\n=== Testing Jump Conditions ===");
        
        // Test 6: JGT (jump if > 0) - should jump when zr=0, ng=0
        instruction = 16'b1110000000000001; // JGT (j2j1j0 = 001)
        zr = 0; ng = 0;
        #10;
        if (jump !== 1) begin
            $display("FAIL: JGT (positive) should jump");
            error_found = 1;
        end else begin
            $display("PASS: JGT with positive value");
        end

        // Test 7: JGT - should NOT jump when zr=1
        zr = 1; ng = 0;
        #10;
        if (jump !== 0) begin
            $display("FAIL: JGT should not jump when zero");
            error_found = 1;
        end else begin
            $display("PASS: JGT with zero (no jump)");
        end

        // Test 8: JEQ (jump if = 0) - should jump when zr=1
        instruction = 16'b1110000000000010; // JEQ (j2j1j0 = 010)
        zr = 1; ng = 0;
        #10;
        if (jump !== 1) begin
            $display("FAIL: JEQ should jump when zero");
            error_found = 1;
        end else begin
            $display("PASS: JEQ with zero");
        end

        // Test 9: JGE (jump if >= 0) - should jump when zr=0, ng=0
        instruction = 16'b1110000000000011; // JGE (j2j1j0 = 011)
        zr = 0; ng = 0;
        #10;
        if (jump !== 1) begin
            $display("FAIL: JGE should jump when positive");
            error_found = 1;
        end else begin
            $display("PASS: JGE with positive");
        end

        // Test 10: JGE - should jump when zr=1, ng=0
        zr = 1; ng = 0;
        #10;
        if (jump !== 1) begin
            $display("FAIL: JGE should jump when zero");
            error_found = 1;
        end else begin
            $display("PASS: JGE with zero");
        end

        // Test 11: JLT (jump if < 0) - should jump when ng=1
        instruction = 16'b1110000000000100; // JLT (j2j1j0 = 100)
        zr = 0; ng = 1;
        #10;
        if (jump !== 1) begin
            $display("FAIL: JLT should jump when negative");
            error_found = 1;
        end else begin
            $display("PASS: JLT with negative");
        end

        // Test 12: JNE (jump if != 0) - should jump when zr=0, ng=0 (positive)
        instruction = 16'b1110000000000101; // JNE (j2j1j0 = 101)
        zr = 0; ng = 0;
        #10;
        if (jump !== 1) begin
            $display("FAIL: JNE should jump when positive");
            error_found = 1;
        end else begin
            $display("PASS: JNE with positive");
        end

        // Test 13: JNE - should jump when ng=1 (negative)
        zr = 0; ng = 1;
        #10;
        if (jump !== 1) begin
            $display("FAIL: JNE should jump when negative");
            error_found = 1;
        end else begin
            $display("PASS: JNE with negative");
        end

        // Test 14: JNE - should NOT jump when zr=1
        zr = 1; ng = 0;
        #10;
        if (jump !== 0) begin
            $display("FAIL: JNE should not jump when zero");
            error_found = 1;
        end else begin
            $display("PASS: JNE with zero (no jump)");
        end

        // Test 15: JLE (jump if <= 0) - should jump when ng=1
        instruction = 16'b1110000000000110; // JLE (j2j1j0 = 110)
        zr = 0; ng = 1;
        #10;
        if (jump !== 1) begin
            $display("FAIL: JLE should jump when negative");
            error_found = 1;
        end else begin
            $display("PASS: JLE with negative");
        end

        // Test 16: JLE - should jump when zr=1
        zr = 1; ng = 0;
        #10;
        if (jump !== 1) begin
            $display("FAIL: JLE should jump when zero");
            error_found = 1;
        end else begin
            $display("PASS: JLE with zero");
        end

        // Test 17: JMP (unconditional jump)
        instruction = 16'b1110000000000111; // JMP (j2j1j0 = 111)
        zr = 0; ng = 0;
        #10;
        if (jump !== 1) begin
            $display("FAIL: JMP should always jump");
            error_found = 1;
        end else begin
            $display("PASS: JMP unconditional");
        end

        // Test 18: No jump instruction (j2j1j0 = 000)
        instruction = 16'b1110000000000000;
        zr = 0; ng = 0;
        #10;
        if (jump !== 0) begin
            $display("FAIL: No jump bits set should not jump");
            error_found = 1;
        end else begin
            $display("PASS: No jump condition");
        end

        // Final report
        #10;
        if (!error_found) begin
            $display("\n=== Decoder Verification Complete. No errors found. ===");
        end else begin
            $display("\n=== Decoder Verification FAILED ===");
        end
        $finish;
    end

endmodule
