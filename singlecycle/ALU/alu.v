module alu (input [31:0] rs1, input [31:0] rs2, input [31:0] imm, input [1:0] alu_op, input alu_src, input [2:0] funct3, input s, output reg [31:0] alu_result, output zero);
    
    wire [31:0] op1, op2;

    assign op1 = rs1;
    assign op2 = alu_src? imm: rs2;

    always@(*) begin
        
        case(alu_op) 
            
            2'b00: begin
                alu_result = op1 + op2;
            end

            2'b01: begin
                alu_result = op1 - op2;
            end

            2'b10: begin
                case(funct3) 
                    3'b000: alu_result = (s)? (op1 - op2) : (op1 + op2);
                    3'b001: alu_result = op1 << op2;
                    3'b010: alu_result = ($signed(op1) < $signed(op2)) ? 32'd1: 32'd0;
                    3'b011: alu_result = (op1 < op2) ? 32'd1: 32'd0;
                    3'b100: alu_result = op1 ^ op2;
                    3'b101: alu_result = (s)? ($signed(op1) >>> op2) : (op1 >> op2);
                    3'b110: alu_result = op1 | op2;
                    3'b111: alu_result = op1 & op2;
                endcase
            end

            2'b11: begin
                case(funct3)
                    3'b000: alu_result = op1 + op2;
                    3'b001: alu_result = op1 << op2[4:0];
                    3'b010: alu_result = ($signed(op1) < $signed (op2))? 32'd1: 32'd0;
                    3'b011: alu_result = (op1 < op2) ? 32'd1: 32'd0;
                    3'b100: alu_result = op1 ^ op2;
                    3'b101: alu_result = (s)? ($signed(op1) >>> op2[4:0]) : (op1 >> op2[4:0]);
                    3'b110: alu_result = op1 | op2;
                    3'b111: alu_result = op1 & op2;
                endcase
            end

        endcase

    end

    assign zero = ~(|alu_result);

endmodule
