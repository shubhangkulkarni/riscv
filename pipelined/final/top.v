module top_module (input clk, input reset);

    wire sel; //done
    wire [31:0] branch_addr; //done
    wire [31:0] inst_addr; //done
    program_counter i1 (clk, reset, sel, stall_detected, branch_addr, inst_addr);
    assign branch_addr = PC_next;

    wire [31:0] instruction; //done
    instruction_mem i2 (inst_addr, instruction);

    reg [31:0] IF_ID_inst_addr, IF_ID_instruction; //inst_addr and instruction are the only 2 outputs from IF so reg done
    always@(posedge clk) begin
        if (reset | sel) begin //ORed the sel signal also since flushing needs to happen whenever sel=1 since currently its in the always-not-taken branch prediction
            IF_ID_inst_addr <= 32'd0;
            IF_ID_instruction <= 32'h00000013; //this is basically addi x0 x0 0 which basically does nothing in the ahead stages but also does not give full of xxxxxx results esp for PC
        end
        else if (!stall_detected) begin //implicity latching in the case of stall being detected i.e when stall detected is 1
            IF_ID_inst_addr <= inst_addr;
            IF_ID_instruction <= instruction;
        end
    end
    
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
    instruction_decode i3(IF_ID_instruction, rs1, rs2, reg_write, rd, alu_src, wb_sel, mem_read, mem_write, branch, alu_op, immediate_extended, funct3, s); //changed input to the resp regs

    wire [31:0] write_value; //done
    wire [31:0] rs1_read, rs2_read; //done
    wire [6:0] opcode; //the intermediate adders need it for jump/branch thing
    reg_file i4(clk, rs1, rs2, MEM_WB_reg_write, MEM_WB_rd, write_value, rs1_read, rs2_read); //this is part of ID itself so inputs will remain those internal wires itself except write_value CHECK!
    wire stall_detected;
    hazard_detection_unit i_hazard (rs1, rs2, ID_EX_mem_read, ID_EX_rd, stall_detected);

    assign write_value = wb_out; //this is correctly coming from wb only
    assign opcode = IF_ID_instruction[6:0];
    //reg [4:0] ID_EX_rs1, ID_EX_rs2, ID_EX_rd;
    //reg ID_EX_reg_write;
    reg ID_EX_alu_src;
    reg [1:0] ID_EX_wb_sel;
    reg ID_EX_mem_read;
    reg ID_EX_mem_write;
    reg ID_EX_branch;
    reg [1:0] ID_EX_alu_op;
    reg [31:0] ID_EX_immediate_extended;
    reg [2:0] ID_EX_funct3;
    reg ID_EX_s;
    reg [31:0] ID_EX_rs1_read;
    reg [31:0] ID_EX_rs2_read;
    reg [31:0] ID_EX_inst_addr; //this is basically PC and the intermediate adders need it (used for jump) which are placed in the WB so need to pass it everywhere
    reg [6:0] ID_EX_opcode;//this is is needed by intermediate adders
    reg ID_EX_reg_write; //Since write happens in WB and the regwrite signal here is of the instruction in ID we need that of the instruction in WB so just pass it till there
    reg [4:0] ID_EX_rd; //'' '' '' '' '' ''.... same as above thing
    reg [4:0] ID_EX_rs1, ID_EX_rs2;
    always@(posedge clk) begin //all outputs from ID made to reg last time made mistake of doing modulewise instead of these stagewise
        if(reset | stall_detected | sel) begin //added sel also since its currently in always-not-taken branch prediction so whenever branch is taken, prediction is wrong and flush is needed
            ID_EX_alu_src <= 1'b0;
            ID_EX_wb_sel <= 2'd0;
            ID_EX_mem_read <= 1'b0;
            ID_EX_mem_write <= 1'b0;
            ID_EX_branch <= 1'b0;
            ID_EX_alu_op <= 2'd0;
            ID_EX_immediate_extended <= 32'd0;
            ID_EX_funct3 <= 3'd0;
            ID_EX_s <= 1'b0;
            ID_EX_rs1_read <= 32'd0;
            ID_EX_rs2_read <= 32'd0;
            ID_EX_inst_addr <= 32'd0;
            ID_EX_opcode <= 7'd0;
            ID_EX_reg_write <= 1'b0;
            ID_EX_rd <= 5'd0;
            ID_EX_rs1 <= 5'd0;
            ID_EX_rs2 <= 5'd0;
        end
        //ID_EX_rs1 <= rs1;
        //ID_EX_rs2 <= rs2;
        //ID_EX_rd <= rd;
        //ID_EX_reg_write <= reg_write;
        else begin
            ID_EX_alu_src <= alu_src;
            ID_EX_wb_sel <= wb_sel;
            ID_EX_mem_read <= mem_read;
            ID_EX_mem_write <= mem_write;
            ID_EX_branch <= branch;
            ID_EX_alu_op <= alu_op;
            ID_EX_immediate_extended <= immediate_extended;
            ID_EX_funct3 <= funct3;
            ID_EX_s <= s;
            ID_EX_rs1_read <= rs1_read;
            ID_EX_rs2_read <= rs2_read;
            ID_EX_inst_addr <= IF_ID_inst_addr;
            ID_EX_opcode <= opcode;
            ID_EX_reg_write <= reg_write;
            ID_EX_rd <= rd;
            ID_EX_rs1 <= rs1;
            ID_EX_rs2 <= rs2;
        end
    end


    wire [31:0] alu_result; //done
    wire zero; //done
    wire [31:0] PC_plus_4;
    wire [31:0] PC_next; 

    wire [1:0] forward_1;
    wire [1:0] forward_2;

    wire [31:0] alu_input_1, alu_input_2;

    assign alu_input_1 = (forward_1 == 2'b01) ? (EX_MEM_alu_result) : (forward_1 == 2'b10 ? write_value: ID_EX_rs1_read);
    assign alu_input_2 = (forward_2 == 2'b01) ? (EX_MEM_alu_result) : (forward_2 == 2'b10 ? write_value: ID_EX_rs2_read);

    alu i5(alu_input_1, alu_input_2, ID_EX_immediate_extended, ID_EX_alu_op, ID_EX_alu_src, ID_EX_funct3, ID_EX_s, alu_result, zero); //inputs changed to regs for pipeline
    adders i(ID_EX_inst_addr, ID_EX_opcode, ID_EX_immediate_extended, alu_result, PC_plus_4, PC_next);
    forwarding_unit i_forward (ID_EX_rs1, ID_EX_rs2, EX_MEM_rd, EX_MEM_reg_write, MEM_WB_rd, MEM_WB_reg_write, forward_1, forward_2);
    assign sel = (ID_EX_opcode == 7'b1100011) ? (ID_EX_branch & zero) : ID_EX_branch;

    reg [31:0] EX_MEM_alu_result;
    reg EX_MEM_zero;
    reg EX_MEM_mem_read; //since these need to be passed on further
    reg EX_MEM_mem_write; //since these need to be passed on further (MEM)
    reg [31:0] EX_MEM_rs2_read; //since these need to be passed on further (MEM itself)
    reg [1:0] EX_MEM_wb_sel; //WB needs it so got to pass it on throughout
    //reg [31:0] EX_MEM_inst_addr; //this is PC - needed for intermediate adders present in WB
    //reg [6:0] EX_MEM_opcode; //intermediate adders need it (jump, branch) which is in WB
    //reg [31:0] EX_MEM_immediate_extended; //intermediate adders once again
    reg [31:0] EX_MEM_PC_plus_4;
    reg EX_MEM_reg_write; 
    reg [4:0] EX_MEM_rd; 
    always@(posedge clk) begin //only 2 outputs from EX stage to be reg and a few to be carried forward (like the ones which MEM needs)
        if(reset) begin
            EX_MEM_alu_result <= 32'd0;
            EX_MEM_zero <= 1'b0;
            EX_MEM_mem_read <= 1'b0;
            EX_MEM_mem_write <= 1'b0;
            EX_MEM_rs2_read <= 32'd0;
            EX_MEM_wb_sel <= 2'd0;
            EX_MEM_PC_plus_4 <= 32'd0;
            EX_MEM_reg_write <= 1'b0;
            EX_MEM_rd <= 5'd0;
        end

        else begin
            EX_MEM_alu_result <= alu_result;
            EX_MEM_zero <= zero;
            EX_MEM_mem_read <= ID_EX_mem_read;
            EX_MEM_mem_write <= ID_EX_mem_write;
            EX_MEM_rs2_read <= alu_input_2; //important since earlier it was just ID_EX_rs2_read but if forwarding was active and it changed, it needs to be passed on properly!
            EX_MEM_wb_sel <= ID_EX_wb_sel;
            //EX_MEM_inst_addr <= ID_EX_inst_addr;
            //EX_MEM_opcode <= ID_EX_opcode;
            //EX_MEM_immediate_extended <= ID_EX_immediate_extended;
            EX_MEM_PC_plus_4 <= PC_plus_4;
            EX_MEM_reg_write <= ID_EX_reg_write;
            EX_MEM_rd <= ID_EX_rd;
        end
    end

    wire [31:0] read_value; //done
    data_memory i6(clk, EX_MEM_mem_read, EX_MEM_mem_write, EX_MEM_alu_result, EX_MEM_rs2_read, read_value); //all inputs changed to resp regs

    reg [31:0] MEM_WB_read_value;
    reg [31:0] MEM_WB_alu_result; //WB needs this 
    reg [1:0] MEM_WB_wb_sel; //WB needs this
    //reg [31:0] MEM_WB_inst_addr; //intermediate adders needs this
    //reg [6:0] MEM_WB_opcode; //intermediate adders need this
    //reg [31:0] MEM_WB_immediate_extended; //intermediate adders need this
    reg [31:0] MEM_WB_PC_plus_4;
    reg MEM_WB_reg_write;
    reg [4:0] MEM_WB_rd;
    always@(posedge clk) begin
        if(reset) begin
            MEM_WB_read_value <= 32'd0;
            MEM_WB_alu_result <= 32'd0;
            MEM_WB_wb_sel <= 2'd0;
            MEM_WB_PC_plus_4 <= 32'd0;
            MEM_WB_reg_write <= 1'b0;
            MEM_WB_rd <= 5'd0;
        end

        else begin
            MEM_WB_read_value <= read_value;
            MEM_WB_alu_result <= EX_MEM_alu_result;
            MEM_WB_wb_sel <= EX_MEM_wb_sel;
            //MEM_WB_inst_addr <= EX_MEM_inst_addr;
            //MEM_WB_opcode <= EX_MEM_opcode;
            //MEM_WB_immediate_extended <= EX_MEM_immediate_extended;
            MEM_WB_PC_plus_4 <= EX_MEM_PC_plus_4;
            MEM_WB_reg_write <= EX_MEM_reg_write;
            MEM_WB_rd <= EX_MEM_rd;
        end
    end
    
    wire [31:0] adder_result; //done
    wire [31:0] wb_out; //done
    writeback i7(MEM_WB_alu_result, MEM_WB_read_value, adder_result, MEM_WB_wb_sel, wb_out); //adder result is generated here only (in WB but by the module below)

    //wire [31:0] PC_plus_4; //done
    //wire [31:0] PC_next; //done
    //adders i8(MEM_WB_inst_addr, MEM_WB_opcode, MEM_WB_immediate_extended, MEM_WB_alu_result, PC_plus_4, PC_next);

    assign adder_result = MEM_WB_PC_plus_4;

endmodule
