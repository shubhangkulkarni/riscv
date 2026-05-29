module reg_file(input clk, input [4:0] rs1, input [4:0] rs2, input write_ena, input [4:0] rd, input [31:0] write_value, output [31:0] rs1_read, output [31:0] rs2_read);
    
    reg [31:0] registers [0: 31];

    assign rs1_read = rs1? registers[rs1]: 32'd0;
    assign rs2_read = rs2? registers[rs2]: 32'd0;

    always@(posedge clk) begin
        if(write_ena & rd!= 5'd0) registers[rd] <= write_value;
    end

endmodule
