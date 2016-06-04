-- ADAFRUITMATRIX -- FPGA design to drive combinations of 32x32 RGB LED Matrices
--
-- Copyright (C) 2016  Harald Netzer (Initial Version by C. Fibich)
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

-- Matrix Driver entity
-- Last modified: 03.06.2016

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.calc_pkg.all;

entity matrix is
	 
    generic (
        NO_PANEL_ROWS : natural := 1;               -- number of panel rows
        NO_PANEL_COLUMNS : natural := 4;            -- number of panel columns
        COLORDEPTH : natural := 6;                  -- colordepth in Bit
        PIXEL_ROW_ADDRESS_BITS : natural := 4;      -- 4 address lines A-D for the pixel rows
        NO_PIXEL_COLUMNS_PER_PANEL : natural := 32  -- number of pixels in one row of one panel
    );
	
    port (
        s_clk_i     : in  std_logic;    -- clock input
        s_reset_n_i : in  std_logic;    -- reset input
        s_wclk_i    : in std_logic;
        s_waddr_i   : in std_logic_vector(log2ceil(NO_PANEL_COLUMNS) + PIXEL_ROW_ADDRESS_BITS + log2ceil(NO_PANEL_ROWS) + log2ceil(NO_PIXEL_COLUMNS_PER_PANEL) + 1 downto 0);  -- write address input to decoder for framebuffers (e.g. format at 4x4 panels: "A-TTT-RRRR-PP-XXXXX" -> 15 bits)
        s_wdata_i   : in std_logic_vector(3*COLORDEPTH-1 downto 0);                             -- 3xCOLORDEPTH bit wide RGB output which goes to the decoder for framebuffers
        s_we_i      : in std_logic;                                                             -- write enable input to decoder for framebuffers
        s_brightscale_i : in std_logic_vector(log2ceil(NO_PIXEL_COLUMNS_PER_PANEL) - 1 downto 0);   -- global brightness control signal
        s_data_o    : out std_logic_vector((NO_PANEL_ROWS*6) - 1 downto 0);                     -- RGB output signals (R0/R1, G0/G1, B0/B1) (6 per panel row)
        s_row_o     : out std_logic_vector((NO_PANEL_ROWS*PIXEL_ROW_ADDRESS_BITS)-1 downto 0);  -- output signals for address lines DCBA (4 per panel row)
        s_lat_o     : out std_logic_vector(NO_PANEL_ROWS-1 downto 0);                           -- STB / LATCH output (1 per panel row)
        s_oe_o      : out std_logic_vector(NO_PANEL_ROWS-1 downto 0);                           -- OE output (1 per panel row)
        s_clk_o     : out std_logic_vector(NO_PANEL_ROWS-1 downto 0)                            -- CLK output (1 per panel row)
    );	 
end matrix;

architecture rtl of matrix is
    -- constants
    constant C_RED_0        : natural := 0;
    constant C_GREEN_0      : natural := 1;
    constant C_BLUE_0       : natural := 2;
    constant C_RED_1        : natural := 3;
    constant C_GREEN_1      : natural := 4;
    constant C_BLUE_1       : natural := 5;
	 
    constant C_NO_PANEL_COLUMNS_BIT           : natural := log2ceil(NO_PANEL_COLUMNS);             -- number of bits necessary to represent NO_PANEL_COLUMNS
    constant C_NO_PIXEL_COLUMNS_PER_PANEL_BIT : natural := log2ceil(NO_PIXEL_COLUMNS_PER_PANEL);   -- number of bits necessary to represent NO_PIXEL_COLUMNS_PER_PANEL (32 at the current panels)
    constant C_NO_PANEL_ROWS_BIT              : natural := log2ceil(NO_PANEL_ROWS);                -- number of bits necessary to represent NO_PANEL_ROWS
	 
    constant RAM_ADDR_WIDTH     : natural := PIXEL_ROW_ADDRESS_BITS + C_NO_PANEL_COLUMNS_BIT + C_NO_PIXEL_COLUMNS_PER_PANEL_BIT;
    constant WADDR_WIDTH        : natural := C_NO_PANEL_COLUMNS_BIT + PIXEL_ROW_ADDRESS_BITS + C_NO_PANEL_ROWS_BIT + 1 + C_NO_PIXEL_COLUMNS_PER_PANEL_BIT + 1;
    -- end constants
	
    -- matrix driver
    signal s_raddr              : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);              -- read address to get current pixel data (for RGB0/1 outputs) out of the framebuffers
    signal s_sel                : std_logic_vector(log2ceil(COLORDEPTH)-1 downto 0);
    signal s_ram_u, s_ram_l     : std_logic_vector(NO_PANEL_ROWS*3*COLORDEPTH-1 downto 0);  -- frame buffer outputs for upper and lower half panel rows
    signal s_row                : std_logic_vector(PIXEL_ROW_ADDRESS_BITS-1 downto 0);
    -- end matrix driver
 	
    -- RGB data decoder
    signal s_waddr              : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);      -- decoded writing address output which goes to all framebuffers
    signal s_wdata              : std_logic_vector(3*COLORDEPTH-1 downto 0);        -- RGB data output of decoder which goes to all framebuffers
    signal s_we                 : std_logic_vector(2*NO_PANEL_ROWS-1 downto 0);     -- write enable for each framebuffer - to select correct framebuffer in which to write wdata at waddr												-- write clock (for decoder, UART receiver and framebuffer writing) 
    signal s_ramindex           : unsigned(RAM_ADDR_WIDTH-1 downto 0);
    signal s_weblock             : std_logic;
    -- end RGB data decoder
	
