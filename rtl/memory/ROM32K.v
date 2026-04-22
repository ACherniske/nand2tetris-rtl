module ROM32K (
    input wire clk,
    input  wire [14:0] cpu_address,
    output reg  [15:0] cpu_instruction,
    input  wire [14:0] load_address,
    input  wire [15:0] load_data,
    input  wire        load_we
);

    // Using 15-bit address for 32768 words
    reg [15:0] rom [0:32767];

    // Synchronous Read and Write
    always @(posedge clk) begin
        // Port 1: CPU Read (Synchronous read is required for BRAM inference)
        cpu_instruction <= rom[cpu_address];
        
        // Port 2: Loader Write
        if (load_we) begin
            rom[load_address] <= load_data;
        end
    end
endmodule
