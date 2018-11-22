################################################
# Set design name and device
set      design_name top
#set      device      xc7s50ftgb196-1
set      device      xc7s25ftgb196-1
set_part $device


################################################
# Create compilation report directory
set rep_dir ./reports
file mkdir $rep_dir
set tmp_dir ./temp
file mkdir $tmp_dir

################################################
# Read in source files
source top_rtl_list.tcl

################################################
# Read in Vivado IP
#read_ip [ glob ./IP/*/*.xci ]
# If auto upgrading Vivado IP then uncomment
#foreach ip [get_ips *] {
#   set locked  [get_property IS_LOCKED        [get_ips $ip]]
#   set upgrade [get_property UPGRADE_VERSIONS [get_ips $ip]]
#   if {$locked && $upgrade != ""} {
#      upgrade_ip [get_ips $ip]
#      generate_target all [get_ips $ip]
#      synth_ip [ get_ips $ip]}
#}
#synth_ip [get_ips *]


################################################
# Read in timing constraints before synthesis
read_xdc ./${design_name}_timing.xdc

################################################
# Synthesize
synth_design -top $design_name -part $device -fsm_extraction off
write_checkpoint -force $tmp_dir/post_synth.dcp
report_timing_summary -file $rep_dir/post_synth_timing_summary.rpt
#stop

#set rts [report_timing_summary -no_header -no_detailed_paths -return_string]
#if {! [string match -nocase {*timing constraints are met*} $rts]} {
#  send_msg_id showstopper-0 error "ERROR: Synth didn't make timing. Abort!!"
#  return -code error
#}

################################################
# Read in physical constraints before placement
read_xdc ./${design_name}_physical.xdc


################################################
# Pre-place optimization
opt_design


################################################
# Power optimization : See UG904
power_opt_design -verbose

write_checkpoint -force $tmp_dir/post_opt_design.dcp
report_timing_summary -file $rep_dir/post_opt_design_timing_summary.rpt

#set rts [report_timing_summary -no_header -no_detailed_paths -return_string]
#if {! [string match -nocase {*timing constraints are met*} $rts]} {
#  send_msg_id showstopper-0 error "ERROR: Map didn't make timing. Abort!!"
#  return -code error
#}

################################################
# Place
# For better timing results
place_design -directive Explore
# place_design

write_checkpoint -force $tmp_dir/post_place_design.dcp
report_timing_summary -file $rep_dir/post_place_design_timing_summary.rpt


################################################
# Post-place optimization
#phys_opt_design
#write_checkpoint -force $tmp_dir/post_phys_opt_design
#report_timing_summary -file $rep_dir/post_phys_opt_design_timing_summary.rpt

################################################
# Route
# For better timing results
route_design -directive Explore
# route_design
write_checkpoint -force $tmp_dir/post_route_design
#report_timing_summary -file $rep_dir/post_route_design_timing_summary.rpt

#set rts [report_timing_summary -no_header -no_detailed_paths -return_string]
#if {! [string match -nocase {*timing constraints are met*} $rts]} {
#  send_msg_id showstopper-0 error "ERROR: Route didn't make timing. Abort!!"
#  return -code error
#}

################################################
# Report
# report_timing -sort_by group -max_paths 20 -path_type summary -file $rep_dir/p
report_timing_summary -file $rep_dir/post_route_timing_summary.rpt
report_timing -sort_by group -max_paths 20  -file $rep_dir/post_route_timing_worst.rpt
report_clock_utilization -file $rep_dir/post_route_clock_util.rpt
report_utilization -file $rep_dir/post_route_util.rpt
report_power -file $rep_dir/post_route_pwr.rpt
report_drc -file $rep_dir/post_route_drc.rpt
report_io  -file $rep_dir/post_route_io.rpt
report_datasheet -file $rep_dir/post_route_datasheets.rpt

check_timing -file $rep_dir/post_route_timing_check.rpt

################################################
# Bitstream
#set_property config_mode                        SPIx4         [current_design]
#set_property BITSTREAM.CONFIG.USERID            0X02754001    [current_design]
#set_property BITSTREAM.STARTUP.DONE_CYCLE       6             [current_design]
#set_property BITSTREAM.STARTUP.GWE_CYCLE        5             [current_design]
#set_property BITSTREAM.STARTUP.GTS_CYCLE        4             [current_design]
# 32bit ADDR is for 128Mb and greater
#set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR    YES           [current_design]
#set_property BITSTREAM.CONFIG.SPI_BUSWIDTH      4             [current_design]
#set_property BITSTREAM.CONFIG.CONFIGFALLBACK    ENABLE        [current_design]
#set_property BITSTREAM.CONFIG.TIMER_CFG         0X00079239    [current_design]
#set_property BITSTREAM.CONFIG.OVERTEMPPOWERDOWN ENABLE        [current_design]
#set_property BITSTREAM.GENERAL.COMPRESS         TRUE          [current_design]

#set_property CONFIG_MODE                        SPIx1         [current_design]
#set_property CONFIG_VOLTAGE                     3.3           [current_design]
#set_property BITSTREAM.GENERAL.COMPRESS         FALSE         [current_design]
#set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN  DISABLE       [current_design]
#set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR    No            [current_design]
#set_property BITSTREAM.CONFIG.SPI_BUSWIDTH      1             [current_design]
##set_property BITSTREAM.CONFIG.SPI_FALL_EDGE     YES           [current_design]
#set_property BITSTREAM.CONFIG.SPI_FALL_EDGE     NO            [current_design]
#set_property BITSTREAM.CONFIG.M0PIN             PULLNONE      [current_design]
#set_property BITSTREAM.CONFIG.M1PIN             PULLNONE      [current_design]
#set_property BITSTREAM.CONFIG.M2PIN             PULLNONE      [current_design]
#set_property BITSTREAM.CONFIG.TCKPIN            PULLNONE      [current_design]
#set_property BITSTREAM.CONFIG.TCKPIN            PULLNONE      [current_design]
#set_property BITSTREAM.CONFIG.TDIPIN            PULLNONE      [current_design]
#set_property BITSTREAM.CONFIG.TMSPIN            PULLNONE      [current_design]
#set_property BITSTREAM.CONFIG.DRIVEDONE         NO            [current_design]
#set_property BITSTREAM.CONFIG.DONEPIN           PULLNONE      [current_design]
#set_property BITSTREAM.CONFIG.INITPIN           PULLNONE      [current_design]

# NONE|0x<8-digit hex>|TIMESTAMP
#set_property BITSTREAM.CONFIG.USR_ACCESS         0xaabbccdd    [current_design]
set_property BITSTREAM.CONFIG.USR_ACCESS         0x12345678    [current_design]

set_property CONFIG_VOLTAGE                     3.3            [current_design]
set_property CFGBVS                             VCCO           [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE        16             [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR    No             [current_design]

set_property SEVERITY {Warning} [get_drc_checks NSTD-1]

write_bitstream -force ${design_name}.bit
write_bitstream -force -bin_file ${design_name} 
write_cfgmem    -force -format MCS -size 8 -loadbit "up 0x0 top.bit" -interface SPIx1 top


# Open Vivado GUI using routed database if running vivado -mode tcl
#start_gui

# Exit TCL shell
exit

