vsim -voptargs=+acc work.matrix_panel_control_tb(sim) -t ps
mem load -infile ram_128x16_6bit_2nd.hex -format hex /matrix_panel_control_tb/DUT/half_panel_row_frame_buffers(0)/ram_u_panelrowX
mem load -infile ram_128x16_6bit_2nd.hex -format hex /matrix_panel_control_tb/DUT/half_panel_row_frame_buffers(0)/ram_l_panelrowX
mem load -infile ram_128x16_6bit_2nd.hex -format hex /matrix_panel_control_tb/DUT/half_panel_row_frame_buffers(1)/ram_u_panelrowX
mem load -infile ram_128x16_6bit_2nd.hex -format hex /matrix_panel_control_tb/DUT/half_panel_row_frame_buffers(1)/ram_l_panelrowX
mem load -infile ram_128x16_6bit_2nd.hex -format hex /matrix_panel_control_tb/DUT/half_panel_row_frame_buffers(2)/ram_u_panelrowX
mem load -infile ram_128x16_6bit_2nd.hex -format hex /matrix_panel_control_tb/DUT/half_panel_row_frame_buffers(2)/ram_l_panelrowX
mem load -infile ram_128x16_6bit_2nd.hex -format hex /matrix_panel_control_tb/DUT/half_panel_row_frame_buffers(3)/ram_u_panelrowX
mem load -infile ram_128x16_6bit_2nd.hex -format hex /matrix_panel_control_tb/DUT/half_panel_row_frame_buffers(3)/ram_l_panelrowX

do wave_panel_control.do

run 20ms