`timescale 1ns / 1ps

module CPU (
    input wire clk,
    input wire reset,
    input wire [15:0] instruction,
    input wire [15:0] inM,
    output wire [15:0] outM,
    output wire writeM,
    output wire [15:0] addressM,
    output wire [15:0] pc
);

    // Internal wires for connections
    wire is_c;
    wire [5:0] alu_ctrl;
    wire load_a, load_d, jump;
    wire zr, ng;
    wire [15:0] a_reg_out, d_reg_out, alu_out, alu_y_in;

    // Decoder (Control Unit)
    Decoder decoder (
        .instruction(instruction), .zr(zr), .ng(ng),
        .is_c_instr(is_c), .alu_ctrl(alu_ctrl),
        .load_a(load_a), .load_d(load_d), .write_m(writeM), .jump(jump)
    );

    // A-Register (Can be loaded by A-instruction or ALU result)
    wire [15:0] a_mux_out = is_c ? alu_out : instruction;
    Register a_reg (.clk(clk), .load(load_a), .in(a_mux_out), .out(a_reg_out));

    // D-Register
    Register d_reg (.clk(clk), .load(load_d), .in(alu_out), .out(d_reg_out));

    // ALU Input MUX (Selects between A-reg or Memory M)
    assign alu_y_in = (is_c & instruction[12]) ? inM : a_reg_out;

    // ALU
    ALU alu (
        .x(d_reg_out), .y(alu_y_in),
        .zx(alu_ctrl[5]), .nx(alu_ctrl[4]), .zy(alu_ctrl[3]), .ny(alu_ctrl[2]), .f(alu_ctrl[1]), .no(alu_ctrl[0]),
        .out(alu_out), .zr(zr), .ng(ng)
    );

    // Program Counter
    PC pc_unit (.clk(clk), .reset(reset), .load(jump), .inc(1'b1), .in(a_reg_out), .out(pc));

    // Outputs
    assign outM = alu_out;
    assign addressM = a_reg_out;

endmodule
