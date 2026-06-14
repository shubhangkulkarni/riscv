module top_tb ();
    
    reg clk, reset;
    wire ecall_out, ebreak_out;
    wire [26:0] temp1, temp2;

    initial begin
        $dumpfile("riscv-pipeline.vcd");
        $dumpvars(0, top_tb);
        $dumpvars(0, top_tb.i1.i6.data_mem[80]);
	$dumpvars(0, top_tb.i1.i4.registers[1]);
	$dumpvars(0, top_tb.i1.i4.registers[2]);
	$dumpvars(0, top_tb.i1.i4.registers[3]);
	$dumpvars(0, top_tb.i1.i_exception.mepc);
        clk=0;
        reset=1;
        #20 reset=0;

    end

    always #5 clk = ~clk;
    top_module i1(clk, reset, ecall_out, ebreak_out, temp1, temp2);

/*    always@(posedge clk) begin
        if(i1.EX_MEM_mem_write & (i1.EX_MEM_alu_result==32'h8000FFF0)) begin
            if(i1.EX_MEM_rs2_read == 32'h00000001) $display("passed!");
            else $display("failed!");
            $finish;
        end
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
    
*/
endmodule
