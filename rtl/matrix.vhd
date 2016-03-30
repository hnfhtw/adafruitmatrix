-- ADAFRUITMATRIX -- FPGA design to drive combinations (1x1, 2x2, 4x4) of 32x32 RGB LED Matrices
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

-- Toplevel entity
-- Last modified: 30.03.2016

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity matrix is
	 
	 generic 
	 (
		NO_PANEL_ROWS : natural := 2;					-- number of panel rows
		NO_PANEL_COLUMNS : natural := 4;				-- number of panel columns
		COLORDEPTH : natural := 8;						-- colordepth in Bit
		PIXEL_ROW_ADDRESS_BITS : natural := 4;		-- 4 address lines A-D for the pixel rows
		NO_PIXEL_COLUMNS_PER_PANEL : natural := 32	-- number of pixels in one row of one panel
	 );
	
    port(
        s_clk_i     : in  std_logic;
        s_reset_n_i : in  std_logic;
        s_data_o    : out std_logic_vector((NO_PANEL_ROWS*6) - 1 downto 0);                 -- RGB output to one row of 32x32 Panels (R0/R1, G0/G1, B0/B1)
        s_row_o     : out std_logic_vector((NO_PANEL_ROWS*PIXEL_ROW_ADDRESS_BITS)-1 downto 0);     							 -- Output to address lines DCBA (3 to 0)
        s_lat_o     : out std_logic_vector(NO_PANEL_ROWS-1 downto 0);						-- STB / LATCH output
        s_oe_o      : out std_logic_vector(NO_PANEL_ROWS-1 downto 0);						-- OE output
        s_wobble_i  : in  std_logic;
        s_clk_o     : out std_logic_vector(NO_PANEL_ROWS-1 downto 0));						-- CLK output
end matrix;

architecture rtl of matrix is

    constant C_RED_0        : natural := 0;
    constant C_GREEN_0      : natural := 1;
    constant C_BLUE_0       : natural := 2;
    constant C_RED_1        : natural := 3;
    constant C_GREEN_1      : natural := 4;
    constant C_BLUE_1       : natural := 5;
	 
	 constant RAM_ADDR_WIDTH	: natural := PIXEL_ROW_ADDRESS_BITS + natural(ceil(log2(real(NO_PANEL_COLUMNS)))) + natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))));

    signal s_addr           : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
   
	 signal s_sel            : std_logic_vector(natural(ceil(log2(real(COLORDEPTH))))-1 downto 0);
	 signal s_ram_u, s_ram_l : std_logic_vector(NO_PANEL_ROWS*3*COLORDEPTH-1 downto 0);	-- frame buffers for upper and lower half of panel row n
    signal s_row            : std_logic_vector(PIXEL_ROW_ADDRESS_BITS-1 downto 0);

    signal s_reset_n : std_logic;
    signal s_clk     : std_logic;
	 signal s_clk1		: std_logic;
    signal s_locked  : std_logic_vector(1 downto 0);
    signal s_reset   : std_logic;

    signal s_wobble                     : std_logic_vector(1 downto 0);
    signal s_brightcnt, s_brightcnt_nxt : unsigned(27 downto 0);
    signal s_direction                  : std_logic;

