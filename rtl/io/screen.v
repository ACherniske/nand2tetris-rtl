module Screen (
    input wire clk,
    input wire [14:0] addr,
    input wire [15:0] data_in,
    input wire we,
    output reg [15:0] data_out
);
    // 8K word memory (15-bit address covers up to 0x5FFF)
    reg [15:0] memory [0:8191];

    always @(posedge clk) begin
        if (we)
            memory[addr[12:0]] <= data_in;
        data_out <= memory[addr[12:0]];
    end
endmodule
