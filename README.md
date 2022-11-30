# RISCV_RV32I

This is a simplified version of the design given at https://github.com/nobotro/fpga_riscv_cpu

For a more professional design, please see https://github.com/YosysHQ/picorv32

Both github repos have information about using the GNU RISC-V C/C++ compiler, compiling
a C/C++ project, and running it on the system instantiated on the FPGA.

The C language standard requires all global variables to be initialized before the main() starts. 
The first github repo, does not implement this requirement. The second more professional one does
implement that requirement.

