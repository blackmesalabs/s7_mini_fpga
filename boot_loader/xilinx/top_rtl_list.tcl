# Read in source files
#read_verilog [ glob ../src/*.v ]     # use glob if all .v files in src are desi
#read_vhdl    [ glob ../src/*.vhd ]   # use glob if all .vhd files in src are de
read_verilog ../src/top.v
read_verilog ../src/core.v
read_verilog ../src/ft232_xface.v
read_verilog ../src/iob_bidi.v
read_verilog ../src/mesa_id.v
read_verilog ../src/mesa_uart_phy.v
read_verilog ../src/mesa_uart.v
read_verilog ../src/mesa_tx_uart.v
read_verilog ../src/mesa_byte2ascii.v
read_verilog ../src/mesa_ascii2nibble.v
read_verilog ../src/mesa_core.v
read_verilog ../src/mesa_decode.v
read_verilog ../src/mesa2lb.v
read_verilog ../src/mesa2ctrl.v
read_verilog ../src/time_stamp.v
read_verilog ../src/spi_prom.v
read_verilog ../src/spi_byte2bit.v
read_verilog ../src/icap_ctrl.v
