# RISCV32I Core
## Testing
In order to test the working, please load the instructions into the code.hex file and compile all the .v files in the 'final' folder. After execution, waveform will be saved in 'riscv-singlecycle.vcd' or 'riscv-pipeline.vcd' for single cycle and pipelined versions respectively. 

### Basic info
1. Standard 32 4byte regs
2. 32k 1byte words for instruction and data memory
3. The pipelined version uses a basic 'always not-taken' branch prediction as of now. To be updated soon.
4. Stall detection, forwarding (WB-to-EX, and MEM-to-EX) and flush in case of wrong branch prediction implemented.
5. Tested with the standard riscv-tests repo - passes all tests (find changes made in the problems_encountered.txt file - roughly written)

Note: Currently supports all riscv32i instructions (as per the RISCV_CARD.pdf file) except U-type, ecall, ebreak, and the non-word versions of load and store. 


