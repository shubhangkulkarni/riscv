module top_module (input clk, input reset, output ecall_out, output ebreak_out, output [26:0] debug_alu_result, output [26:0] debug_mem_result);

    wire sel; //done
    wire [31:0] branch_addr; //done
    wire [31:0] inst_addr; //done
    wire inst_addr_misaligned; //to be driven //done
    wire [9:0] global_history; //needs to be passed down since ID_EX_global_history is needed to update global_history in case of misprediction //changed to 10 bits
    wire prediction;
    wire [31:0] btb_branch_addr;
    wire btb_hit;

    branch_predictor i_branch_predictor(clk, reset, inst_addr, btb_hit, ID_EX_branch, ID_EX_inst_addr, ID_EX_global_history, misprediction, sel, global_history, prediction); //sel itself is the correct_outcome (which was previously being used when we had a branch or jump instruction //btb_hit itself is the best way to find IF_is_branch since no decode has happened

    btb i_btb(clk, reset, inst_addr, ID_EX_inst_addr, ID_EX_branch, PC_next, prediction, btb_hit, btb_branch_addr); //ID_EX_branch itself is EX_is_branch signal which includes both branch and jump instructions

    program_counter i1 (clk, reset, sel, stall_detected, branch_addr, EX_MEM_mret, exception_detected, mepc_out, mtvec_out, misprediction, PC_plus_4, btb_branch_addr, inst_addr, inst_addr_misaligned);
    assign branch_addr = PC_next; //to be updated after branch prediction fully in place //this is what is coming from EX (to be used when misprediction)

    wire [31:0] instruction; //done
    instruction_mem i2 (inst_addr, instruction);

    reg [31:0] IF_ID_inst_addr, IF_ID_instruction; //inst_addr and instruction are the only 2 outputs from IF so reg done
    reg IF_ID_exception_valid;
    reg [3:0] IF_ID_exception_cause; //these 2 needed to handle exceptions. Overall exception handler kept in MEM stage.
    reg [9:0] IF_ID_global_history; //changed to 10 bits
    reg IF_ID_prediction;
    always@(posedge clk) begin
        if (reset | misprediction | exception_flush) begin //ORed the sel signal also since flushing needs to happen whenever sel=1 since currently its in the always-not-taken branch prediction //replaced sel with misprediction after adding thhe gshare branch predictor and btb
            IF_ID_inst_addr <= 32'd0;
            IF_ID_instruction <= 32'h00000013; //this is basically addi x0 x0 0 which basically does nothing in the ahead stages but also does not give full of xxxxxx results esp for PC
            IF_ID_exception_valid <= 1'b0;
            IF_ID_exception_cause <= 4'd0;
            IF_ID_global_history <= 10'd0; //changed to 10 bits
            IF_ID_prediction <= 1'b0;
        end
        else if (!stall_detected) begin //implicity latching in the case of stall being detected i.e when stall detected is 1
            IF_ID_inst_addr <= inst_addr;
            IF_ID_instruction <= instruction;
            IF_ID_exception_valid <= inst_addr_misaligned;
            IF_ID_exception_cause <= 4'd0; //standard code for misaligned instruction address ALSO: no need to check if misaligned or not here since either ways value will be 0 only
            IF_ID_global_history <= global_history;
            IF_ID_prediction <= prediction;
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
    wire ecall, ebreak;
    wire illegal_instruction; //to be driven //done
    wire mret; //done
    wire is_csr; //to be driven //done
    instruction_decode i3(IF_ID_instruction, rs1, rs2, reg_write, rd, alu_src, wb_sel, mem_read, mem_write, branch, alu_op, immediate_extended, funct3, s, ecall, ebreak, illegal_instruction, mret, is_csr); //changed input to the resp regs

    wire [31:0] write_value; //done
    wire [31:0] rs1_read, rs2_read; //done
    wire [6:0] opcode; //the intermediate adders need it for jump/branch thing
    wire [11:0] csr_addr; //needed to handle the software part of exceptions (csrrc etc..)
    reg_file i4(clk, rs1, rs2, MEM_WB_reg_write, MEM_WB_rd, write_value, rs1_read, rs2_read); //this is part of ID itself so inputs will remain those internal wires itself except write_value CHECK!
    wire stall_detected;
    hazard_detection_unit i_hazard (rs1, rs2, ID_EX_mem_read, ID_EX_rd, stall_detected);

    assign write_value = wb_out; //this is correctly coming from wb only
    assign opcode = IF_ID_instruction[6:0];
    assign csr_addr = IF_ID_instruction[31:20]; //for csr type instructions this is placed instead of the immediate and immediate is placed in rs1's place in cases where immediate is used else that is also rs1 only
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
    reg ID_EX_ecall, ID_EX_ebreak;
    reg ID_EX_exception_valid;
    reg [3:0] ID_EX_exception_cause; //these 2 needed for exception handling later in MEM
    reg ID_EX_mret, ID_EX_is_csr; //for the computations and writeback of csr type instructions for handling 
    reg [11:0] ID_EX_csr_addr; //exception handling software instructions
    reg [9:0] ID_EX_global_history; //changed to 10 bits
    reg ID_EX_prediction;

    always@(posedge clk) begin //all outputs from ID made to reg last time made mistake of doing modulewise instead of these stagewise
        if(reset | stall_detected | misprediction | exception_flush) begin //added sel also since its currently in always-not-taken branch prediction so whenever branch is taken, prediction is wrong and flush is needed
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
            ID_EX_ecall <= 1'b0;
            ID_EX_ebreak <= 1'b0;
            ID_EX_exception_valid <= 1'b0;
            ID_EX_exception_cause <= 4'd0;
            ID_EX_mret <= 1'b0;
            ID_EX_is_csr <= 1'b0;
            ID_EX_csr_addr <= 12'd0;
            ID_EX_global_history <= 10'd0;//changed to 10 bits
            ID_EX_prediction <= 1'b0;
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
            ID_EX_ecall <= ecall;
            ID_EX_ebreak <= ebreak;
            ID_EX_mret <= mret;
            ID_EX_is_csr <= is_csr;
            ID_EX_csr_addr <= csr_addr;
            ID_EX_global_history <= IF_ID_global_history;
            ID_EX_prediction <= IF_ID_prediction;
            if(IF_ID_exception_valid) begin //if this instruction had exception detected in IF only then carry the same forward (some sort of priority incase multiple exceptions by same instruction)
                ID_EX_exception_valid <= IF_ID_exception_valid;
                ID_EX_exception_cause <= IF_ID_exception_cause;
            end
            else if(illegal_instruction) begin
                ID_EX_exception_valid <= 1'b1;
                ID_EX_exception_cause <= 4'd2; //standard code for illegal instruction
            end
            else begin
                ID_EX_exception_valid <= 1'b0;
                ID_EX_exception_cause <= 4'd0;
            end
        end
    end


    wire [31:0] alu_result; //done
    wire zero; //done
    wire [31:0] PC_plus_4;
    wire [31:0] PC_next; 
    wire exception_ecall_valid = ID_EX_ecall; //this is for the exception handler
    wire exception_ebreak_valid = ID_EX_ebreak; //this is for exception handler

    wire [1:0] forward_1;
    wire [1:0] forward_2;
    
    wire [31:0] alu_input_1, alu_input_2, forwarded_1;
    wire [31:0] forwarded_value_from_MEM; //this could be from the data_mem or the exception handler that's why had to add another mux here to select
    wire misprediction;

    assign forwarded_value_from_MEM = (EX_MEM_is_csr) ? (next_csr) : (EX_MEM_alu_result);

    assign debug_alu_result = alu_result; //doing this just so that synthesis happens properly and modules are not swept off

    assign forwarded_1 = (forward_1 == 2'b01) ? (forwarded_value_from_MEM) : (forward_1 == 2'b10 ? write_value: ID_EX_rs1_read);
    assign alu_input_2 = (forward_2 == 2'b01) ? (forwarded_value_from_MEM) : (forward_2 == 2'b10 ? write_value: ID_EX_rs2_read);

    assign alu_input_1 = (ID_EX_opcode == 7'b0010111) ? ID_EX_inst_addr : ((ID_EX_opcode == 7'b0110111) ? 32'd0: forwarded_1);

    alu i5(alu_input_1, alu_input_2, ID_EX_immediate_extended, ID_EX_alu_op, ID_EX_alu_src, ID_EX_funct3, ID_EX_s, ID_EX_is_csr, alu_result, zero); //inputs changed to regs for pipeline
    adders i(ID_EX_inst_addr, ID_EX_opcode, ID_EX_immediate_extended, alu_result, alu_input_1, PC_plus_4, PC_next);
    forwarding_unit i_forward (ID_EX_rs1, ID_EX_rs2, EX_MEM_rd, EX_MEM_reg_write, MEM_WB_rd, MEM_WB_reg_write, forward_1, forward_2);
    assign sel = (ID_EX_opcode == 7'b1100011) ? (ID_EX_branch & zero) : ID_EX_branch;
    assign misprediction = ID_EX_branch? (ID_EX_prediction ^ sel): 1'b0;

    reg [31:0] EX_MEM_alu_result;
    reg EX_MEM_zero;
    reg EX_MEM_mem_read; //since these need to be passed on further
    reg EX_MEM_mem_write; //since these need to be passed on further (MEM)
    reg [31:0] EX_MEM_rs2_read; //since these need to be passed on further (MEM itself)
    reg [1:0] EX_MEM_wb_sel; //WB needs it so got to pass it on throughout
    reg [31:0] EX_MEM_inst_addr; //this is PC - needed for intermediate adders present in WB
    //reg [6:0] EX_MEM_opcode; //intermediate adders need it (jump, branch) which is in WB
    //reg [31:0] EX_MEM_immediate_extended; //intermediate adders once again
    reg [31:0] EX_MEM_PC_plus_4;
    reg EX_MEM_reg_write; 
    reg [4:0] EX_MEM_rd; 
    reg EX_MEM_ecall, EX_MEM_ebreak;
    reg [2:0] EX_MEM_funct3; //needed for half/byte version detection for load and store
    reg EX_MEM_exception_valid;
    reg [3:0] EX_MEM_exception_cause;
    reg EX_MEM_is_csr, EX_MEM_mret;
    reg [11:0] EX_MEM_csr_addr;
    always@(posedge clk) begin //only 2 outputs from EX stage to be reg and a few to be carried forward (like the ones which MEM needs)
        if(reset | exception_flush) begin //since exception detected in MEM, this also is flushed unlike in the case of branch which gets detected in EX only so this need not be flushed then (that is in case of branch miss and jump)
            EX_MEM_alu_result <= 32'd0;
            EX_MEM_zero <= 1'b0;
            EX_MEM_mem_read <= 1'b0;
            EX_MEM_mem_write <= 1'b0;
            EX_MEM_rs2_read <= 32'd0;
            EX_MEM_wb_sel <= 2'd0;
            EX_MEM_PC_plus_4 <= 32'd0;
            EX_MEM_reg_write <= 1'b0;
            EX_MEM_rd <= 5'd0;
            EX_MEM_ecall <= 1'b0;
            EX_MEM_ebreak <= 1'b0;
            EX_MEM_funct3 <= 3'd0;
            EX_MEM_exception_valid <= 1'b0;
            EX_MEM_exception_cause <= 4'd0;
            EX_MEM_inst_addr <= 32'd0;
            EX_MEM_is_csr <= 1'b0;
            EX_MEM_mret <= 1'b0;
            EX_MEM_csr_addr <= 12'd0;
        end

        else begin
            EX_MEM_alu_result <= alu_result;
            EX_MEM_zero <= zero;
            EX_MEM_mem_read <= ID_EX_mem_read;
            EX_MEM_mem_write <= ID_EX_mem_write;
            EX_MEM_rs2_read <= alu_input_2; //important since earlier it was just ID_EX_rs2_read but if forwarding was active and it changed, it needs to be passed on properly!
            EX_MEM_wb_sel <= ID_EX_wb_sel;
            EX_MEM_inst_addr <= ID_EX_inst_addr;
            //EX_MEM_opcode <= ID_EX_opcode;
            //EX_MEM_immediate_extended <= ID_EX_immediate_extended;
            EX_MEM_PC_plus_4 <= PC_plus_4;
            EX_MEM_reg_write <= ID_EX_reg_write;
            EX_MEM_rd <= ID_EX_rd;
            EX_MEM_ecall <= ID_EX_ecall;
            EX_MEM_ebreak <= ID_EX_ebreak;
            EX_MEM_funct3 <= ID_EX_funct3;
            EX_MEM_is_csr <= ID_EX_is_csr;
            EX_MEM_mret <= ID_EX_mret;
            EX_MEM_csr_addr <= ID_EX_csr_addr;
            if(ID_EX_exception_valid) begin
                EX_MEM_exception_valid <= ID_EX_exception_valid;
                EX_MEM_exception_cause <= ID_EX_exception_cause;
            end
            else if(exception_ecall_valid) begin
                EX_MEM_exception_valid <= 1'b1;
                EX_MEM_exception_cause <= 4'd11;
            end
            else if(exception_ebreak_valid) begin
                EX_MEM_exception_valid <= 1'b1;
                EX_MEM_exception_cause <= 4'd3;
            end
            else begin
                EX_MEM_exception_valid <= 1'b0;
                EX_MEM_exception_cause <= 4'd0;
            end
        end
    end

    wire [31:0] read_value; //done
    wire load_address_misaligned;
    wire store_address_misaligned;
    data_memory i6(clk, EX_MEM_mem_read, EX_MEM_mem_write, EX_MEM_alu_result, EX_MEM_rs2_read, EX_MEM_funct3, read_value, load_address_misaligned, store_address_misaligned); //all inputs changed to resp regs

    assign debug_mem_result = read_value; //doing this so that synthesis happens properly without sweeping thiis module off

    //this part is now for the inputs to the exception handler module
    reg exception_valid; //this will be the input to the exception handler module
    reg [3:0] exception_cause;
    always@(*) begin
        if(EX_MEM_exception_valid) begin
            exception_valid = EX_MEM_exception_valid;
            exception_cause = EX_MEM_exception_cause;
        end
        else if(load_address_misaligned) begin
            exception_valid = 1'b1;
            exception_cause = 4'd4;
        end
        else if(store_address_misaligned) begin
            exception_valid = 1'b1;
            exception_cause = 4'd6;
        end
        else begin
            exception_valid = 1'b0;
            exception_cause = 4'd0;
        end
    end
    wire [31:0] mepc_out, mtvec_out; //begin driven only now
    wire exception_detected; //basically same as exception_valid but just put it for the sake of the name so that it is clear when using for flushing
    wire [31:0] csr_read;
    wire [31:0] next_csr;
    exception_handler i_exception(clk, reset, EX_MEM_inst_addr, exception_valid, exception_cause, EX_MEM_csr_addr, EX_MEM_alu_result, EX_MEM_is_csr, EX_MEM_funct3, exception_detected, mepc_out, mtvec_out, csr_read, next_csr); 
        

    reg [31:0] MEM_WB_read_value;
    reg [31:0] MEM_WB_alu_result; //WB needs this 
    reg [1:0] MEM_WB_wb_sel; //WB needs this
    //reg [31:0] MEM_WB_inst_addr; //intermediate adders needs this
    //reg [6:0] MEM_WB_opcode; //intermediate adders need this
    //reg [31:0] MEM_WB_immediate_extended; //intermediate adders need this
    reg [31:0] MEM_WB_PC_plus_4;
    reg MEM_WB_reg_write;
    reg [4:0] MEM_WB_rd;
    reg MEM_WB_ecall, MEM_WB_ebreak;
    reg [31:0] MEM_WB_csr_read; //needed to writeback for csr related instructions
    always@(posedge clk) begin
        if(reset | exception_flush) begin
            MEM_WB_read_value <= 32'd0;
            MEM_WB_alu_result <= 32'd0;
            MEM_WB_wb_sel <= 2'd0;
            MEM_WB_PC_plus_4 <= 32'd0;
            MEM_WB_reg_write <= 1'b0;
            MEM_WB_rd <= 5'd0;
            MEM_WB_ecall <= 1'b0;
            MEM_WB_ebreak <= 1'b0;
            MEM_WB_csr_read <= 32'd0;
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
            MEM_WB_ecall <= EX_MEM_ecall;
            MEM_WB_ebreak <= EX_MEM_ebreak;
            MEM_WB_csr_read <= csr_read;
        end
    end
    
    wire [31:0] adder_result; //done
    wire [31:0] wb_out; //done
    writeback i7(MEM_WB_alu_result, MEM_WB_read_value, adder_result, MEM_WB_csr_read, MEM_WB_wb_sel, wb_out); //adder result is generated here only (in WB but by the module below)

    //wire [31:0] PC_plus_4; //done
    //wire [31:0] PC_next; //done
    //adders i8(MEM_WB_inst_addr, MEM_WB_opcode, MEM_WB_immediate_extended, MEM_WB_alu_result, PC_plus_4, PC_next);

    assign adder_result = MEM_WB_PC_plus_4;
    assign ecall_out = MEM_WB_ecall;
    assign ebreak_out = MEM_WB_ebreak;
    
    wire exception_flush;
    assign exception_flush = exception_detected | EX_MEM_mret; //flushing of pipeline whenever exception or mret instrucition is detected
endmodule