begin
    -- RGB data decoder (sets s_we signal for correct framebuffer)
    -- Example for 4x4 Panels: 
    -- Input address format s_waddr_i = A-TTT-RRRR-PP-XXXXX -> PP = panel column number, TTT = halfpanel row number (0 = upper half of first panel row, 1 = lower half of first panel row, ...), RRRR = pixel row number, XXXXX = pixel column number, A = fill all framebuffers with s_wdata if A=1
    -- Output address format s_waddr = PP-RRRR-XXXXX and s_we(TTT) -> set write address at all framebuffers but activate only the correct one for writing
    
    p_decode : process(s_wclk_i, s_reset_n_i)
    begin
        if(s_reset_n_i = '0') then
            s_we <= (others => '0');
            s_wdata <= (others => '0');
            s_waddr <= (others => '0');
            s_ramindex <= (others => '0');
        elsif(rising_edge(s_wclk_i)) then
            s_we <= (others => '0');
			
            if(s_we_i = '1' and s_weblock <= '0') then              
                -- address assignment for input address format: A-TTT-RRRR-PP-XXXXX:
                s_waddr(C_NO_PIXEL_COLUMNS_PER_PANEL_BIT-1 downto 0)	<= s_waddr_i(C_NO_PIXEL_COLUMNS_PER_PANEL_BIT-1 downto 0);  -- assign address part XXXXX
                s_waddr(RAM_ADDR_WIDTH-1 downto RAM_ADDR_WIDTH-C_NO_PANEL_COLUMNS_BIT) <= s_waddr_i(C_NO_PIXEL_COLUMNS_PER_PANEL_BIT+C_NO_PANEL_COLUMNS_BIT-1 downto C_NO_PIXEL_COLUMNS_PER_PANEL_BIT); -- assign address part PP
                s_waddr(RAM_ADDR_WIDTH-C_NO_PANEL_COLUMNS_BIT-1 downto C_NO_PIXEL_COLUMNS_PER_PANEL_BIT) <= s_waddr_i(PIXEL_ROW_ADDRESS_BITS+C_NO_PIXEL_COLUMNS_PER_PANEL_BIT+C_NO_PANEL_COLUMNS_BIT-1 downto C_NO_PIXEL_COLUMNS_PER_PANEL_BIT+C_NO_PANEL_COLUMNS_BIT); -- assign address part RRRR
                s_we(to_integer(unsigned(s_waddr_i(WADDR_WIDTH-2 downto C_NO_PIXEL_COLUMNS_PER_PANEL_BIT+C_NO_PANEL_COLUMNS_BIT+PIXEL_ROW_ADDRESS_BITS)))) <= '1';  -- assign address part TTT to correct write enable signal for correct framebuffer
                      
                s_wdata <= s_wdata_i;   -- RGB data
                
                -- enable writing of whole ram blocks if MSB (address part 'A') of s_waddr_i is set
                if(s_waddr_i(s_waddr_i'length - 1) = '1') then
                    s_weblock <= '1';
                end if;
                
            elsif(s_weblock = '1') then     -- fill all ram blocks with the same s_wdata color
                s_waddr <= std_logic_vector(s_ramindex);
                s_ramindex <= s_ramindex + 1;
                s_we <= (others => '1');
                if(s_ramindex = to_unsigned(NO_PIXEL_COLUMNS_PER_PANEL*NO_PANEL_COLUMNS*(2**PIXEL_ROW_ADDRESS_BITS)-1, s_ramindex'length)) then
                    s_ramindex <= (others => '0');
                    s_weblock <= '0';
                end if;
            end if;
        end if;
    end process p_decode;
    -- end RGB data decoder
	
    -- generate frame buffers for upper and lower half of panel row n
    half_panel_row_frame_buffers : for n in 0 to NO_PANEL_ROWS-1 generate
    begin
	
        ram_u_panelrowX : entity work.ram
        generic map (
            DATA_WIDTH => 3*COLORDEPTH,
            DATA_RANGE => NO_PIXEL_COLUMNS_PER_PANEL*NO_PANEL_COLUMNS*(2**PIXEL_ROW_ADDRESS_BITS),
            init_file => "..\img\mif_files\128x32_black_6bit.mif"
        )
        port map (
            rclk    => s_clk_i,
            wclk    => s_wclk_i,
            raddr   => s_raddr,
            waddr   => s_waddr,
            wdata    => s_wdata,
            we      => s_we(2*n),
            q       => s_ram_u((n+1)*3*COLORDEPTH-1 downto 3*COLORDEPTH*n)
        );
		
        ram_l_panelrowX : entity work.ram
        generic map (
            DATA_WIDTH => 3*COLORDEPTH,
            DATA_RANGE => NO_PIXEL_COLUMNS_PER_PANEL*NO_PANEL_COLUMNS*(2**PIXEL_ROW_ADDRESS_BITS),
            init_file => "..\img\mif_files\128x32_black_6bit.mif"
        )
        port map (
            rclk	=> s_clk_i,
            wclk	=> s_wclk_i,
            raddr	=> s_raddr,
            waddr	=> s_waddr,
            wdata	=> s_wdata,
            we		=> s_we(2*n+1),
            q		=> s_ram_l((n+1)*3*COLORDEPTH-1 downto 3*COLORDEPTH*n)
        );	
	
    end generate half_panel_row_frame_buffers;
	 
    -- assign panel control signals to toplevel output signals
    panel_ctrl_signals : for n in 0 to NO_PANEL_ROWS-1 generate
        s_clk_o(n) <= not s_clk_i;	-- A-D address line outputs for panel row n (180° delayed to RGB0/1 timing)
        s_row_o((n+1)*PIXEL_ROW_ADDRESS_BITS-1 downto n*PIXEL_ROW_ADDRESS_BITS) <= s_row;   -- CLK output for panel row n
    --begin
    end generate panel_ctrl_signals;
 
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
            s_clk_i       => s_clk_i,
            s_reset_n_i   => s_reset_n_i,
            s_brightscale_i => s_brightscale_i,
            s_addr_o      => s_raddr,
            s_row_o       => s_row,
            s_sel_o       => s_sel,
            s_oe_o        => s_oe_o,
            s_lat_o       => s_lat_o
        );
		
    -- generate processes that drive RGB0/1 output signals from framebuffer output	
    RGB01_output_signals : for n in 0 to NO_PANEL_ROWS-1 generate
    begin
	 
        p_RGB01_output_panelrowX : process(s_ram_u, s_ram_l, s_sel)
        begin			
            -- order if framebuffer data is arranged as: RGB (Bit 7 to Bit 0 = B)
            s_data_o(n*(C_BLUE_1+1) + C_RED_0)   <= s_ram_u(to_integer(unsigned(s_sel))+COLORDEPTH*3*n+COLORDEPTH*2);
            s_data_o(n*(C_BLUE_1+1) + C_GREEN_0) <= s_ram_u(to_integer(unsigned(s_sel))+COLORDEPTH*3*n+COLORDEPTH);
            s_data_o(n*(C_BLUE_1+1) + C_BLUE_0)  <= s_ram_u(to_integer(unsigned(s_sel))+COLORDEPTH*3*n);
            s_data_o(n*(C_BLUE_1+1) + C_RED_1)   <= s_ram_l(to_integer(unsigned(s_sel))+COLORDEPTH*3*n+COLORDEPTH*2);
            s_data_o(n*(C_BLUE_1+1) + C_GREEN_1) <= s_ram_l(to_integer(unsigned(s_sel))+COLORDEPTH*3*n+COLORDEPTH);
            s_data_o(n*(C_BLUE_1+1) + C_BLUE_1)  <= s_ram_l(to_integer(unsigned(s_sel))+COLORDEPTH*3*n);
        end process p_RGB01_output_panelrowX;
	 
    end generate RGB01_output_signals;
	
end rtl;
