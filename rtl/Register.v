module Register(
    input  wire clk, 
    input  wire load,
    input  wire [15:0] in,
    output reg  [15:0] out
);
    
    //Initial state
    initial out = 16'd0;

    // Synchronous update
    always @(posedge clk) begin
        if (load) begin
            out <= in; // Load new value on rising edge if load is high
        end
        // If load is low, retain the current value (do nothing)
    end
endmodule
