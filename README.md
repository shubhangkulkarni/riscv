# Single Cycle RISCV32I Core

## Testing
In order to test the working, please load the instructions into the code.hex file and compile all the .v files in the 'final' folder. After execution, waveform will be saved in 'riscv-singlecycle.vcd'. 

### Basic info
1. Standard 32 4byte regs
2. 64 4byte words for instruction and data memory

Note: Currently supports all riscv32i instructions (as per the RISCV_CARD.pdf file) except U-type, ecall, ebreak, and the non-word versions of load and store. 
