module program_counter(input clk, input reset, input sel, input stall_detected, input [31:0] branch_addr, input mret, input exception_detected, input [31:0] mepc_out, input [31:0] mtvec_out, output reg [31:0] inst_addr, output inst_addr_misaligned);

    always@(posedge clk) begin
        if(reset) inst_addr <= 32'h80000000;
        else if (!stall_detected) inst_addr <= new_addr; //implicit latching when stall_detected is 1
    end 

   reg [31:0] new_addr;

   assign inst_addr_misaligned = (inst_addr[1:0] != 2'b00);
   
   always@(*) begin
        if(exception_detected) new_addr = mtvec_out;
        else if(mret) new_addr = mepc_out;
        else if(sel) new_addr = branch_addr;
        else new_addr = inst_addr + 32'd4;
    end
endmodule
