onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /matrix_tb/DUT/s_clk_i
add wave -noupdate /matrix_tb/DUT/s_reset_n_i
add wave -noupdate -radix unsigned /matrix_tb/DUT/ctrl/s_cnt_pxl
add wave -noupdate -radix unsigned /matrix_tb/DUT/ctrl/s_cnt_pan
add wave -noupdate -radix unsigned /matrix_tb/DUT/ctrl/s_cnt_bit
add wave -noupdate -radix unsigned /matrix_tb/DUT/ctrl/s_cnt_row
add wave -noupdate -radix unsigned -childformat {{/matrix_tb/DUT/s_raddr(10) -radix unsigned} {/matrix_tb/DUT/s_raddr(9) -radix unsigned} {/matrix_tb/DUT/s_raddr(8) -radix unsigned} {/matrix_tb/DUT/s_raddr(7) -radix unsigned} {/matrix_tb/DUT/s_raddr(6) -radix unsigned} {/matrix_tb/DUT/s_raddr(5) -radix unsigned} {/matrix_tb/DUT/s_raddr(4) -radix unsigned} {/matrix_tb/DUT/s_raddr(3) -radix unsigned} {/matrix_tb/DUT/s_raddr(2) -radix unsigned} {/matrix_tb/DUT/s_raddr(1) -radix unsigned} {/matrix_tb/DUT/s_raddr(0) -radix unsigned}} -subitemconfig {/matrix_tb/DUT/s_raddr(10) {-height 15 -radix unsigned} /matrix_tb/DUT/s_raddr(9) {-height 15 -radix unsigned} /matrix_tb/DUT/s_raddr(8) {-height 15 -radix unsigned} /matrix_tb/DUT/s_raddr(7) {-height 15 -radix unsigned} /matrix_tb/DUT/s_raddr(6) {-height 15 -radix unsigned} /matrix_tb/DUT/s_raddr(5) {-height 15 -radix unsigned} /matrix_tb/DUT/s_raddr(4) {-height 15 -radix unsigned} /matrix_tb/DUT/s_raddr(3) {-height 15 -radix unsigned} /matrix_tb/DUT/s_raddr(2) {-height 15 -radix unsigned} /matrix_tb/DUT/s_raddr(1) {-height 15 -radix unsigned} /matrix_tb/DUT/s_raddr(0) {-height 15 -radix unsigned}} /matrix_tb/DUT/s_raddr
add wave -noupdate /matrix_tb/DUT/s_ram_u
add wave -noupdate /matrix_tb/DUT/s_ram_l
add wave -noupdate -radix unsigned -childformat {{/matrix_tb/DUT/s_sel(2) -radix unsigned} {/matrix_tb/DUT/s_sel(1) -radix unsigned} {/matrix_tb/DUT/s_sel(0) -radix unsigned}} -subitemconfig {/matrix_tb/DUT/s_sel(2) {-height 15 -radix unsigned} /matrix_tb/DUT/s_sel(1) {-height 15 -radix unsigned} /matrix_tb/DUT/s_sel(0) {-height 15 -radix unsigned}} /matrix_tb/DUT/s_sel
add wave -noupdate /matrix_tb/DUT/s_data_o(5)
add wave -noupdate /matrix_tb/DUT/s_data_o(4)
add wave -noupdate /matrix_tb/DUT/s_data_o(3)
add wave -noupdate /matrix_tb/DUT/s_data_o(2)
add wave -noupdate /matrix_tb/DUT/s_data_o(1)
add wave -noupdate /matrix_tb/DUT/s_data_o(0)
add wave -noupdate /matrix_tb/DUT/s_clk_o(0)
add wave -noupdate /matrix_tb/DUT/s_lat_o(0)
add wave -noupdate /matrix_tb/DUT/s_oe_o(0)
add wave -noupdate /matrix_tb/DUT/s_row_o(3)
add wave -noupdate /matrix_tb/DUT/s_row_o(2)
add wave -noupdate /matrix_tb/DUT/s_row_o(1)
add wave -noupdate /matrix_tb/DUT/s_row_o(0)
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 4} {407060000 ps} 0} {{Cursor 5} {1976980000 ps} 0} {{Cursor 3} {717564666 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 250
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
WaveRestoreZoom {0 ps} {1459249152 ps}
