module btb(input clk, input reset, input [31:0] inst_addr, input [31:0] ID_EX_inst_addr, input EX_is_branch, input [31:0] EX_target_addr, input branch_predictor, output hit, output [31:0] branch_addr);
    reg valid [0:127];
    reg [22:0] tag [0:127];
    reg [31:0] target_addr_buffer [0:127];

    wire [6:0] write_index = ID_EX_inst_addr[8:2];
    wire [22:0] write_tag = ID_EX_inst_addr[31:9];

    wire [6:0] read_index = inst_addr[8:2];
    wire [22:0] read_tag = inst_addr[31:9];

    assign hit = (valid[read_index]) && (tag[read_index] == read_tag);
    assign branch_addr = (hit && branch_predictor)? (target_addr_buffer[read_index]) : (inst_addr+32'd4);
    integer i;
    always@(posedge clk) begin
        if(reset) begin
            for(i=0; i<128; i=i+1) valid[i] <= 1'b0;
        end
        else if(EX_is_branch) begin
            tag[write_index] <= write_tag;
            target_addr_buffer[write_index] <= EX_target_addr;
            valid[write_index] <= 1'b1;
        end
    end
    
endmodule

