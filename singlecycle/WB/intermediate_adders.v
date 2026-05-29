module adders (input [31:0] PC_value, input[31:0] instruction,  input [31:0] imm, input [31:0] alu_result,  output reg [31:0] PC_plus_4, output reg [31:0] PC_next);

    always@(*) begin
        case(instruction[6:0])
            7'b1100011: begin
                PC_next = PC_value + imm;
            end

            7'b1101111: begin
                PC_next = PC_value + imm;
                PC_plus_4 = PC_value + 32'd4;
            end

            7'b1100111: begin
                PC_next = alu_result;
                PC_plus_4 = PC_value + 32'd4;
            end

            default: begin
                PC_next = 32'd0;
                PC_plus_4 = 32'd0;
            end
        endcase
    end

    // this module basically has both the adders needed for the branch and jump instructions along with the control blocks (mux to select between branch and jump and jump-link so that this PC_next can be fed to the mux before the PC whose 1bit selection line is just the branch signal that is already there. 

endmodule

    
