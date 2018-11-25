################################################
# Set design name and device
set      design_name top
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
# Read in timing constraints before synthesis
read_xdc ./${design_name}_timing.xdc

################################################
# Synthesize
synth_design -top $design_name -part $device -fsm_extraction off
write_checkpoint -force $tmp_dir/post_synth.dcp
report_timing_summary -file $rep_dir/post_synth_timing_summary.rpt

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

################################################
# Place for better timing results
place_design -directive Explore
write_checkpoint -force $tmp_dir/post_place_design.dcp
report_timing_summary -file $rep_dir/post_place_design_timing_summary.rpt

################################################
# Post-place optimization
phys_opt_design
write_checkpoint -force $tmp_dir/post_phys_opt_design
report_timing_summary -file $rep_dir/post_phys_opt_design_timing_summary.rpt

################################################
# Route
route_design -directive Explore
write_checkpoint -force $tmp_dir/post_route_design


################################################
# Report
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
set_property BITSTREAM.CONFIG.USR_ACCESS        0x12345678     [current_design]
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

