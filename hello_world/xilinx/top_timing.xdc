create_clock -period 10.000 -name clk_100m -waveform {0.000 5.000} [get_ports clk_100m_pin]
set_input_jitter clk_100m 0.200
