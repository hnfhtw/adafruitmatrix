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

-- LED matrix control entity
-- Last modified: 21.04.2016

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;			-- for ceil and log2 -> to get bit width of integer (natural) generics

entity ctrl is

	generic 
	 (
		NO_PANEL_ROWS : natural;					-- number of panel rows
		NO_PANEL_COLUMNS : natural;				-- number of panel columns
		COLORDEPTH : natural;						-- colordepth in Bit
		PIXEL_ROW_ADDRESS_BITS : natural;		-- 4 address lines A-D for the pixel rows
		NO_PIXEL_COLUMNS_PER_PANEL : natural	-- number of pixels in one row of one panel
	 );

    port (
        s_clk_i       : in  std_logic;
        s_reset_n_i   : in  std_logic;
        s_addr_o      : out std_logic_vector((PIXEL_ROW_ADDRESS_BITS + natural(ceil(log2(real(NO_PANEL_COLUMNS)))) + natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL)))))-1 downto 0);			-- 11 bit wide (10 downto 0)
        s_row_o       : out std_logic_vector(PIXEL_ROW_ADDRESS_BITS-1 downto 0);				-- 4 bit wide (3 downto 0)
        s_sel_o       : out std_logic_vector(natural(ceil(log2(real(COLORDEPTH))))-1 downto 0);			-- 3 bit wide (2 downto 0)
        s_brightscale : in  std_logic_vector(natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))-1 downto 0);				-- 5 bit wide (4 downto 0)
        s_oe_o        : out std_logic_vector(NO_PANEL_ROWS-1 downto 0);
        s_lat_o       : out std_logic_vector(NO_PANEL_ROWS-1 downto 0));
end entity ctrl;

architecture rtl of ctrl is
    constant C_NO_PANEL_COLUMNS_BIT					: natural := natural(ceil(log2(real(NO_PANEL_COLUMNS))));	-- number of bits necessary to represent NO_PANEL_COLUMNS
	 constant C_NO_PIXEL_COLUMNS_PER_PANEL_BIT 	: natural := natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))));  -- number of bits necessary to represent NO_PIXEL_COLUMNS_PER_PANEL (32 at the current panels)
	 constant C_NO_PANEL_ROWS_BIT 					: natural := natural(ceil(log2(real(NO_PANEL_ROWS))));	-- number of bits necessary to represent NO_PANEL_ROWS
	 	 
	 signal s_cnt_row, s_cnt_row_nxt 				: unsigned(PIXEL_ROW_ADDRESS_BITS downto 0);				-- 5 bit wide (4 downto 0) -> can count from 0 to 31
    signal s_cnt_bit, s_cnt_bit_nxt 				: unsigned(COLORDEPTH downto 0);								-- 9 bit wide (8 downto 0) -> can count from 0 to 255
    signal s_cnt_pan 									: unsigned(C_NO_PANEL_COLUMNS_BIT downto 0);				-- 3 bit wide (2 downto 0) -> can count from 0 to 7	
	 signal s_cnt_pxl, s_cnt_pxl_nxt 				: unsigned(C_NO_PIXEL_COLUMNS_PER_PANEL_BIT downto 0);		-- 6 bit wide (5 downto 0) -> can count from 0 to 63

    signal s_sel : std_logic_vector(natural(ceil(log2(real(COLORDEPTH))))-1 downto 0);						-- 3 bit wide (2 downto 0) -> can count from 0 to 7
    signal s_row : std_logic_vector(PIXEL_ROW_ADDRESS_BITS-1 downto 0);											-- 4 bit wide (3 downto 0) -> can count from 0 to 15
    signal s_oe  : std_logic_vector(NO_PANEL_ROWS-1 downto 0);
    signal s_lat : std_logic_vector(NO_PANEL_ROWS-1 downto 0);
	 
	 constant s_brightscale1 : std_logic_vector(4 downto 0) := "01111";		-- HN DEBUG
