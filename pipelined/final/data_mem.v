module data_memory (input clk, input mem_read, input mem_write, input [31:0] address, input [31:0] write_data, input [2:0] funct3, output reg [31:0] read_value, output load_address_misaligned, output store_address_misaligned);

    reg [7:0] data_mem [0: 32767];
    //reg [7:0] data_mem [0: 15];
    
    initial $readmemh("program.hex", data_mem);

    wire is_word = (funct3[1:0] == 2'b10);
    wire is_halfword = (funct3[1:0] == 2'b01);

    wire addr_misaligned = (is_word && address[1:0]!=2'b00) || (is_halfword && address[0]!=1'b0);
    assign load_address_misaligned = (mem_read) && (addr_misaligned);
    assign store_address_misaligned = (mem_write) && (addr_misaligned);
    
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
        
        if (mem_write & !store_address_misaligned) begin
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