begin
	
	-- generate frame buffers for upper and lower half of panel row n
	half_panel_row_frame_buffers : for n in 0 to NO_PANEL_ROWS-1 generate
	begin
	
		testram_u_panelrowX : entity work.testram
		generic map (
			DATA_WIDTH => 3*COLORDEPTH,
			ADDR_WIDTH => RAM_ADDR_WIDTH,
			init_file => "128x32_upper.mif"
		)
		port map (
			rclk	=> s_clk,
			wclk	=> s_clk,
			raddr	=> s_addr,
			waddr	=> s_addr,
			data	=> s_ram_l((n+1)*3*COLORDEPTH-1 downto 3*COLORDEPTH*n),
			we		=> '0',
			q		=> s_ram_u((n+1)*3*COLORDEPTH-1 downto 3*COLORDEPTH*n)
		);
		
		testram_l_panelrowX : entity work.testram
		generic map (
			DATA_WIDTH => 3*COLORDEPTH,
			ADDR_WIDTH => RAM_ADDR_WIDTH,
			init_file => "128x32_lower.mif"
		)
		port map (
			rclk	=> s_clk,
			wclk	=> s_clk,
			raddr	=> s_addr,
			waddr	=> s_addr,
			data	=> s_ram_u((n+1)*3*COLORDEPTH-1 downto 3*COLORDEPTH*n),
			we		=> '0',
			q		=> s_ram_l((n+1)*3*COLORDEPTH-1 downto 3*COLORDEPTH*n)
		);	
	
	end generate half_panel_row_frame_buffers;

	
    -- generate clock for the panel
    -- c1 is shifted by 180deg
    pll_i : entity work.pll
        port map (
            areset => s_reset,
            inclk0 => s_clk_i,
            c0     => s_clk,
				c1		 => s_clk1,
            locked => s_locked(0));

				
    -- reset based on PLL locked signal
    p_rst : process(s_clk, s_reset_n_i)
    begin
        if(s_reset_n_i = '0') then
            s_locked(1) <= '0';
        elsif(rising_edge(s_clk)) then
            s_locked(1) <= s_locked(0);
        end if;
    end process p_rst;

    s_reset   <= not s_reset_n_i;
    s_reset_n <= s_reset_n_i and s_locked(1);

	 
	 -- assign panel control signals to toplevel output signals
    panel_ctrl_signals : for n in 0 to NO_PANEL_ROWS-1 generate
		s_clk_o(n) <= s_clk1;	-- A-D address line outputs for panel row n
		s_row_o((n+1)*PIXEL_ROW_ADDRESS_BITS-1 downto n*PIXEL_ROW_ADDRESS_BITS) <= s_row;	-- CLK output for panel row n
	--begin
	end generate panel_ctrl_signals;

	
    -- Hacky brightness scaling controller
    s_brightcnt_nxt <= s_brightcnt + 1 when s_direction = '0' else s_brightcnt - 1;

    p_brightcnt : process(s_clk, s_reset_n)
    begin
        if(s_reset_n = '0') then
            s_brightcnt <= (others => '0');
            s_wobble    <= (others => '0');
            s_direction <= '0';
        elsif (rising_edge(s_clk)) then
            s_wobble(0) <= s_wobble_i;
            s_wobble(1) <= s_wobble(0);

            if(s_brightcnt_nxt(s_brightcnt'length-1) = '1') then
                s_direction <= not s_direction;
            end if;

            if(s_wobble(1) = '1') then
                if (s_brightcnt_nxt(s_brightcnt'length-1) = '0') then
                    s_brightcnt <= s_brightcnt_nxt;
                end if;
            else
                s_brightcnt <= (others => '0');
            end if;
        end if;
    end process p_brightcnt;

	 	 
    -- instantiate the entity which generates the control signals for the Panel and BCM
    ctrl : entity work.ctrl
		  generic map (
				NO_PANEL_ROWS => NO_PANEL_ROWS,
				NO_PANEL_COLUMNS => NO_PANEL_COLUMNS,
				COLORDEPTH => COLORDEPTH,
				PIXEL_ROW_ADDRESS_BITS => PIXEL_ROW_ADDRESS_BITS,
				NO_PIXEL_COLUMNS_PER_PANEL => NO_PIXEL_COLUMNS_PER_PANEL
		  )
        port map (
            s_clk_i       => s_clk,
            s_reset_n_i   => s_reset_n,
            s_addr_o      => s_addr,
            s_row_o       => s_row,
            s_sel_o       => s_sel,
            s_brightscale => std_logic_vector(s_brightcnt(s_brightcnt'length-2 downto s_brightcnt'length-6)),
            s_oe_o        => s_oe_o,
            s_lat_o       => s_lat_o);

				
	 -- generate processes that drive RGB0/1 output signals from framebuffer output	
    RGB01_output_signals : for n in 0 to NO_PANEL_ROWS-1 generate
	 begin
	 
		 p_RGB01_output_panelrowX : process(s_ram_u, s_ram_l, s_sel)
		 begin
			  s_data_o(n*(C_BLUE_1+1) + C_RED_0)   <= s_ram_u(to_integer(unsigned(s_sel))+COLORDEPTH*3*n);
			  s_data_o(n*(C_BLUE_1+1) + C_GREEN_0) <= s_ram_u(to_integer(unsigned(s_sel))+COLORDEPTH*3*n+COLORDEPTH);
			  s_data_o(n*(C_BLUE_1+1) + C_BLUE_0)  <= s_ram_u(to_integer(unsigned(s_sel))+COLORDEPTH*3*n+COLORDEPTH*2);
			  s_data_o(n*(C_BLUE_1+1) + C_RED_1)   <= s_ram_l(to_integer(unsigned(s_sel))+COLORDEPTH*3*n);
			  s_data_o(n*(C_BLUE_1+1) + C_GREEN_1) <= s_ram_l(to_integer(unsigned(s_sel))+COLORDEPTH*3*n+COLORDEPTH);
			  s_data_o(n*(C_BLUE_1+1) + C_BLUE_1)  <= s_ram_l(to_integer(unsigned(s_sel))+COLORDEPTH*3*n+COLORDEPTH*2);
		 end process p_RGB01_output_panelrowX;
	 
	 end generate RGB01_output_signals;
	
end rtl;
