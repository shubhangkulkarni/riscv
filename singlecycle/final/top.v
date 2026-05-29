module top_module (input clk, input reset);

    wire sel; //done
    wire [31:0] branch_addr; //done
    wire [31:0] inst_addr; //done
    program_counter i1 (clk, reset, sel, branch_addr, inst_addr);
    assign sel = (instruction[6:0]==7'b1100011)? (branch&zero) : (branch);
    assign branch_addr = PC_next;

    wire [31:0] instruction; //done
    instruction_mem i2 (inst_addr, instruction);
    
    wire [4:0] rs1, rs2; //done
    wire reg_write; //done
    wire [4:0] rd; //done
    wire alu_src; //done
    wire [1:0] wb_sel; //done
    wire mem_read; //done
    wire mem_write; //done
    wire branch; //done
    wire [1:0] alu_op; //done
    wire [31:0] immediate_extended; //done
    wire [2:0] funct3; //done
    wire s; //done
    instruction_decode i3(instruction, rs1, rs2, reg_write, rd, alu_src, wb_sel, mem_read, mem_write, branch, alu_op, immediate_extended, funct3, s);

    wire [31:0] write_value; //done
    wire [31:0] rs1_read, rs2_read; //done
    reg_file i4(clk, rs1, rs2, reg_write, rd, write_value, rs1_read, rs2_read);
    assign write_value = wb_out;

    wire [31:0] alu_result; //done
    wire zero; //done
    alu i5(rs1_read, rs2_read, immediate_extended, alu_op, alu_src, funct3, s, alu_result, zero);

    wire [31:0] read_value; //done
    data_memory i6(clk, mem_read, mem_write, alu_result, rs2_read, read_value);
    
    wire [31:0] adder_result; //done
    wire [31:0] wb_out; //done
    writeback i7(alu_result, read_value, adder_result, wb_sel, wb_out);

    wire [31:0] PC_plus_4; //done
    wire [31:0] PC_next; //done
    adders i8(inst_addr, instruction, immediate_extended, alu_result, PC_plus_4, PC_next);

    assign adder_result = PC_plus_4;

endmodule
