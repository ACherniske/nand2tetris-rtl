module Loader (
    input wire clk,
    input wire reset,
    input wire [7:0] rx_data,
    input wire rx_ready,
    output reg [15:0] mem_data,
    output reg [14:0] mem_addr,
    output reg mem_write_en,
    output reg loading_active
);
    reg byte_idx; // 0 = High Byte, 1 = Low Byte

    always @(posedge clk) begin
        if (reset) begin
            mem_addr <= 0;
            byte_idx <= 0;
            mem_write_en <= 0;
            loading_active <= 1;
        end else if (rx_ready) begin
            if (byte_idx == 0) begin
                mem_data[15:8] <= rx_data; 
                byte_idx <= 1;
                mem_write_en <= 0;
            end else begin
                mem_data[7:0] <= rx_data;
                mem_write_en <= 1;         // Pulse write enable for 1 cycle
                byte_idx <= 0;
                mem_addr <= mem_addr + 1;
            end
        end else begin
            mem_write_en <= 0;
        end
    end
endmodule
