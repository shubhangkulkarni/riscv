module instruction_mem(input [31:0] addr, output [31:0] instruction);

    reg [31:0] mem [0:63];

    assign instruction = mem[addr[31:2]];

    initial begin
        $readmemh("code.hex", mem);
    end

endmodule
