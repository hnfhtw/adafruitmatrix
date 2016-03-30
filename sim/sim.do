vsim -voptargs=+acc work.matrix_tb(sim) -t ps

add wave -position insertpoint  \
sim:/matrix_tb/DUT/s_clk_i \
sim:/matrix_tb/DUT/s_reset_n_i \
sim:/matrix_tb/DUT/s_data_o \
sim:/matrix_tb/DUT/s_row_o \
sim:/matrix_tb/DUT/s_lat_o \
sim:/matrix_tb/DUT/s_oe_o \
sim:/matrix_tb/DUT/s_clk_o \
sim:/matrix_tb/DUT/s_addr \
sim:/matrix_tb/DUT/s_sel \
sim:/matrix_tb/DUT/s_ram_u \
sim:/matrix_tb/DUT/s_ram_l \
sim:/matrix_tb/DUT/s_row \
sim:/matrix_tb/DUT/s_reset_n \
sim:/matrix_tb/DUT/s_clk \
sim:/matrix_tb/DUT/s_locked \
sim:/matrix_tb/DUT/s_reset \
sim:/matrix_tb/DUT/C_RED_OFFSET \
sim:/matrix_tb/DUT/C_GREEN_OFFSET \
sim:/matrix_tb/DUT/C_BLUE_OFFSET \
sim:/matrix_tb/DUT/C_RED_0 \
sim:/matrix_tb/DUT/C_GREEN_0 \
sim:/matrix_tb/DUT/C_BLUE_0 \
sim:/matrix_tb/DUT/C_RED_1 \
sim:/matrix_tb/DUT/C_GREEN_1 \
sim:/matrix_tb/DUT/C_BLUE_1

run 33.3ms