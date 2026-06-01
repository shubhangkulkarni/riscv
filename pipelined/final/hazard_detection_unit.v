module hazard_detection_unit (input [4:0] rs1, input [4:0] rs2, input ID_EX_mem_read, input [4:0] ID_EX_rd, output stall_detected);

    assign stall_detected = (ID_EX_mem_read & (ID_EX_rd==rs1 | ID_EX_rd==rs2) & ID_EX_rd != 5'd0);

endmodule
