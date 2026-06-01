module program_counter(input clk, input reset, input sel, input stall_detected, input [31:0] branch_addr, output reg [31:0] inst_addr);

    always@(posedge clk) begin
        if(reset) inst_addr <= 32'd0;
        else if (!stall_detected) inst_addr <= new_addr; //implicit latching when stall_detected is 1
    end 

   wire [31:0] new_addr;

   assign new_addr = (sel) ? branch_addr: inst_addr+32'd4;

endmodule
