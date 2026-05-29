module inst_decode_tb();

    reg [31:0] instruction;
    wire [4:0] rs1, rs2, rd;
    wire reg_write, alu_src, mem_read, mem_write, branch;
    wire [1:0] wb_sel, alu_op;
    wire [31:0] immediate_extended;

    initial begin
        
        instruction = 32'h00B502B3;
        #10;
        instruction = 32'hFF620193;
        #10 ;
        instruction = 32'h0284A403;
        #10; 
        instruction = 32'h00D60863;
        #10; 
        instruction = 32'hFFFFF0EF;
        #10;
        #10 $finish;

    end

    initial begin
        $dumpfile("inst_decode_sim.vcd");
        $dumpvars(0, inst_decode_tb);
    end
    
    instruction_decode i1 (instruction, rs1, rs2, reg_write, rd, alu_src, wb_sel, mem_read, mem_write, branch, alu_op, immediate_extended);

endmodule
