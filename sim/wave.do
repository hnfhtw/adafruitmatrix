onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /matrix_tb/DUT/s_data_o(5)
add wave -noupdate /matrix_tb/DUT/s_data_o(4)
add wave -noupdate /matrix_tb/DUT/s_data_o(3)
add wave -noupdate /matrix_tb/DUT/s_data_o(2)
add wave -noupdate /matrix_tb/DUT/s_data_o(1)
add wave -noupdate /matrix_tb/DUT/s_data_o(0)
add wave -noupdate /matrix_tb/DUT/s_lat_o(0)
add wave -noupdate /matrix_tb/DUT/s_oe_o(0)
add wave -noupdate /matrix_tb/DUT/s_clk_o(0)
add wave -noupdate /matrix_tb/DUT/s_row_o(3)
add wave -noupdate /matrix_tb/DUT/s_row_o(2)
add wave -noupdate /matrix_tb/DUT/s_row_o(1)
add wave -noupdate /matrix_tb/DUT/s_row_o(0)
add wave -noupdate /matrix_tb/DUT/ctrl/s_clk_i
add wave -noupdate -radix unsigned /matrix_tb/DUT/ctrl/s_addr_o
add wave -noupdate -radix unsigned /matrix_tb/DUT/ctrl/s_cnt_pxl
add wave -noupdate -radix unsigned /matrix_tb/DUT/ctrl/s_cnt_pan
add wave -noupdate -radix unsigned /matrix_tb/DUT/ctrl/s_cnt_bit
add wave -noupdate -radix unsigned /matrix_tb/DUT/ctrl/s_cnt_row
add wave -noupdate -radix unsigned /matrix_tb/DUT/ctrl/s_sel
add wave -noupdate /matrix_tb/DUT/ctrl/s_lat(0)
add wave -noupdate /matrix_tb/DUT/ctrl/s_oe(0)
add wave -noupdate -radix unsigned /matrix_tb/DUT/ctrl/s_row
add wave -noupdate /matrix_tb/DUT/s_we
add wave -noupdate /matrix_tb/DUT/s_we_i
add wave -noupdate /matrix_tb/DUT/s_waddr_i
add wave -noupdate /matrix_tb/DUT/s_waddr
add wave -noupdate /matrix_tb/DUT/s_wclk_i
add wave -noupdate /matrix_tb/DUT/half_panel_row_frame_buffers(0)/ram_u_panelrowX/ram
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 4} {655957001 ps} 0} {{Cursor 5} {1976980000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 444
configure wave -valuecolwidth 139
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 24000
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {648422572 ps} {663108666 ps}
