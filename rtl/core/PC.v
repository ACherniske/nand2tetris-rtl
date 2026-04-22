`timescale 1ns / 1ps

module PC (
    input wire clk,
    input wire reset,
    input wire load,
    input wire inc,
    input wire [15:0] in,
    output reg [15:0] out
);

    initial out = 16'd0;

    always @(posedge clk) begin
        if (reset)
            out <= 16'd0;
        else if (load)
            out <= in;
        else if (inc)
            out <= out + 16'd1;
    end

endmodule
