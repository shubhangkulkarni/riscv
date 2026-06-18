module branch_predictor(input clk, input reset, input [31:0] inst_addr, input IF_is_branch, input EX_is_branch, input [31:0] ID_EX_inst_addr, input [9:0] ID_EX_global_history, input misprediction, input correct_outcome, output reg[9:0] global_history, output prediction); //prediction=1 for taken and 0 for not-taken //IF_is_branch comes from BTB so just keep it here for now

    //reg [1:0] counters [0:127]; //just using a counter with 128 entries with each entry being a 2bit counter (similar to that HDLbits question)
    reg [1:0] counters [0:1023];
    //reg [6:0] global_history; declared it as output so commented this //global history reg which will be XORed with the PC (bottom 7 bits after excluding the 2 bottomost bits)
    //reg [6:0] next_global_history;
    reg [9:0] next_global_history;
    reg [1:0] next_counter;

    //wire [6:0] index = inst_addr[8:2] ^ global_history; 
    wire [9:0] index = inst_addr[11:2] ^ global_history;
    //wire [6:0] EX_index = ID_EX_inst_addr[8:2] ^ ID_EX_global_history; //need to pipeline the global history as well since global history would have been changed by the 2 instructions that come until the mispredicted instruction reaches EX so inorder to index to the correct old entry and change it 
    wire [9:0] EX_index = ID_EX_inst_addr[11:2] ^ ID_EX_global_history;

    assign prediction = (counters[index] == 2'b10 | counters[index] == 2'b11); //00 and 01 for not-taken and 10 and 11 for taken

    always@(*) begin
        case(counters[EX_index]) //the update happens only after instruction reaches EX so using that only
            2'b00: next_counter = (correct_outcome)? (2'b01) : (2'b00);
            2'b01: next_counter = (correct_outcome)? (2'b10) : (2'b00);
            2'b10: next_counter = (correct_outcome)? (2'b11) : (2'b01);
            2'b11: next_counter = (correct_outcome)? (2'b11) : (2'b10);
            default: next_counter = 2'b01;
        endcase
    end

    always@(*) begin
        //if(misprediction) next_global_history = {ID_EX_global_history[5:0], correct_outcome}; //need to discard whatever changes that the 2 instructions did to the global_history reg since branch was wrongly predicted
        if(misprediction) next_global_history = {ID_EX_global_history[8:0], correct_outcome};
        //else if (IF_is_branch) next_global_history = {global_history[5:0], prediction};
        else if(IF_is_branch) next_global_history = {global_history[8:0], prediction};
        else next_global_history = global_history; //updating global_history only if instruction in IF is a branch instruction (to be known, not with 100% accuracy, from BTB hit/miss)
    end
    integer i;
    always@(posedge clk) begin
        if(reset) begin
            //for(i=0; i<128; i=i+1) counters[i] <= 2'b01; //resetting to 01 (weakly NT)
            for(i=0; i<1024; i=i+1) counters[i] <= 2'b01;
            //global_history <= 7'd0;
            global_history <= 10'd0;
        end
        else begin
            //global_history[0] <= ~global_history[0]; this wont work since 2 instructions after the wrong predicted one would have also changed the global history
            global_history <= next_global_history;
            if(EX_is_branch) counters[EX_index] <= next_counter; //updating counter only if instruction in EX is branch
        end
    end

endmodule
