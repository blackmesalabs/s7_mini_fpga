# Pinout file for Black Mesa Labs' Spartan7 M2 Board
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_100m_IBUF] 

# Config PROM. Note spi_sck handled by STARTUPE2 hard IP
set_property PACKAGE_PIN B11 [get_ports {spi_mosi}]
set_property PACKAGE_PIN B12 [get_ports {spi_miso}]
set_property PACKAGE_PIN C11 [get_ports {spi_cs_l}]
# set_property PACKAGE_PIN A8  [get_ports {spi_sck}]

# Bootloader Pinout for BML Spartan7 M2 and Mini Boards

# S7 Mini Board
set_property PACKAGE_PIN A10 [get_ports {rst_l}]
set_property PACKAGE_PIN L5  [get_ports {clk_100m}]
set_property PACKAGE_PIN A13 [get_ports {ftdi[0]}]
set_property PACKAGE_PIN A12 [get_ports {ftdi[1]}]
set_property PACKAGE_PIN A5  [get_ports {ftdi[2]}]
set_property PACKAGE_PIN B5  [get_ports {ftdi[3]}]
set_property PACKAGE_PIN D3  [get_ports {j1_l}]
set_property PACKAGE_PIN A4  [get_ports {j2_l}]
set_property PACKAGE_PIN D14 [get_ports {led1}]
set_property PACKAGE_PIN C14 [get_ports {led2}]

set_property IOSTANDARD LVCMOS33 [get_ports rst_l]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100m]
set_property IOSTANDARD LVCMOS33 [get_ports j1_l]
set_property IOSTANDARD LVCMOS33 [get_ports j2_l]
set_property IOSTANDARD LVCMOS33 [get_ports led1]
set_property IOSTANDARD LVCMOS33 [get_ports led2]
set_property IOSTANDARD LVCMOS33 [get_ports {ftdi[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_*}]

set_property PULLUP     TRUE     [get_ports rst_l]
set_property PULLUP     TRUE     [get_ports clk_100m]
set_property PULLUP     TRUE     [get_ports j1_l]
set_property PULLUP     TRUE     [get_ports j2_l]
set_property PULLUP     TRUE     [get_ports led1]
set_property PULLUP     TRUE     [get_ports led2]
set_property PULLUP     TRUE     [get_ports {ftdi[*]}]
set_property PULLUP     TRUE     [get_ports {spi_*]}]

set_property DRIVE      8        [get_ports led1 ]
set_property DRIVE      8        [get_ports led2 ]
set_property SLEW       SLOW     [get_ports led1 ]
set_property SLEW       SLOW     [get_ports led2 ]


# Example: Note defaults to TRUE ( low performance )
set_property IBUF_LOW_PWR FALSE  [get_ports j1_l ]


# HR Banks mA Ranges     HP Banks mA Ranges
# LVCMOS33 4,8,12,16
# LVCMOS25 4,8,12,16     
# LVCMOS18 4,8,12,16,24  2,4,6,8,12,16
# LVCMOS15 4,8,12,16     2,4,6,8,12,16
# LVCMOS12 4,8,12        2,4,6,8
