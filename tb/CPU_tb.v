`timescale 1ns / 1ps

module CPU_tb;

    reg clk, reset;
    reg [15:0] instruction, inM;
    wire [15:0] outM, addressM, pc;
    wire writeM;

    CPU uut (.*);

    // Reference State
    reg [15:0] ref_A, ref_D, ref_PC;

    always #5 clk = ~clk;

    // --- GOLDEN MODEL LOGIC ---
    // This block mirrors the Hack Architecture behavior independently
    always @(posedge clk) begin
        if (reset) begin
            ref_A <= 0; ref_D <= 0; ref_PC <= 0;
        end else begin
            // Simplified Golden Model logic
            if (~instruction[15]) begin // A-Instruction
                ref_A <= instruction;
                ref_PC <= ref_PC + 1;
            end else begin // C-Instruction
                // In a real Golden Model, you would replicate the ALU logic here
                // ... (Logic to update ref_A, ref_D, and ref_PC based on instruction bits) ...
                ref_PC <= ref_PC + 1; 
            end
        end
    end

    // --- ASSERTION: Compare UUT to Golden Model ---
    always @(negedge clk) begin
        #1;
        if (uut.a_reg_out !== ref_A) begin
            $display("MISMATCH! A-Reg Expected: %h, Got: %h", ref_A, uut.a_reg_out);
            $finish;
        end
    end

    initial begin
        $dumpfile("test.vcd"); $dumpvars(0, CPU_tb);
        clk = 0; reset = 1; instruction = 0;
        #20 reset = 0;

        // Feed instructions and let the Golden Model verify them automatically
        @(negedge clk) instruction = 16'h000A; // @10
        repeat(5) @(negedge clk);
        
        $display("Golden Model Verification Passed!");
        $finish;
    end
endmodule
