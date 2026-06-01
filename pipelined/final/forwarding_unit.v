module forwarding_unit (input [4:0] ID_EX_rs1, input [4:0] ID_EX_rs2, input [4:0] EX_MEM_rd, input EX_MEM_reg_write, input [4:0] MEM_WB_rd, input  MEM_WB_reg_write, output reg [1:0] forward_1, output reg [1:0] forward_2);

    always@(*) begin
        forward_1 = 2'b00;
        forward_2 = 2'b00; //this is for the defaults

        if(ID_EX_rs1 == EX_MEM_rd & EX_MEM_reg_write & EX_MEM_rd!=5'd0) forward_1 = 2'b01; //this if else ensures priority to MEM to EX over WB to EX in case of double forwarding sort of situation
        else if(ID_EX_rs1 == MEM_WB_rd & MEM_WB_reg_write & MEM_WB_rd!=5'd0) forward_1 = 2'b10;

        if(ID_EX_rs2 == EX_MEM_rd & EX_MEM_reg_write & EX_MEM_rd!=5'd0) forward_2 = 2'b01;
        else if(ID_EX_rs2 == MEM_WB_rd & MEM_WB_reg_write & MEM_WB_rd!=5'd0) forward_2 = 2'b10;

    end

endmodule

