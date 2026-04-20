module CPU(
    input  clk, reset,
    input  [15:0] inM, instruct,
    output [15:0] outM,
    output writeM,
    output [14:0] addressM, pc_out
);
    // TODO 1: Instruction Decoder: 
    //         Split 'instruct' into opcode, A/M select, ALU control bits, 
    //         dest bits (A, D, M), and jump bits.

    // TODO 2: A-Register Mux:
    //         Select between 'instruct' (A-instr) and 'ALU_out' (C-instr).

    // TODO 3: ALU Input Mux:
    //         Select between A-register and 'inM' based on the 'a' bit.

    // TODO 4: D-Register & A-Register Control:
    //         Enable load signal only if corresponding dest bit is set 
    //         AND instruction is a C-instruction.

    // TODO 5: Jump Logic:
    //         Check ALU flags (zr, ng) against j1, j2, j3 bits.
    //         Enable PC load if jump condition met.

    // TODO 6: Assign outputs: 
    //         outM = ALU_out, addressM = A_reg[14:0], writeM = d3 & isC
endmodule
