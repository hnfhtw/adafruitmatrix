vsim -voptargs=+acc work.matrix_tb(sim) -t ps
mem load -infile newaddress_128x32_upper.hex -format hex /matrix_tb/DUT/half_panel_row_frame_buffers(0)/testram_u_panelrowX
mem load -infile newaddress_128x32_lower.hex -format hex /matrix_tb/DUT/half_panel_row_frame_buffers(0)/testram_l_panelrowX
mem load -infile newaddress_128x32_upper.hex -format hex /matrix_tb/DUT/half_panel_row_frame_buffers(1)/testram_u_panelrowX
mem load -infile newaddress_128x32_lower.hex -format hex /matrix_tb/DUT/half_panel_row_frame_buffers(1)/testram_l_panelrowX
mem load -infile newaddress_128x32_upper.hex -format hex /matrix_tb/DUT/half_panel_row_frame_buffers(2)/testram_u_panelrowX
mem load -infile newaddress_128x32_lower.hex -format hex /matrix_tb/DUT/half_panel_row_frame_buffers(2)/testram_l_panelrowX
mem load -infile newaddress_128x32_upper.hex -format hex /matrix_tb/DUT/half_panel_row_frame_buffers(3)/testram_u_panelrowX
mem load -infile newaddress_128x32_lower.hex -format hex /matrix_tb/DUT/half_panel_row_frame_buffers(3)/testram_l_panelrowX

do wave.do

run 100us