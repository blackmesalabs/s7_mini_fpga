# Pinout file for Black Mesa Labs' Spartan7 M2 Board
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_100m_pin_IBUF] 

# Config PROM. Note spi_sck handled by STARTUPE2 hard IP
set_property PACKAGE_PIN B11 [get_ports {spi_mosi}]
set_property PACKAGE_PIN B12 [get_ports {spi_miso}]
set_property PACKAGE_PIN C11 [get_ports {spi_cs_l}]
# set_property PACKAGE_PIN A8  [get_ports {spi_sck}]

# S7 Mini Board
set_property PACKAGE_PIN A10 [get_ports {rst_l}]
set_property PACKAGE_PIN L5  [get_ports {clk_100m_pin}]
set_property PACKAGE_PIN A13 [get_ports {ftdi[0]}]
set_property PACKAGE_PIN A12 [get_ports {ftdi[1]}]
set_property PACKAGE_PIN A5  [get_ports {ftdi[2]}]
set_property PACKAGE_PIN B5  [get_ports {ftdi[3]}]
set_property PACKAGE_PIN D3  [get_ports {j1_l}]
set_property PACKAGE_PIN A4  [get_ports {j2_l}]
set_property PACKAGE_PIN D14 [get_ports {led1}]
set_property PACKAGE_PIN C14 [get_ports {led2}]

# S7 Mini 32 DIP I/O and 64 50mil I/O (shared)
set_property PACKAGE_PIN A2 [get_ports {port_a[0]}]
set_property PACKAGE_PIN B3 [get_ports {port_a[4]}]
set_property PACKAGE_PIN C4 [get_ports {port_a[1]}]
set_property PACKAGE_PIN C5 [get_ports {port_a[5]}]
set_property PACKAGE_PIN D4 [get_ports {port_a[2]}]
set_property PACKAGE_PIN E4 [get_ports {port_a[6]}]
set_property PACKAGE_PIN A3 [get_ports {port_a[3]}]
set_property PACKAGE_PIN C3 [get_ports {port_a[7]}]

set_property PACKAGE_PIN B2 [get_ports {port_b[0]}]
set_property PACKAGE_PIN B1 [get_ports {port_b[4]}]
set_property PACKAGE_PIN C1 [get_ports {port_b[1]}]
set_property PACKAGE_PIN D1 [get_ports {port_b[5]}]
set_property PACKAGE_PIN D2 [get_ports {port_b[2]}]
set_property PACKAGE_PIN E2 [get_ports {port_b[6]}]
set_property PACKAGE_PIN F1 [get_ports {port_b[3]}]
set_property PACKAGE_PIN G1 [get_ports {port_b[7]}]

set_property PACKAGE_PIN F3 [get_ports {port_c[0]}]
set_property PACKAGE_PIN F2 [get_ports {port_c[4]}]
set_property PACKAGE_PIN F4 [get_ports {port_c[1]}]
set_property PACKAGE_PIN G4 [get_ports {port_c[5]}]
set_property PACKAGE_PIN H3 [get_ports {port_c[2]}]
set_property PACKAGE_PIN H4 [get_ports {port_c[6]}]
set_property PACKAGE_PIN J3 [get_ports {port_c[3]}]
set_property PACKAGE_PIN J4 [get_ports {port_c[7]}]

set_property PACKAGE_PIN K3 [get_ports {port_d[0]}]
set_property PACKAGE_PIN K4 [get_ports {port_d[4]}]
set_property PACKAGE_PIN L2 [get_ports {port_d[1]}]
set_property PACKAGE_PIN L3 [get_ports {port_d[5]}]
set_property PACKAGE_PIN M2 [get_ports {port_d[2]}]
set_property PACKAGE_PIN M3 [get_ports {port_d[6]}]
set_property PACKAGE_PIN M4 [get_ports {port_d[3]}]
set_property PACKAGE_PIN M5 [get_ports {port_d[7]}]

set_property PACKAGE_PIN E11 [get_ports {port_h[0]}]
set_property PACKAGE_PIN C12 [get_ports {port_h[4]}]
set_property PACKAGE_PIN C10 [get_ports {port_h[1]}]
set_property PACKAGE_PIN D10 [get_ports {port_h[5]}]
set_property PACKAGE_PIN D12 [get_ports {port_h[2]}]
set_property PACKAGE_PIN D13 [get_ports {port_h[6]}]
set_property PACKAGE_PIN E13 [get_ports {port_h[3]}]
set_property PACKAGE_PIN F13 [get_ports {port_h[7]}]

