-- ADAFRUITMATRIX -- FPGA design to drive combinations of 32x32 RGB LED Matrices
--
-- Copyright (C) 2016  Harald Netzer (Initial Version by Christian Fibich)
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

-- Testbench
-- Last modified: 01.04.2016

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-------------------------------------------------------------------------------

entity matrix_tb is

     generic 
	 (
		NO_PANEL_ROWS : natural := 4;					-- number of panel rows
		NO_PANEL_COLUMNS : natural := 4;				-- number of panel columns
		COLORDEPTH : natural := 8;						-- colordepth in Bit
		PIXEL_ROW_ADDRESS_BITS : natural := 4;		-- 4 address lines A-D for the pixel rows
		NO_PIXEL_COLUMNS_PER_PANEL : natural := 32	-- number of pixels in one row of one panel
	 );

end entity matrix_tb;

-------------------------------------------------------------------------------

architecture sim of matrix_tb is
	
	component matrix
	port(
        s_clk_i     : in  std_logic;
        s_reset_n_i : in  std_logic;
        s_data_o    : out std_logic_vector((NO_PANEL_ROWS*6) - 1 downto 0);                 -- RGB output to one row of 32x32 Panels (R0/R1, G0/G1, B0/B1)
        s_row_o     : out std_logic_vector((NO_PANEL_ROWS*PIXEL_ROW_ADDRESS_BITS)-1 downto 0);     							 -- Output to address lines DCBA (3 to 0)
        s_lat_o     : out std_logic_vector(NO_PANEL_ROWS-1 downto 0);						-- STB / LATCH output
        s_oe_o      : out std_logic_vector(NO_PANEL_ROWS-1 downto 0);						-- OE output
        s_wobble_i  : in  std_logic;
        s_clk_o     : out std_logic_vector(NO_PANEL_ROWS-1 downto 0);						-- CLK output
		  
		  -- input for RGB data decoder
		  s_data_i    : in std_logic_vector(3*COLORDEPTH-1 downto 0);		-- RGB data input to decoder for framebuffers
		  s_we_i      : in std_logic;													-- write enable input to decoder for framebuffers
		  s_waddr_i   : in std_logic_vector((natural(ceil(log2(real(NO_PANEL_COLUMNS)))) + PIXEL_ROW_ADDRESS_BITS + natural(ceil(log2(real(NO_PANEL_ROWS)))) + natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))) downto 0);	-- write address input to decoder for framebuffers (e.g. format at 4x4 panels: PP RRRRRRR XXXXX -> 14 Bit)
		  s_wclk_i    : in std_logic);
	end component;



    -- component ports
    signal s_clk_i     : std_logic := '1';
    signal s_reset_n_i : std_logic := '0';
    signal s_data_o    : std_logic_vector((NO_PANEL_ROWS*6) - 1 downto 0);
    signal s_row_o     : std_logic_vector((NO_PANEL_ROWS*PIXEL_ROW_ADDRESS_BITS)-1 downto 0);
    signal s_lat_o     : std_logic_vector(NO_PANEL_ROWS-1 downto 0);
    signal s_oe_o      : std_logic_vector(NO_PANEL_ROWS-1 downto 0);
    signal s_wobble_i  : std_logic;
	signal s_clk_o     : std_logic_vector(NO_PANEL_ROWS-1 downto 0);	
	signal s_data_i    : std_logic_vector(3*COLORDEPTH-1 downto 0) := (others => '0');
	signal s_we_i      : std_logic := '0';
	signal s_waddr_i   : std_logic_vector((natural(ceil(log2(real(NO_PANEL_COLUMNS)))) + PIXEL_ROW_ADDRESS_BITS + natural(ceil(log2(real(NO_PANEL_ROWS)))) + natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))) downto 0) := (others => '0');
	signal s_wclk_i    : std_logic := '1';
    -- clock
    signal Clk : std_logic := '1';

begin  -- architecture sim

    -- component instantiation
    DUT : entity work.matrix
		generic map (
			NO_PANEL_ROWS	=> 4,
			NO_PANEL_COLUMNS	=> 4,
			COLORDEPTH	=> 8,
			PIXEL_ROW_ADDRESS_BITS	=> 4,
			NO_PIXEL_COLUMNS_PER_PANEL	=> 32
		)
	
        port map (
            s_clk_i     => s_clk_i,
            s_reset_n_i => s_reset_n_i,
            s_data_o    => s_data_o,
            s_row_o     => s_row_o,
            s_lat_o     => s_lat_o,
            s_oe_o      => s_oe_o,
            s_wobble_i  => s_wobble_i,
			s_clk_o     => s_clk_o,
			s_data_i    => s_data_i,
			s_we_i      => s_we_i,
			s_waddr_i   => s_waddr_i,
			s_wclk_i    => s_wclk_i			
			);

    -- clock generation
    s_clk_i     <= not s_clk_i after 10 ns;
    s_reset_n_i <= '1'         after 5 ns;
    s_wobble_i  <= '1';
	s_wclk_i    <= not s_wclk_i after 50ns;
	
	-- PP TTT RRRR XXXXX
	p_decode_test : process
	begin
	    wait until falling_edge(s_wclk_i);
		s_we_i <= '1';
		s_waddr_i <= "01001000100011";
		s_data_i <= "111111110000000011111111";
		wait until falling_edge(s_wclk_i);
		s_we_i <= '0';
		wait until falling_edge(s_wclk_i);
		s_we_i <= '1';
		s_waddr_i <= "11101000101111";
		s_data_i <= "000000001111111100000000";
		wait until falling_edge(s_wclk_i);
		s_we_i <= '0';
		wait until falling_edge(s_wclk_i);
		s_we_i <= '1';
		s_waddr_i <= "11010111110000";
		s_data_i <= "000000000000000011111111";
		wait until falling_edge(s_wclk_i);
		s_we_i <= '0';
		wait until falling_edge(s_wclk_i);
		s_waddr_i <= "01001000100011";
		s_data_i <= "111111110000000011111111";

	end process p_decode_test;
	
end architecture sim;

-------------------------------------------------------------------------------

configuration matrix_tb_sim_cfg of matrix_tb is
    for sim
    end for;
end matrix_tb_sim_cfg;

-------------------------------------------------------------------------------
