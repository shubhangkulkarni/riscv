module reg_file_tb();
    
    reg clk, write_ena;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] write_value;
    wire [31:0] rs1_read, rs2_read;

    initial begin
        $dumpfile("reg_file_sim.vcd");
        $dumpvars(0, reg_file_tb);

        clk=0;
        #10 rs1 = 5'd0;
        rs2 = 5'd0;
        rd = 5'd1;
        write_value = 32'd67;
        write_ena = 1;
        #10 rs1 = 5'd1;
        rs2 = 5'd0;
        write_ena=0;
        #10 rs1 = 5'd1;
        rs2 = 5'd1;
        write_ena=1;
        rd=5'd2;
        write_value=32'd420;
        #10 rs1=5'd1;
        rs2=5'd2;
        write_ena=0;
        #20 $finish;

    end

    always #5 clk = ~clk;

    reg_file i1 (clk, rs1, rs2, write_ena, rd, write_value, rs1_read, rs2_read);

endmodule
