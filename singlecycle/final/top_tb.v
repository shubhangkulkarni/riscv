module top_tb ();
    
    reg clk, reset;

    initial begin
        $dumpfile("riscv-singlecycle.vcd");
        $dumpvars(0, top_tb);

        clk=0;
        reset=1;
        #10 reset=0;

        #300 $finish;
    end

    always #5 clk = ~clk;
    top_module i1(clk, reset);
endmodule
