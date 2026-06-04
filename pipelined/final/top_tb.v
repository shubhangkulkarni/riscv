module top_tb ();
    
    reg clk, reset;
    wire ecall_out, ebreak_out;

    initial begin
        $dumpfile("riscv-pipeline.vcd");
        $dumpvars(0, top_tb);

        clk=0;
        reset=1;
        #20 reset=0;

    end

    always #5 clk = ~clk;
    top_module i1(clk, reset, ecall_out, ebreak_out);

    always@(posedge clk) begin
        if(ebreak_out) begin
            $display("ebreak!");
            $finish;
        end
        if(ecall_out) begin
            if(i1.i4.registers[3]==32'd1) $display("passed!");
            else $display("failed at test #%0d", i1.i4.registers[3] >> 1);
            $finish;
        end
    end
endmodule
