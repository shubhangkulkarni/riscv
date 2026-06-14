module exception_handler(input clk, input reset, input [31:0] inst_addr, input exception_valid, input [3:0] exception_cause, input [11:0] csr_addr, input [31:0] alu_result, input is_csr, input [2:0] funct3, output exception_detected, output [31:0] mepc_out, output [31:0] mtvec_out, output reg [31:0] csr_read, output reg [31:0] next_csr);
    reg [31:0] mepc;
    reg [31:0] mtvec;
    reg [31:0] mcause; //making it 32 bit here so that computation is all 32 bits
    always@(*) begin
        case(csr_addr) 
            12'h305: csr_read = mtvec;
            12'h341: csr_read = mepc;
            12'h342: csr_read = mcause;
            default: csr_read = 32'd0;
        endcase
    end
    
    //reg [31:0] next_csr; made it an output instead since it was needed for forwarding!

    always@(*) begin
        case(funct3[1:0])
            2'b01: next_csr = alu_result;
            2'b10: next_csr = csr_read | alu_result;
            2'b11: next_csr = csr_read & ~alu_result;
            default: next_csr = csr_read;
        endcase
    end

    always@(posedge clk) begin
        if(reset) begin
            mepc <= 32'd0;
            mtvec <= 32'h80000004;
            mcause <= 4'd0;
        end
        else if(exception_valid) begin
            mepc <= inst_addr;
            mcause <= {28'd0, exception_cause};
        end
        else if(is_csr) begin
            case(csr_addr) 
                12'h305: mtvec <= next_csr;
                12'h341: mepc <= next_csr;
                12'h342: mcause <= next_csr;
                default: ;
            endcase
        end
    end

    assign exception_detected = exception_valid;
    assign mepc_out = mepc;
    assign mtvec_out = mtvec;

endmodule
