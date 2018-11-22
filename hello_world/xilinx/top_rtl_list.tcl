# Read in source files
#read_verilog [ glob ../src/*.v ]     # use glob if all .v files in src are desi
#read_vhdl    [ glob ../src/*.vhd ]   # use glob if all .vhd files in src are de
read_verilog ../ip_src/pll_7series.v
read_verilog ../ip_src/cdc_reset.v
read_verilog ../ip_src/ft232_xface.v
read_verilog ../ip_src/iob_bidi.v
read_verilog ../ip_src/mesa_id.v
read_verilog ../ip_src/mesa_uart_phy.v
read_verilog ../ip_src/mesa_uart.v
read_verilog ../ip_src/mesa_tx_uart.v
read_verilog ../ip_src/mesa_byte2ascii.v
read_verilog ../ip_src/mesa_ascii2nibble.v
read_verilog ../ip_src/mesa_decode.v
read_verilog ../ip_src/mesa2lb.v
read_verilog ../ip_src/mesa2ctrl.v
read_verilog ../ip_src/spi_prom.v
read_verilog ../ip_src/spi_byte2bit.v
read_verilog ../ip_src/icap_ctrl.v
read_verilog ../ip_src/sump2.v
read_verilog ../ip_src/deep_sump.v
read_verilog ../ip_src/deep_sump_ram.v
read_verilog ../ip_src/deep_sump_fifo.v
read_verilog ../ip_src/deep_sump_hyperram.v
read_verilog ../ip_src/fifo_1024x108.v
read_verilog ../ip_src/fifo_2048x108.v
read_verilog ../ip_src/fifo_4096x108.v
read_verilog ../ip_src/hyper_xface_pll.v
read_verilog ../ip_src/hyper_xface_mux.v
read_verilog ../ip_src/hr_pll_example.v
read_verilog ../ip_src/xil_iddr.v
read_verilog ../ip_src/xil_oddr.v
read_verilog ../src/time_stamp.v
read_verilog ../src/core.v
read_verilog ../src/vga_timing.v
read_verilog ../src/vga_core.v
read_verilog ../src/top.v
