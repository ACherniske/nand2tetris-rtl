module PC(
    input  clk, reset, load, inc,
    input  [15:0] in,
    output reg [15:0] out
);
    // TODO 1: Implement priority: reset -> load -> inc -> hold
    // TODO 2: Handle 16-bit wraparound on increment (if necessary)
endmodule
