This is an example design for testing the external 64Mbit HyperRAM DRAM  
on the "S7 Mini" board.

[ Building FPGA Design ]
1) cd .\hyperram\xilinx
2) go.bat

[ Programming FPGA PROM using Digilent HS2 JTAG and Vivado ]
1) Launch Vivado
2) Select "Open Hardware Manager"
3) "Open Target", "Auto Connect"
4) Right-Click on "XC7S25_0(1)"
5) Select "Add Configuration Memory Device"
6) Select Micron, 64Mb for Mfr,Density
7) Select N25Q64-3.3V-SPI-X1_X2_X4, OK
8) OK for "Do you want to program..now?"
9) Configuration File = hyperram\xilinx\top.bin, OK
10) Device should now program. Close Vivado and Power Cycle to run.


Kevin Hubbard @ Black Mesa Labs 2018.11.25
