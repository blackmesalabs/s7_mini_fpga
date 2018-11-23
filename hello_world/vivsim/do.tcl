open_vcd
log_vcd [get_objects -r * ]
add_force rst_l 0
add_force j1_l  1
add_force j2_l  1
add_force clk_100m_pin {0 0ns} {1 5ns} -repeat_every 10ns
run 50ns
add_force rst_l 1
run 100ns
close_vcd
quit
