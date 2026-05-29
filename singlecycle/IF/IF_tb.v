module if_tb();
    reg clk, reset, sel;
    reg [31:0] branch_addr;
    wire [31:0] out;
    wire [31:0] instruction;

    initial begin
        $dumpfile("IF_sim.vcd");
        $dumpvars(0, if_tb);

        clk = 0;
        reset=1;
        sel=0;
        #10 reset=0;
        #20 sel=1;
        branch_addr=32'd0;
        #10 sel=0;
        #30 reset=1;

        #10 $finish;
    end

    always #5 clk = ~clk;

    program_counter i1 (clk, reset, sel, branch_addr, out);
    instruction_mem i2 (out, instruction);
endmodule
