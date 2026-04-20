module ALU(
    input  [15:0] x, y,
    input  zx, nx, zy, ny, f, no,
    output [15:0] out,
    output zr, ng
);
    // TODO 1: Implement the pre-processing (zx, nx, zy, ny)
    // TODO 2: Implement the functional selection (f) -> (x & y) vs (x + y)
    // TODO 3: Implement post-processing (no) and invert the result
    // TODO 4: Calculate zr (1 if out == 0, else 0) and ng (1 if out < 0, else 0)
endmodule
