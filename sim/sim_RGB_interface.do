vsim -voptargs=+acc work.matrix_RGB_interface_tb(sim) -t ps
mem load -infile ram_128x16_6bit.hex -format hex /matrix_RGB_interface_tb/DUT/half_panel_row_frame_buffers(0)/ram_u_panelrowX
mem load -infile ram_128x16_6bit.hex -format hex /matrix_RGB_interface_tb/DUT/half_panel_row_frame_buffers(0)/ram_l_panelrowX
mem load -infile ram_128x16_6bit.hex -format hex /matrix_RGB_interface_tb/DUT/half_panel_row_frame_buffers(1)/ram_u_panelrowX
mem load -infile ram_128x16_6bit.hex -format hex /matrix_RGB_interface_tb/DUT/half_panel_row_frame_buffers(1)/ram_l_panelrowX
mem load -infile ram_128x16_6bit.hex -format hex /matrix_RGB_interface_tb/DUT/half_panel_row_frame_buffers(2)/ram_u_panelrowX
mem load -infile ram_128x16_6bit.hex -format hex /matrix_RGB_interface_tb/DUT/half_panel_row_frame_buffers(2)/ram_l_panelrowX
mem load -infile ram_128x16_6bit.hex -format hex /matrix_RGB_interface_tb/DUT/half_panel_row_frame_buffers(3)/ram_u_panelrowX
mem load -infile ram_128x16_6bit.hex -format hex /matrix_RGB_interface_tb/DUT/half_panel_row_frame_buffers(3)/ram_l_panelrowX

do wave_RGB_interface.do

run 3ms