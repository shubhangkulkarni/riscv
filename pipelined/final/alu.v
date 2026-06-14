module alu (input [31:0] rs1, input [31:0] rs2, input [31:0] imm, input [1:0] alu_op, input alu_src, input [2:0] funct3, input s, input is_csr, output reg [31:0] alu_result, output reg zero);
    
    wire [31:0] op1, op2;

    assign op1 = rs1;
    assign op2 = alu_src? imm: rs2;

    always@(*) begin
        if(is_csr) alu_result = (funct3[2]) ? (imm) : (rs1); //just direcly routing either rs1 or imm as alu_result since computation happens in the exception handler in the MEM stage
        else begin
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
                    3'b001: alu_result = op1 << op2[4:0];
                    3'b010: alu_result = ($signed(op1) < $signed(op2)) ? 32'd1: 32'd0;
                    3'b011: alu_result = (op1 < op2) ? 32'd1: 32'd0;
                    3'b100: alu_result = op1 ^ op2;
                    3'b101: begin
                        if(s) alu_result = $signed(op1) >>> op2[4:0];
                        else alu_result = op1 >> op2[4:0];
                    end
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
                    3'b101: begin
                        if(s) alu_result = $signed(op1) >>> op2[4:0];
                        else alu_result = op1 >> op2[4:0];
                    end
                    3'b110: alu_result = op1 | op2;
                    3'b111: alu_result = op1 & op2;
                endcase
            end

        endcase
        end
    end

    always@(*) begin
    	zero = 1'b0;
    	case(funct3) 
    		//3'b000: zero = (alu_result==32'd0);
            3'b000: zero = (op1==op2);
    		//3'b001: zero = (alu_result!=32'd0);
            3'b001: zero = (op1!=op2); //this does not have to wait for alu_result to be calculated thus happens parallely and faster. This part had large slack so changed it
    		3'b100: zero = ($signed(op1) < $signed(op2));
    		3'b101: zero = ($signed(op1) >= $signed(op2));
    		3'b110: zero = (op1 < op2);
    		3'b111: zero = (op1 >= op2);
    		default: zero = 1'b0;
	endcase
    end

endmodule
