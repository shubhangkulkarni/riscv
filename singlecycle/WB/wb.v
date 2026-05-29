module writeback (input [31:0] alu_result, input [31:0] mem_result, input [31:0] adder_for_link_result, input [1:0] wb_sel, output reg [31:0] wb_out);

    always@(*) begin
        case(wb_sel) 
            2'b00: wb_out = alu_result;
            2'b01: wb_out = mem_result;
            2'b10: wb_out = adder_for_link_result;
            2'b11: wb_out = 32'd0; //could have been left but added just for the sake of it, can be used for something else later
        endcase
    end
endmodule
