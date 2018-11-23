This is an example design for flashing the LEDs internally and externally
on the "S7 Mini" board.
For external LED connections, connect 1K resistor in series with LEDs to GND
on Port_A[3:0] pins.


[ Simulating Verilog Design ]
1) cd .\hello_world\vivsim
2) compile.bat
3) elaborate.bat
4) simulate.bat
5) Launch GTKwave.exe and open dump.vcd

[ Building FPGA Design ]
1) cd .\hello_world\xilinx
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
9) Configuration File = hello_world\xilinx\top.bin, OK
10) Device should now program. Close Vivado and Power Cycle to run.


Kevin Hubbard @ Black Mesa Labs 2018.11.23