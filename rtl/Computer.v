`timescale 1ns / 1ps

module Computer (
    input wire clk,
    input wire reset
);

    wire [15:0] instruction, outM, addressM, inM, pc, ram_out, screen_out, kbd_out;
    wire writeM;

    // Address Decoding
    wire is_ram    = (addressM < 16384);
    wire is_screen = (addressM >= 16384 && addressM < 24576);
    wire is_kbd    = (addressM == 24576);

    assign inM = is_ram    ? ram_out    : 
                 is_screen ? screen_out : 
                 is_kbd    ? kbd_out    : 16'd0;

    // Components
    CPU cpu (
        .clk(clk), .reset(reset), .instruction(instruction), 
        .inM(inM), .outM(outM), .writeM(writeM), .addressM(addressM), .pc(pc)
    );

    ROM32K rom (.address(pc[14:0]), .out(instruction));

    RAM16K ram (
        .clk(clk), .writeM(writeM & is_ram), 
        .address(addressM[13:0]), .in(outM), .out(ram_out)
    );

    // Screen/Keyboard Buffers
    ScreenBuffer screen (.clk(clk), .writeM(writeM & is_screen), .address(addressM[12:0]), .in(outM), .out(screen_out));
    KeyboardBuffer kbd (.out(kbd_out));

endmodule

// Simple Buffer Modules
module ScreenBuffer (input clk, writeM, input [12:0] address, input [15:0] in, output reg [15:0] out);
    reg [15:0] mem [0:8191];
    always @(posedge clk) if (writeM) mem[address] <= in;
    always @(*) out = mem[address];
endmodule

module KeyboardBuffer (output reg [15:0] out);
    initial out = 16'd0;
endmodule
