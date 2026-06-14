module instruction_mem(input [31:0] addr, output [31:0] instruction); 

    reg [7:0] mem [0:32767];  //made this byte sized due to how the riscv-tests format was!
    //reg [7:0] mem [0:15];
    wire [31:0] adjusted_addr = addr- 32'h80000000;

    assign instruction = {mem[adjusted_addr+3], mem[adjusted_addr+2], mem[adjusted_addr+1], mem[adjusted_addr]};

    initial begin
        $readmemh("program.hex", mem);
    end
endmodule
