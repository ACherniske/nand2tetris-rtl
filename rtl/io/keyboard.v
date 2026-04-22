module Keyboard (
    input wire [14:0] addr,
    output reg [15:0] data_out
);
    // Placeholder for actual keyboard hardware input
    always @(*) begin
        if (addr == 15'h6000)
            data_out = 16'h0000; // Currently no key pressed
        else
            data_out = 16'h0000;
    end
endmodule
