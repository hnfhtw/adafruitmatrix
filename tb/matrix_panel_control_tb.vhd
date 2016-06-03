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

-- Testbench for matrix entity
-- Last modified: 03.06.2016

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.calc_pkg.all;

-------------------------------------------------------------------------------

entity matrix_panel_control_tb is

     generic 
	 (
		NO_PANEL_ROWS : natural := 4;					-- number of panel rows
		NO_PANEL_COLUMNS : natural := 4;				-- number of panel columns
		COLORDEPTH : natural := 6;						-- colordepth in Bit
		PIXEL_ROW_ADDRESS_BITS : natural := 4;		    -- 4 address lines A-D for the pixel rows
		NO_PIXEL_COLUMNS_PER_PANEL : natural := 32	    -- number of pixels in one row of one panel
	 );

end entity matrix_panel_control_tb;

-------------------------------------------------------------------------------

architecture sim of matrix_panel_control_tb is

	component matrix
	port(
        s_clk_i     : in  std_logic;
        s_reset_n_i : in  std_logic;
        s_wclk_i    : in std_logic;
        s_waddr_i   : in std_logic_vector(log2ceil(NO_PANEL_COLUMNS) + PIXEL_ROW_ADDRESS_BITS + log2ceil(NO_PANEL_ROWS) + log2ceil(NO_PIXEL_COLUMNS_PER_PANEL) + 1 downto 0);  -- write address input to decoder for framebuffers (e.g. format at 4x4 panels: "A-TTT-RRRR-PP-XXXXX" -> 15 Bit)
        s_wdata_i   : in std_logic_vector(3*COLORDEPTH-1 downto 0);  -- 3x8 bit wide RGB output which goes to the decoder for framebuffers
        s_we_i      : in std_logic;                         -- write enable input to decoder for framebuffers
        s_brightscale_i : in std_logic_vector(log2ceil(NO_PIXEL_COLUMNS_PER_PANEL) - 1 downto 0);
        s_data_o    : out std_logic_vector((NO_PANEL_ROWS*6) - 1 downto 0);                     -- RGB output signals (R0/R1, G0/G1, B0/B1) (6 per panel row)
        s_row_o     : out std_logic_vector((NO_PANEL_ROWS*PIXEL_ROW_ADDRESS_BITS)-1 downto 0);  -- output signals for address lines DCBA (4 per panel row)
        s_lat_o     : out std_logic_vector(NO_PANEL_ROWS-1 downto 0);                           -- STB / LATCH output (1 per panel row)
        s_oe_o      : out std_logic_vector(NO_PANEL_ROWS-1 downto 0);                           -- OE output (1 per panel row)
        s_clk_o     : out std_logic_vector(NO_PANEL_ROWS-1 downto 0)                            -- CLK output (1 per panel row)
    );
	end component;

    -- component ports
    signal s_clk_i     : std_logic := '1';
    signal s_clk180_i  : std_logic;
    signal s_reset_n_i : std_logic := '0';
    signal s_data_o    : std_logic_vector((NO_PANEL_ROWS*6) - 1 downto 0);
    signal s_row_o     : std_logic_vector((NO_PANEL_ROWS*PIXEL_ROW_ADDRESS_BITS)-1 downto 0);
    signal s_lat_o     : std_logic_vector(NO_PANEL_ROWS-1 downto 0);
    signal s_oe_o      : std_logic_vector(NO_PANEL_ROWS-1 downto 0);
    signal s_brightscale_i : std_logic_vector(log2ceil(NO_PIXEL_COLUMNS_PER_PANEL) - 1 downto 0) := "00000";
	signal s_clk_o     : std_logic_vector(NO_PANEL_ROWS-1 downto 0);	
	signal s_wdata_i    : std_logic_vector(3*COLORDEPTH-1 downto 0) := (others => '0');
	signal s_we_i      : std_logic := '0';
	signal s_waddr_i   : std_logic_vector(log2ceil(NO_PANEL_COLUMNS) + PIXEL_ROW_ADDRESS_BITS + log2ceil(NO_PANEL_ROWS) + log2ceil(NO_PIXEL_COLUMNS_PER_PANEL) + 1 downto 0) := (others => '0');
	signal s_wclk_i    : std_logic := '1';
    
begin  -- architecture sim

    -- component instantiation
    DUT : entity work.matrix
		generic map (
			NO_PANEL_ROWS	=> NO_PANEL_ROWS,
			NO_PANEL_COLUMNS	=> NO_PANEL_COLUMNS,
			COLORDEPTH	=> COLORDEPTH,
			PIXEL_ROW_ADDRESS_BITS	=> PIXEL_ROW_ADDRESS_BITS,
			NO_PIXEL_COLUMNS_PER_PANEL	=> NO_PIXEL_COLUMNS_PER_PANEL
		)
	
        port map (
            s_clk_i     => s_clk_i,
            s_reset_n_i => s_reset_n_i,
            s_wclk_i    => s_wclk_i,
            s_waddr_i   => s_waddr_i,
            s_wdata_i   => s_wdata_i,
            s_we_i      => s_we_i,     
            s_brightscale_i => s_brightscale_i,
            s_data_o    => s_data_o,
            s_row_o     => s_row_o,
            s_lat_o     => s_lat_o,
            s_oe_o      => s_oe_o,
			s_clk_o     => s_clk_o
		);

    -- clock generation
    s_clk_i     <= not s_clk_i after 16666 ps;  -- 30MHz system clock
    s_clk180_i  <= not s_clk_i;
    s_reset_n_i <= '1'         after 3333 ns;   -- reset after 10 clock periods
	s_wclk_i    <= s_clk_i; -- use 30MHz system clock also as RGB data interface write clock
	
    -- input address format: A-TTT-RRRR-PP-XXXXX:
	p_decode_test : process
	begin
     wait for 600 us;
    -- wait until rising_edge(s_wclk_i);
		-- s_we_i <= '1';                      -- test writing of single pixel
		-- s_waddr_i <= "000000000000010";
		-- s_wdata_i <= "111111000000111111";
		-- wait until rising_edge(s_wclk_i);
		-- s_we_i <= '0';
		-- wait until rising_edge(s_wclk_i);
    -- wait until rising_edge(s_wclk_i);
    -- wait until rising_edge(s_wclk_i);
    -- wait until rising_edge(s_wclk_i);
		-- s_we_i <= '1';                      -- test filling of whole framebuffer
		-- s_waddr_i <= "100000010100001";
		-- s_wdata_i <= "000000111111000000";
		-- wait until rising_edge(s_wclk_i);
		-- s_we_i <= '0';	
    -- wait for 2 ms;                 -- with 10MHz write clock, the RAM blocks (128x16 memory locations) are filled in ~204.8us
	end process p_decode_test;


	
end architecture sim;

-------------------------------------------------------------------------------

configuration matrix_panel_control_tb_sim_cfg of matrix_panel_control_tb is
    for sim
    end for;
end matrix_panel_control_tb_sim_cfg;

-------------------------------------------------------------------------------
