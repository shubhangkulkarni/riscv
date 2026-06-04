module data_memory (input clk, input mem_read, input mem_write, input [31:0] address, input [31:0] write_data, input [2:0] funct3, output reg [31:0] read_value);

    reg [7:0] data_mem [0: 32767];
    
    initial $readmemh("lb.hex", data_mem);
    
    wire [31:0] adjusted_addr = address - 32'h80000000;
    wire [7:0] b0 = data_mem[adjusted_addr];
    wire [7:0] b1 = data_mem[adjusted_addr+1];
    wire [7:0] b2 = data_mem[adjusted_addr+2];
    wire [7:0] b3 = data_mem[adjusted_addr+3];
    
    always@(*) begin
        if(mem_read) begin
            case(funct3) 
                3'b000: read_value = {{24{b0[7]}}, b0};
                3'b001: read_value = {{16{b1[7]}}, b1, b0};
                3'b010: read_value = {b3, b2, b1, b0};
                3'b100: read_value = {24'd0, b0};
                3'b101: read_value = {16'd0, b1, b0};
                default: read_value = 32'd0;
            endcase
        end
        else read_value = 32'd0;
    end

    always@(posedge clk) begin
        
        if (mem_write) begin
            case(funct3) 
                3'b000: begin
                    data_mem[adjusted_addr] <= write_data[7:0];
                end
                3'b001: begin
                    data_mem[adjusted_addr+1] <= write_data[15:8];
                    data_mem[adjusted_addr] <= write_data[7:0];
                end
                3'b010: begin
                    data_mem[adjusted_addr+3] <= write_data[31:24];
                    data_mem[adjusted_addr+2] <= write_data[23:16];
                    data_mem[adjusted_addr+1] <= write_data[15:8];
                    data_mem[adjusted_addr] <= write_data[7:0];
                end
                default: begin
                    data_mem[adjusted_addr+3] <= write_data[31:24];
                    data_mem[adjusted_addr+2] <= write_data[23:16];
                    data_mem[adjusted_addr+1] <= write_data[15:8];
                    data_mem[adjusted_addr] <= write_data[7:0];
                end
            endcase
        end
    end
endmodule
