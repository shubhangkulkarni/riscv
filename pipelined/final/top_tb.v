module top_tb ();
    
    reg clk, reset;

    initial begin
        $dumpfile("riscv-pipeline.vcd");
        $dumpvars(0, top_tb);

        clk=0;
        reset=1;
        #30 reset=0;

        #200 $finish;
    end

    always #5 clk = ~clk;
    top_module i1(clk, reset);
endmodule
