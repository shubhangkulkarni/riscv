# RISCV32I Core
## Testing
In order to test the working, please load the instructions into the code.hex file and compile all the .v files in the 'final' folder. After execution, waveform will be saved in 'riscv-singlecycle.vcd' or 'riscv-pipeline.vcd' for single cycle and pipelined versions respectively. 

### Basic info
1. Standard 32 4byte regs
2. 32k 1byte words for instruction and data memory
3. The pipelined version uses a basic 'always not-taken' branch prediction as of now. To be updated soon.
4. Stall detection, forwarding (WB-to-EX, and MEM-to-EX) and flush in case of wrong branch prediction implemented.
5. Tested with the standard riscv-tests repo - passes all tests (find changes made in the problems_encountered.txt file - roughly written)
6. Implemented exception handling for ecall, ebreak, illegal instruction, misaligned instruction/data address (both load and store), with mtvec, mepc, and mcause CSRs (read, write and return with mret).
7. Implemented GShare branch prediction with a 10bit global history registor, corresponding to a table of 2-bit counters with 1024 entries, indexed by the XOR of the global history reg and the 10 LSB of the instruction address (PC/inst_addr). The BTB (Branch Table Buffer) has 128 entries, direct mapped using tags (23 bit tag + 7 bit index + 2bits ignored since addresses are 4bytes). 




