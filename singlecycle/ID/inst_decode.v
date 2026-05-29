module instruction_decode(input [31:0] instruction, output [4:0] rs1, output [4:0] rs2, output reg reg_write,  output [4:0] rd, output reg alu_src, output reg [1:0] wb_sel, output reg mem_read, output reg mem_write, output reg branch, output reg [1:0] alu_op, output reg [31:0] immediate_extended, output [2:0]funct3, output s ); //made it [1:0] wb_sel instead of just mem_reg since in the case of jump i.e jtype instructions, we would need to select between output of ALU, MEM and the standalone PC+4 adder for the link reg.
    
    wire [6:0] opcode;

    assign opcode = instruction[6:0];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rd = instruction[11:7];

    assign funct3 = instruction[14:12];
    assign s = instruction[30];

    always@(*) begin
        
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
                immediate_extended = {{20{instruction[31]}}, instruction[31:20]};
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

            default: begin
                reg_write = 1'b0;
                alu_src = 1'b0;
                wb_sel = 2'b00;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b0;
                alu_op = 2'b00;
                immediate_extended = 32'd0;
            end
        endcase

    end

endmodule
