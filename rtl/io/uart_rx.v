module uart_rx #(
    parameter CLK_HZ = 12000000,
    parameter BAUD_RATE = 115200
) (
    input wire clk,
    input wire reset,
    input wire rx,
    output reg [7:0] data,
    output reg data_ready
);

    localparam CLKS_PER_BIT = CLK_HZ / BAUD_RATE;

    reg [3:0] state = 0;
    reg [15:0] count = 0;
    reg [2:0] bit_idx = 0;
    reg [7:0] rx_buffer = 0;

    always @(posedge clk) begin
        if (reset) begin
            state <= 0;
            count <= 0;
            data_ready <= 0;
        end else begin
            data_ready <= 0;
            case (state)
                // IDLE: Wait for start bit
                0: begin
                    if (rx == 0) state <= 1;
                    count <= 0;
                end
                // START BIT: Halfway through to sample
                1: begin
                    if (count == CLKS_PER_BIT / 2) begin
                        if (rx == 0) state <= 2;
                        else state <= 0;
                        count <= 0;
                    end else count <= count + 1;
                end
                // DATA BITS: Sample 8 bits
                2: begin
                    if (count == CLKS_PER_BIT - 1) begin
                        rx_buffer[bit_idx] <= rx;
                        count <= 0;
                        if (bit_idx == 7) state <= 3;
                        else bit_idx <= bit_idx + 1;
                    end else count <= count + 1;
                end
                // STOP BIT: Complete transmission
                3: begin
                    if (count == CLKS_PER_BIT - 1) begin
                        data <= rx_buffer;
                        data_ready <= 1;
                        state <= 0;
                        bit_idx <= 0;
                    end else count <= count + 1;
                end
            endcase
        end
    end
endmodule
