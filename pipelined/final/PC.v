module program_counter(input clk, input reset, input sel, input stall_detected, input [31:0] branch_addr, input mret, input exception_detected, input [31:0] mepc_out, input [31:0] mtvec_out, input misprediction, input [31:0] EX_PC_plus_4, input [31:0] btb_addr, output reg [31:0] inst_addr, output inst_addr_misaligned);

    always@(posedge clk) begin
        if(reset) inst_addr <= 32'h80000000;
        else if (!stall_detected) inst_addr <= new_addr; //implicit latching when stall_detected is 1
    end 

   reg [31:0] new_addr;

   assign inst_addr_misaligned = (inst_addr[1:0] != 2'b00);
   
   always@(*) begin
        if(exception_detected) new_addr = mtvec_out;
        else if(mret) new_addr = mepc_out;
        //else if(sel) new_addr = branch_addr;
        else if(misprediction) begin 
            if (sel) new_addr = branch_addr; //using the old branch_addr in case of misprediction (which also has to be higher priority)
            else new_addr = EX_PC_plus_4; //in case of predicting taken but actual outcome ends up being not taken
        end
        //else new_addr = inst_addr + 32'd4;
        else new_addr = btb_addr; //btb gives branch_target when btb_hit&prediction else it gives inst_addr+4 only so it can be used directly here
    end
endmodule
