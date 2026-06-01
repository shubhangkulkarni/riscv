module top_module (input clk, input reset);

    wire sel; //done
    wire [31:0] branch_addr; //done
    wire [31:0] inst_addr; //done  //reg done
    program_counter i1 (clk, reset, sel, branch_addr, inst_addr);
    assign sel = (instruction_reg[6:0]==7'b1100011)? (branch_reg&zero_reg) : (branch_reg);
    assign branch_addr = PC_next_reg;
    reg [31:0] inst_addr_reg;

    always@(posedge clk) inst_addr_reg <= inst_addr;

    wire [31:0] instruction; //done //reg done
    instruction_mem i2 (inst_addr_reg, instruction); //input changed to the new reg for pipeline
    reg [31:0] instruction_reg;
    
    always@(posedge clk) instruction_reg <= instruction;

    wire [4:0] rs1, rs2; //done //reg done
    wire reg_write; //done //reg done
    wire [4:0] rd; //done //reg done
    wire alu_src; //done //reg done
    wire [1:0] wb_sel; //done //reg done
    wire mem_read; //done //reg done
    wire mem_write; //done //reg done
    wire branch; //done reg done
    wire [1:0] alu_op; //done //reg done
    wire [31:0] immediate_extended; //done //reg done
    wire [2:0] funct3; //done //reg done
    wire s; //done
    instruction_decode i3(instruction_reg, rs1, rs2, reg_write, rd, alu_src, wb_sel, mem_read, mem_write, branch, alu_op, immediate_extended, funct3, s); //input changed to new reg for pipeline
    reg [4:0] rs1_reg, rs2_reg; 
    reg reg_write_reg;
    reg [4:0] rd_reg;
    reg alu_src_reg;
    reg [1:0] wb_sel_reg;
    reg mem_read_reg;
    reg mem_write_reg;
    reg branch_reg;
    reg [1:0] alu_op_reg;
    reg [31:0] immediate_extended_reg;
    reg [2:0] funct3_reg;
    reg s_reg;

    always@(posedge clk) begin
        rs1_reg <= rs1;
        rs2_reg <= rs2;
        reg_write_reg <= reg_write;
        rd_reg <= rd;
        alu_src_reg <= alu_src;
        wb_sel_reg <= wb_sel;
        mem_read_reg <= mem_read;
        mem_write_reg <= mem_write;
        branch_reg <= branch;
        alu_op_reg <= alu_op;
        immediate_extended_reg <= immediate_extended;
        funct3_reg <= funct3;
        s_reg <= s;
    end

    wire [31:0] write_value; //done //this is being driven by wb yet to be made reg!
    wire [31:0] rs1_read, rs2_read; //done //reg done
    reg_file i4(clk, rs1_reg, rs2_reg, reg_write_reg, rd_reg, write_value, rs1_read, rs2_read); //except write_value others changed to reg for pipeline
    assign write_value = wb_out;
    
    reg [31:0] rs1_read_reg, rs2_read_reg;

    always@(posedge clK) begin
        rs1_read_reg <= rs1_read;
        rs2_read_reg <= rs2_read;
    end
                            
    wire [31:0] alu_result; //done //reg done
    wire zero; //done //reg done
    alu i5(rs1_read_reg, rs2_read_reg, immediate_extended_reg, alu_op_reg, alu_src_reg, funct3_reg, s_reg, alu_result, zero); //inputs changed to resp regs for pipeline

    reg [31:0] alu_result_reg;
    reg zero_reg;

    always@(posedge clk) begin
        alu_result_reg <= alu_result;
        zero_reg <= zero;
    end

    wire [31:0] read_value; //done //reg done
    data_memory i6(clk, mem_read_reg, mem_write_reg, alu_result_reg, rs2_read_reg, read_value); //inputs changed to resp reg for pipeline

    reg [31:0] read_value_reg; 

    always@(posedge clk) begin
        read_value_reg <= read_value;
    end
    
    wire [31:0] adder_result; //done
    wire [31:0] wb_out; //done //reg done
    writeback i7(alu_result_reg, read_value_reg, adder_result, wb_sel_reg, wb_out); //all inputs except adder_result changed just assign of adder_result can be changed later

    reg [31:0] wb_out_reg;

    always@(posedge clk) begin
        wb_out_reg <= wb_out;
    end

    wire [31:0] PC_plus_4; //done
    wire [31:0] PC_next; //done
    adders i8(inst_addr_reg, instruction_reg, immediate_extended_reg, alu_result_reg, PC_plus_4, PC_next);//inputs changed to regs for pipeline

    reg [31:0] PC_plus_4_reg, PC_next_reg;

    always@(posedge clk) begin
        PC_plus_4_reg <= PC_plus_4;
        PC_next_reg <= PC_next;
    end

    assign adder_result = PC_plus_4_reg; //changed to reg 

endmodule
