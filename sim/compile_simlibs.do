# create base library setup
vlib ./simlib
vlib ./simlib/work
vlib ./work

vmap work simlib/work

#create specific lib setup and compile

vlib ./simlib/altera_mf
vmap altera_mf ./simlib/altera_mf
vcom     "$env(QUARTUS_INSTALL_DIR)/eda/sim_lib/altera_mf_components.vhd"            -work altera_mf
vcom     "$env(QUARTUS_INSTALL_DIR)/eda/sim_lib/altera_mf.vhd"                       -work altera_mf

vlib ./simlib/altera_mf_ver
vmap altera_mf_ver ./simlib/altera_mf_ver 
vlog    "$env(QUARTUS_INSTALL_DIR)/eda/sim_lib/altera_mf.v"                          -work altera_mf_ver

vlib ./simlib/altera_lnsim
vmap altera_lnsim ./simlib/altera_lnsim
vcom     "$env(QUARTUS_INSTALL_DIR)/eda/sim_lib/altera_lnsim_components.vhd"         -work altera_lnsim
vlog -sv "$env(QUARTUS_INSTALL_DIR)/eda/sim_lib/mentor/altera_lnsim_for_vhdl.sv"     -work altera_lnsim

## Only needed when using altera primitive components

#vlib ./simlib/altera
#vmap altera ./simlib/altera
#vcom     "$env(QUARTUS_INSTALL_DIR)/eda/sim_lib/altera_primitives_components.vhd"    -work altera
#vcom     "$env(QUARTUS_INSTALL_DIR)/eda/sim_lib/altera_primitives.vhd"               -work altera

#vlib ./simlib/cyclonev
#vmap cyclonev ./simlib/cyclonev
#vcom     "$env(QUARTUS_INSTALL_DIR)/eda/sim_lib/cyclonev_components.vhd"             -work cyclonev
#vcom     "$env(QUARTUS_INSTALL_DIR)/eda/sim_lib/cyclonev_atoms.vhd"                  -work cyclonev

