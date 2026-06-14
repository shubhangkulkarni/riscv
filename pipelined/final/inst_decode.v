module instruction_decode(input [31:0] instruction, output [4:0] rs1, output [4:0] rs2, output reg reg_write,  output [4:0] rd, output reg alu_src, output reg [1:0] wb_sel, output reg mem_read, output reg mem_write, output reg branch, output reg [1:0] alu_op, output reg [31:0] immediate_extended, output [2:0]funct3, output s, output reg ecall, output reg ebreak, output reg illegal_instruction, output reg mret, output reg is_csr); //made it [1:0] wb_sel instead of just mem_reg since in the case of jump i.e jtype instructions, we would need to select between output of ALU, MEM and the standalone PC+4 adder for the link reg.
    
    wire [6:0] opcode;
    

    assign opcode = instruction[6:0];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rd = instruction[11:7];

    assign funct3 = instruction[14:12];
    assign s = instruction[30];

    always@(*) begin
        ecall = 1'b0;
        ebreak = 1'b0;
        illegal_instruction = 1'b0; //defaults
        is_csr = 1'b0;
        mret = 1'b0;

        case(opcode) 
            
            7'b0110011: begin
                reg_write = 1'b1;
                alu_src = 1'b0;
                wb_sel = 2'b00;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b0;
                alu_op = 2'b10;
                immediate_extended=32'd0;
            end

            7'b0010011: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                wb_sel = 2'b00;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b0;
                alu_op = 2'b11;
                immediate_extended = {{20{instruction[31]}}, instruction[31:20]};
            end

            7'b0000011: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                wb_sel = 2'b01;
                mem_read = 1'b1;
                mem_write = 1'b0;
                branch = 1'b0;
                alu_op = 2'b00;
                immediate_extended = {{20{instruction[31]}}, instruction[31:20]};
            end

            7'b0100011: begin
                reg_write = 1'b0;
                alu_src = 1'b1;
                wb_sel = 2'b00;
                mem_read = 1'b0;
                mem_write = 1'b1;
                branch = 1'b0;
                alu_op = 2'b00;
                immediate_extended = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end

            7'b1100011: begin
                reg_write = 1'b0;
                alu_src = 1'b0;
                wb_sel = 2'b00;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b1;
                alu_op = 2'b01;
                immediate_extended = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            end

            7'b1101111: begin
                reg_write = 1'b1;
                alu_src = 1'b0; //in this jtype instructions, just make the mux before regfile (which gives the write_data to regfile) include the output from PC+4 adder and ignore the alu and memory's outputs. 
                wb_sel = 2'b10;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b1; 
                alu_op = 2'b00; //doesn't matter since its skipped;
                immediate_extended = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            end

            7'b1100111: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                wb_sel = 2'b10;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b1; //but we need a mux before the mux of the PC to choose between rs1+imm or PC+imm;
                alu_op = 2'b00; //Even though for Itype its 11, it is 00 here since we just need to add the imm to rs1
                immediate_extended = {{20{instruction[31]}}, instruction[31:20]};
            end

            7'b0110111, 7'b0010111: begin //for utype instructions
                reg_write = 1'b1;
                alu_src = 1'b1;
                wb_sel = 2'b00;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b0;
                alu_op = 2'b00;
                immediate_extended = {instruction[31:12], 12'd0}; 
            end
            
            7'b1110011: begin
                reg_write = 1'b0;
                alu_src = 1'b0;
                wb_sel = 2'b00;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b0;
                alu_op = 2'b00;
                immediate_extended = 32'd0;
                ecall = 1'b0;
                ebreak = 1'b0;
                mret = 1'b0; //NOT YET DECLARED ANYWHERE!
                is_csr = 1'b0; //NOT YET DECLARED ANYWHERE!
                illegal_instruction = 1'b0;

                //if(instruction == 32'h00000073 ) ecall = 1'b1;
                //else if (instruction == 32'h00100073) ebreak = 1'b1;
                //else illegal_instruction = 1'b1; //important - since we need it to be one even when some of the system instructions are not implemented!

                //ecall, ebreak, mret, and all csr related instructions have this opcode only so for using case here to set some control signals correctly

                case(instruction[14:12]) 
                    3'b000: begin
                        if(instruction[31:20] == 12'd0) ecall = 1'b1;
                        else if(instruction[31:20] == 12'd1) ebreak = 1'b1;
                        else if(instruction == 32'h30200073) mret = 1'b1;
                        else illegal_instruction = 1'b1;
                    end

                    3'b001, 3'b010, 3'b011: begin
                        reg_write = 1'b1;
                        alu_src = 1'b0;
                        wb_sel = 2'b11; //using the extra available input of the writeback mux since its coming from neither the adder for jal, ALU nor the MEM output. 
                        mem_read = 1'b0;
                        mem_write = 1'b0;
                        branch = 1'b0;
                        alu_op = 2'b00; //just keeping it zero since we either has to do alu_result = rs1 or alu_result = imm so I'll use the is_csr signal to do this as a separate conditonal block in the ALU instead of using the ALU_op at all
                        immediate_extended = 32'd0;
                        is_csr = 1'b1;
                    end

                    3'b101, 3'b110, 3'b111: begin
                        reg_write = 1'b1;
                        alu_src = 1'b1;
                        wb_sel = 2'b11;
                        mem_read = 1'b0;
                        mem_write = 1'b0;
                        branch = 1'b0;
                        alu_op = 2'b00; //same as above
                        immediate_extended = {{27{instruction[19]}}, instruction[19:15]};
                        is_csr = 1'b1;
                    end

                    default: illegal_instruction = 1'b1;
                endcase
            end

            default: begin
                reg_write = 1'b0;
                alu_src = 1'b0;
                wb_sel = 2'b00;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b0;
                alu_op = 2'b00;
                immediate_extended = 32'd0;
                illegal_instruction = 1'b1;
            end
        endcase

    end

endmodule
