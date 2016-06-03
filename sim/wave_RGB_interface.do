onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -height 20 -label s_wclk_i /matrix_RGB_interface_tb/DUT/s_wclk_i
add wave -noupdate -height 20 -label s_we_i /matrix_RGB_interface_tb/DUT/s_we_i
add wave -noupdate -height 20 -label s_waddr_i /matrix_RGB_interface_tb/DUT/s_waddr_i
add wave -noupdate -height 20 -label s_wdata_i /matrix_RGB_interface_tb/DUT/s_wdata_i
add wave -noupdate -height 20 -label s_we /matrix_RGB_interface_tb/DUT/s_we
add wave -noupdate -height 20 -label s_waddr /matrix_RGB_interface_tb/DUT/s_waddr
add wave -noupdate -height 20 -label s_wdata /matrix_RGB_interface_tb/DUT/s_wdata
add wave -noupdate -height 20 -label {RAM BUFF0 UPPER} /matrix_RGB_interface_tb/DUT/half_panel_row_frame_buffers(0)/ram_u_panelrowX/ram
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 4} {600583581 ps} 0} {{Cursor 5} {1976980000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 137
configure wave -valuecolwidth 150
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
WaveRestoreZoom {599961367 ps} {601305343 ps}
