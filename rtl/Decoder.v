`timescale 1ns / 1ps

module Decoder (
    input wire [15:0] instruction,
    input wire zr,          // From ALU
    input wire ng,          // From ALU
    output wire is_c_instr, // True if C-instruction
    output wire [5:0] alu_ctrl, // zx, nx, zy, ny, f, no
    output wire load_a,     // Load A-register
    output wire load_d,     // Load D-register
    output wire write_m,    // Write to Memory (M)
    output wire jump        // Trigger PC load
);

    // Decode instruction type
    assign is_c_instr = instruction[15];

    // C-instruction field mapping
    // bits 12:7 are ALU control (a, c1, c2, c3, c4, c5, c6)
    assign alu_ctrl = instruction[11:6];
    
    // Dest bits (bits 5:3)
    assign load_a = ~is_c_instr | instruction[5];
    assign load_d = is_c_instr & instruction[4];
    assign write_m = is_c_instr & instruction[3];

    // Jump logic (bits 2:0)
    // Only jump if C-instruction and conditions met
    wire zr_cond = instruction[1] & zr;
    wire ng_cond = instruction[2] & ng;
    wire pos_cond = instruction[0] & ~(zr | ng);
    assign jump = is_c_instr & (zr_cond | ng_cond | pos_cond);

endmodule