set_property PACKAGE_PIN F14 [get_ports {port_g[0]}]
set_property PACKAGE_PIN G14 [get_ports {port_g[4]}]
set_property PACKAGE_PIN E12 [get_ports {port_g[1]}]
set_property PACKAGE_PIN F12 [get_ports {port_g[5]}]
set_property PACKAGE_PIN F11 [get_ports {port_g[2]}]
set_property PACKAGE_PIN G11 [get_ports {port_g[6]}]
set_property PACKAGE_PIN H12 [get_ports {port_g[3]}]
set_property PACKAGE_PIN H11 [get_ports {port_g[7]}]

set_property PACKAGE_PIN H13 [get_ports {port_f[0]}]
set_property PACKAGE_PIN H14 [get_ports {port_f[4]}]
set_property PACKAGE_PIN J13 [get_ports {port_f[1]}]
set_property PACKAGE_PIN J14 [get_ports {port_f[5]}]
set_property PACKAGE_PIN L12 [get_ports {port_f[2]}]
set_property PACKAGE_PIN L13 [get_ports {port_f[6]}]
set_property PACKAGE_PIN L14 [get_ports {port_f[3]}]
set_property PACKAGE_PIN M13 [get_ports {port_f[7]}]

set_property PACKAGE_PIN J12 [get_ports {port_e[0]}]
set_property PACKAGE_PIN J11 [get_ports {port_e[4]}]
set_property PACKAGE_PIN M14 [get_ports {port_e[1]}]
set_property PACKAGE_PIN N14 [get_ports {port_e[5]}]
set_property PACKAGE_PIN K12 [get_ports {port_e[2]}]
set_property PACKAGE_PIN K11 [get_ports {port_e[6]}]
set_property PACKAGE_PIN M12 [get_ports {port_e[3]}]
set_property PACKAGE_PIN M11 [get_ports {port_e[7]}]



set_property PACKAGE_PIN P2   [get_ports {hr_cs_l}]
set_property PACKAGE_PIN P3   [get_ports {hr_rst_l}]
set_property PACKAGE_PIN N1   [get_ports {hr_ck}]
set_property PACKAGE_PIN P4   [get_ports {hr_rwds}]
set_property PACKAGE_PIN N4   [get_ports {hr_dq[2]}]
set_property PACKAGE_PIN P12  [get_ports {hr_dq[1]}]
set_property PACKAGE_PIN P11  [get_ports {hr_dq[0]}]
set_property PACKAGE_PIN P10  [get_ports {hr_dq[3]}]
set_property PACKAGE_PIN P5   [get_ports {hr_dq[4]}]
set_property PACKAGE_PIN P13  [get_ports {hr_dq[7]}]
set_property PACKAGE_PIN N11  [get_ports {hr_dq[6]}]
set_property PACKAGE_PIN N10  [get_ports {hr_dq[5]}]

# HyperRAM IOB types
set_property IOSTANDARD LVCMOS33 [get_ports {hr_*}]
set_property SLEW       FAST     [get_ports {hr_*}]
set_property DRIVE      16       [get_ports {hr_*}]

set_property IOSTANDARD LVCMOS33 [get_ports rst_l]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100m_pin]
set_property IOSTANDARD LVCMOS33 [get_ports j1_l]
set_property IOSTANDARD LVCMOS33 [get_ports j2_l]
set_property IOSTANDARD LVCMOS33 [get_ports led1]
set_property IOSTANDARD LVCMOS33 [get_ports led2]
set_property IOSTANDARD LVCMOS33 [get_ports {ftdi[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_*}]
set_property IOSTANDARD LVCMOS33 [get_ports {port_*}]

set_property PULLUP     TRUE     [get_ports rst_l]
set_property PULLUP     TRUE     [get_ports clk_100m_pin]
set_property PULLUP     TRUE     [get_ports j1_l]
set_property PULLUP     TRUE     [get_ports j2_l]
set_property PULLUP     TRUE     [get_ports {ftdi[*]}]
set_property PULLUP     TRUE     [get_ports {spi_*]}]
set_property PULLUP     TRUE     [get_ports {hr_cs_l}]
set_property PULLDOWN   TRUE     [get_ports {hr_rst_l}]

set_property DRIVE      16       [get_ports led1 ]
set_property DRIVE      16       [get_ports led2 ]
set_property SLEW       SLOW     [get_ports led1 ]
set_property SLEW       SLOW     [get_ports led2 ]


# HR Banks mA Ranges     HP Banks mA Ranges
# LVCMOS33 4,8,12,16
# LVCMOS25 4,8,12,16     
# LVCMOS18 4,8,12,16,24  2,4,6,8,12,16
# LVCMOS15 4,8,12,16     2,4,6,8,12,16
# LVCMOS12 4,8,12        2,4,6,8
