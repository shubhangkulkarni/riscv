module id_and_alu_tb();

    reg [31:0] instruction;
    wire [4:0] rs1, rs2, rd;
    wire reg_write, alu_src, mem_read, mem_write, branch;
    wire [1:0] wb_sel, alu_op;
    wire [31:0] immediate_extended;
    wire [2:0] funct3;
    wire s;
    reg clk;

    initial begin
        clk = 0;
        #10
        instruction = 32'h06400513; #10;
        instruction = 32'h01900593; #10;
        instruction = 32'h03200213; #10;
        instruction = 32'h0C800493; #10;
        instruction = 32'h01E00613; #10;
        instruction = 32'h01E00693; #10;
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

    always #5 clk = ~clk;

    initial begin
        $dumpfile("id_and_alu_sim.vcd");
        $dumpvars(0, id_and_alu_tb);
    end
    
    wire [31:0] rs1_read, rs2_read, write_value;
    wire [31:0] alu_result;

    assign write_value = alu_result;

    wire zero;
    instruction_decode i1 (instruction, rs1, rs2, reg_write, rd, alu_src, wb_sel, mem_read, mem_write, branch, alu_op, immediate_extended, funct3, s);
    reg_file i2 (clk, rs1, rs2, reg_write, rd, write_value , rs1_read, rs2_read);
    alu i3 (rs1_read, rs2_read, immediate_extended, alu_op, alu_src, funct3, s, alu_result, zero);
endmodule
