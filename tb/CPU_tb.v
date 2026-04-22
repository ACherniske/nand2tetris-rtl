`timescale 1ns / 1ps

module CPU_tb;

    reg clk, reset;
    reg [15:0] instruction, inM;
    wire [15:0] outM, addressM, pc;
    wire writeM;

    CPU uut (
        .clk(clk), .reset(reset), .instruction(instruction),
        .inM(inM), .outM(outM), .writeM(writeM),
        .addressM(addressM), .pc(pc)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, CPU_tb);
        
        // 1. Initialize
        reset = 1; instruction = 0; inM = 0;
        #20 reset = 0;

        // 2. Feed instructions synchronized to PC
        // @10
        wait(pc == 0); @(negedge clk) instruction = 16'h000A;
        // D=A
        wait(pc == 1); @(negedge clk) instruction = 16'hEC10;
        // @20
        wait(pc == 2); @(negedge clk) instruction = 16'h0014;
        // D=D+A
        wait(pc == 3); @(negedge clk) instruction = 16'hE090;
        // 5. Send NOP (0000)
        wait(pc == 4); @(negedge clk) instruction = 16'h0000;
        
        // 3. Final Verification
        repeat(2) @(negedge clk);
        
        if (uut.d_reg_out === 16'd30) begin 
            $display("SUCCESS! D = %d", uut.d_reg_out);
        end else begin
            $display("FAILURE! Expected 30 (hex 1E), Got %d (hex %h)", uut.d_reg_out, uut.d_reg_out);
        end
        
        $finish;
    end
endmodule