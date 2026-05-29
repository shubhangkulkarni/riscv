module data_memory (input clk, input mem_read, input mem_write, input [31:0] address, input [31:0] write_data, output [31:0] read_value);

    reg [31:0] data_mem [0: 63];

    assign read_value = mem_read ? data_mem[address[31:2]]: 32'd0;

    always@(posedge clk) begin
        
        if(mem_write) data_mem[address[31:2]] <= write_data;
    end
endmodule
