-- ADAFRUITMATRIX -- FPGA design to drive a chain of 32x32 RGB LED Matrices
--
-- Copyright (C) 2016  Christian Fibich
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

library ieee;
use ieee.std_logic_1164.all;
library work;
use work.cfg_pkg.all;
-------------------------------------------------------------------------------

entity matrix_tb is

end entity matrix_tb;

-------------------------------------------------------------------------------

architecture sim of matrix_tb is

    -- component ports
    signal s_clk_i     : std_logic := '1';
    signal s_reset_n_i : std_logic := '0';
    signal s_data_o    : std_logic_vector(5 downto 0);
    signal s_row_o     : std_logic_vector(C_ROW_BITS-1 downto 0);
    signal s_lat_o     : std_logic;
    signal s_oe_o      : std_logic;
    signal s_wobble_i  : std_logic;

    -- clock
    signal Clk : std_logic := '1';

begin  -- architecture sim

    -- component instantiation
    DUT : entity work.matrix
        port map (
            s_clk_i     => s_clk_i,
            s_reset_n_i => s_reset_n_i,
            s_data_o    => s_data_o,
            s_row_o     => s_row_o,
            s_lat_o     => s_lat_o,
            s_oe_o      => s_oe_o,
            s_wobble_i  => s_wobble_i);

    -- clock generation
    s_clk_i     <= not s_clk_i after 10 ns;
    s_reset_n_i <= '1'         after 5 ns;
    s_wobble_i  <= '1';

end architecture sim;

-------------------------------------------------------------------------------

configuration matrix_tb_sim_cfg of matrix_tb is
    for sim
    end for;
end matrix_tb_sim_cfg;

-------------------------------------------------------------------------------