begin
    -- counter that loops through all pixels
    p_cnt : process(s_clk_i, s_reset_n_i)
	 begin
      if(s_reset_n_i = '0') then
		  s_cnt_pxl <= (others => '0');
		  s_cnt_pan <= (others => '0');
		  s_cnt_bit <= (others => '0');
	     s_cnt_row <= (others => '0');
		elsif(rising_edge(s_clk_i)) then
		  s_cnt_pxl <= '0' & s_cnt_pxl_nxt(C_NO_PIXEL_COLUMNS_PER_PANEL_BIT-1 downto 0);            -- count up pixels in one panel
		  
		  if(s_cnt_pxl_nxt(C_NO_PIXEL_COLUMNS_PER_PANEL_BIT) = '1') then                            -- count up the panels
		    if(s_cnt_pan = NO_PANEL_COLUMNS-1) then
			   s_cnt_pan <= (others => '0');
			 else
			   s_cnt_pan <= s_cnt_pan + 1;
			 end if;
		  end if;
		  
		  if((s_cnt_pan = NO_PANEL_COLUMNS-1) and s_cnt_pxl_nxt(C_NO_PIXEL_COLUMNS_PER_PANEL_BIT) = '1') then     -- count up the BCM (e.g. up to 255 at 8 bit colordepth)
		    s_cnt_bit <= '0' & s_cnt_bit_nxt(COLORDEPTH-1 downto 0);
		  end if;
		  
		  if(s_cnt_bit_nxt(COLORDEPTH) = '1' and (s_cnt_pan = NO_PANEL_COLUMNS-1) and s_cnt_pxl_nxt(C_NO_PIXEL_COLUMNS_PER_PANEL_BIT) = '1') then       -- count up the pixel rows (ABCD)
		    s_cnt_row <= '0' & s_cnt_row_nxt(PIXEL_ROW_ADDRESS_BITS-1 downto 0);
		  end if;	 
		end if;  
	 end process p_cnt;

    s_cnt_pxl_nxt <= s_cnt_pxl + 1;
    s_cnt_bit_nxt <= s_cnt_bit + 1;
    s_cnt_row_nxt <= s_cnt_row + 1;

	-- assign output signal which always correspons to the current pixel (necessary to lookup RGB values in framebuffers and generate RGB0/1 output signals)
   s_addr_o <=  std_logic_vector(s_cnt_pan(C_NO_PANEL_COLUMNS_BIT-1 downto 0)) &
					 std_logic_vector(s_cnt_row(PIXEL_ROW_ADDRESS_BITS-1 downto 0)) &
                std_logic_vector(s_cnt_pxl(C_NO_PIXEL_COLUMNS_PER_PANEL_BIT-1 downto 0));


    -- generate the bit select signal for BCM (necessary to determine which bit of the e.g. 6 bit wide RGB values it put to the RGB0/1 outputs)
    p_decode_sel : process(s_cnt_bit)
    begin
        s_sel <= (others => '0');
        for i in 0 to COLORDEPTH-1 loop
            if (((2**i) - 1) < s_cnt_bit) then
                s_sel <= std_logic_vector(to_unsigned(i, natural(ceil(log2(real(COLORDEPTH))))));
            end if;
        end loop;
    end process p_decode_sel;

    s_oe_o  <= s_oe;
	 s_lat_o  <= s_lat;
    s_sel_o <= s_sel;

    -- generate the LATCH and ABCD control lines
    p_ctrl : process(s_clk_i, s_reset_n_i)
    begin
        if(s_reset_n_i = '0') then
            --s_lat_o <= (others => '0');
            s_row_o <= (others => '0');
            s_lat   <= (others => '0');
            s_oe    <= (others => '1');
            s_row   <= (others => '0');
        elsif(rising_edge(s_clk_i)) then
            s_row_o <= s_row;
            s_lat <= (others => '0');
            s_oe  <= (others => '0');

            -- hacky brightness scaling: enable just for the more significant bits 
            -- with increasing value of brightscale
            -- FIXME: reduces color depth, would be better to change overall duty cycle
            -- or remove entirely -- it is not really necessary
			-- HN: brightness scaling -> enable the panel only for part of the time (determined by difference of 31 - s_brightscale
            if (s_cnt_pxl >= ((NO_PIXEL_COLUMNS_PER_PANEL-1) - unsigned(s_brightscale))) then	-- s_cnt_pxl >= 2^5 - 1 - s_brightscale
					s_oe <= (others => '1');
				end if;

			if((s_cnt_pan = NO_PANEL_COLUMNS-1) and s_cnt_pxl_nxt(C_NO_PIXEL_COLUMNS_PER_PANEL_BIT) = '1') then
                s_lat <= (others => '1');
                s_row <= std_logic_vector(s_cnt_row(PIXEL_ROW_ADDRESS_BITS-1 downto 0));
            end if;
        end if;
    end process p_ctrl;

end rtl;
