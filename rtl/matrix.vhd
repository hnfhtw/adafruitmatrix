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

-- Toplevel entity
-- Last modified: 19.04.2016

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity matrix is
	 
	 generic 
	 (
		NO_PANEL_ROWS : natural := 4;					-- number of panel rows
		NO_PANEL_COLUMNS : natural := 4;				-- number of panel columns
		COLORDEPTH : natural := 6;						-- colordepth in Bit
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
        s_clk_o     : out std_logic_vector(NO_PANEL_ROWS-1 downto 0);						-- CLK output
		  
		  -- input for RGB data decoder
		 -- s_data_i    : in std_logic_vector(3*COLORDEPTH-1 downto 0);		-- RGB data input to decoder for framebuffers
		  --s_we_i      : in std_logic;													-- write enable input to decoder for framebuffers
		  --s_waddr_i   : in std_logic_vector((natural(ceil(log2(real(NO_PANEL_COLUMNS)))) + PIXEL_ROW_ADDRESS_BITS + natural(ceil(log2(real(NO_PANEL_ROWS)))) + natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))) downto 0);	-- write address input to decoder for framebuffers (e.g. format at 4x4 panels: PP RRRRRRR XXXXX -> 14 Bit)
		  --s_wclk_i    : in std_logic;
		  -- end input for RGB data decoder
		  
		  -- input for UART receiver
			s_uart_rx_i	  : in std_logic);		  
end matrix;

architecture rtl of matrix is

    constant C_RED_0        : natural := 0;
    constant C_GREEN_0      : natural := 1;
    constant C_BLUE_0       : natural := 2;
    constant C_RED_1        : natural := 3;
    constant C_GREEN_1      : natural := 4;
    constant C_BLUE_1       : natural := 5;
	 
	 constant RAM_ADDR_WIDTH	: natural := PIXEL_ROW_ADDRESS_BITS + natural(ceil(log2(real(NO_PANEL_COLUMNS)))) + natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))));
	 --constant WADDR_WIDTH      : natural := natural(ceil(log2(real(NO_PANEL_COLUMNS)))) + PIXEL_ROW_ADDRESS_BITS + natural(ceil(log2(real(NO_PANEL_ROWS)))) + natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))+1;
	 constant WADDR_WIDTH      : natural := natural(ceil(log2(real(NO_PANEL_COLUMNS)))) + PIXEL_ROW_ADDRESS_BITS + natural(ceil(log2(real(2*NO_PANEL_ROWS)))) + natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))));
	 
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

	-- RGB data decoder
	signal s_waddr   : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
	signal s_we      : std_logic_vector(2*NO_PANEL_ROWS-1 downto 0);
	-- end RGB data decoder
	 
	-- UART receiver
	signal s_uart_rx : std_logic;
	signal s_uart_rx_busy : std_logic;
	signal s_uart_rx_data	: std_logic_vector(7 downto 0);
	signal s_uart_rx_packet : std_logic_vector(47 downto 0) := (others => '0'); 	-- 6 Byte input buffer for RGB packets
	signal s_uart_rx_count		: unsigned(2 downto 0);					-- to count received bytes
	signal s_uart_rx_RGB		: std_logic_vector(3*8-1 downto 0);
	 
	signal s_data_i    : std_logic_vector(3*COLORDEPTH-1 downto 0);		-- RGB data input to decoder for framebuffers
	signal s_we_i      : std_logic;													-- write enable input to decoder for framebuffers
	signal s_waddr_i   : std_logic_vector((natural(ceil(log2(real(NO_PANEL_COLUMNS)))) + PIXEL_ROW_ADDRESS_BITS + natural(ceil(log2(real(NO_PANEL_ROWS)))) + natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))) downto 0);	-- write address input to decoder for framebuffers (e.g. format at 4x4 panels: PP RRRRRRR XXXXX -> 14 Bit)
	signal s_wclk_i    : std_logic; 
	signal s_data_taken	: std_logic := '0';
	signal s_uart_cs	: std_logic_vector(7 downto 0);
	
	--end UART receiver
begin

	-- instantiate the uart entity	  
	 rs232 : entity work.rs232
		   generic map (
				 Quarz_Taktfrequenz => 30000000,
				 Baudrate => 460800
		   )
         port map (
				 RXD			=> s_uart_rx,			-- RS232 received serial data
				 RX_Data		=> s_uart_rx_data,		-- Received data 
				 RX_Busy		=> s_uart_rx_busy,		-- Received data ready to uPC read
				 CLK			=> s_clk				-- Main clock
		   );	  
			  
	p_uart_rx : process(s_wclk_i, s_reset_n)
	begin
	  if(s_reset_n = '0') then
			s_we_i <= '0';
			s_uart_rx_count <= (others => '0');
      elsif(rising_edge(s_wclk_i)) then
		
			s_uart_rx <= s_uart_rx_i;
			
			s_uart_rx_RGB <= (others => '0');
			s_waddr_i <= (others => '0');
			s_we_i <= '0';
			
			 if(s_uart_rx_busy = '1') then
				 s_data_taken <= '0';
			 end if;			
		
			if(s_uart_rx_busy = '0' and s_uart_rx_count < 6 and s_data_taken = '0') then
				s_uart_rx_packet(47-(8*to_integer(s_uart_rx_count)) downto 40-(8*to_integer(s_uart_rx_count))) <= s_uart_rx_data;
				s_data_taken <= '1';
				s_uart_cs <= (s_uart_rx_packet(47 downto 40) xor s_uart_rx_packet(39 downto 32) xor s_uart_rx_packet(31 downto 24) xor s_uart_rx_packet(23 downto 16) xor s_uart_rx_packet(15 downto 8));
				s_uart_rx_count <= s_uart_rx_count + 1;
			elsif(s_uart_rx_count = 6) then			
				if(s_uart_rx_packet(7 downto 0) = s_uart_cs) then
					s_uart_rx_RGB <= s_uart_rx_packet(31 downto 8);
					s_waddr_i((natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))-1) downto 0) <= s_uart_rx_packet(40+natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))-1 downto 40);	            -- X coordinate -> Bit 0 to 4 (44 downto 40)-> s_waddr_i(4 downto 0) (XXXXX of s_waddr_i)
					s_waddr_i(WADDR_WIDTH-1 downto WADDR_WIDTH-natural(ceil(log2(real(NO_PANEL_COLUMNS))))) <= s_uart_rx_packet(40+natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))+natural(ceil(log2(real(NO_PANEL_COLUMNS))))-1 downto 40+natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL)))));	      -- X coordinate -> Bit 5 and 6 (46 downto 45)-> s_waddr_i(13 downto 12) (PP of s_waddr_i)
					s_waddr_i(natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))+PIXEL_ROW_ADDRESS_BITS-1 downto natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))) <= s_uart_rx_packet(32+PIXEL_ROW_ADDRESS_BITS-1 downto 32); 	-- Y coordinate -> Bit 0 to 3	(35 downto 32)-> s_waddr_i(8 downto 5) (RRRR of s_waddr_i)
					s_waddr_i(WADDR_WIDTH-natural(ceil(log2(real(NO_PANEL_COLUMNS))))-1 downto natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))+PIXEL_ROW_ADDRESS_BITS) <= s_uart_rx_packet(32+PIXEL_ROW_ADDRESS_BITS+natural(ceil(log2(real(2*NO_PANEL_ROWS))))-1 downto 32+PIXEL_ROW_ADDRESS_BITS);	-- Y coordinate -> Bit 4 to 6 (36 downto 38)-> s_waddr_i(11 downto 9) (TTT of s_waddr_i)
					s_we_i <= '1';
					s_uart_rx_count <= (others => '0');	
					s_uart_rx_packet <= (others => '0');
				else
					s_uart_rx_packet(47 downto 40) <= s_uart_rx_packet(39 downto 32);
					s_uart_rx_packet(39 downto 32) <= s_uart_rx_packet(31 downto 24);
					s_uart_rx_packet(31 downto 24) <= s_uart_rx_packet(23 downto 16);
					s_uart_rx_packet(23 downto 16) <= s_uart_rx_packet(15 downto 8);
					s_uart_rx_packet(15 downto 8) <= s_uart_rx_packet(7 downto 0);
					s_uart_rx_count <= s_uart_rx_count - 1;
				end if;
			end if;
      end if;
	end process p_uart_rx;	
	
	s_wclk_i <= s_clk;
		  

	-- RGB data decoder (sets s_we signal for correct framebuffer)
	-- Example for 4x4 Panels: Input address format s_waddr_i = PP TTT RRRR XXXXX -> PP = panel column number, TTT = halfpanel row number, RRRR = pixel row number, XXXXX = pixel column number
	--                         Output address format s_waddr = PP RRRR XXXXX and s_we(TTT) -> set write address at all framebuffers but activate only the correct one for writting
	--s_waddr(natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))-1 downto 0)	<= s_waddr_i(natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))-1 downto 0); -- assign address part XXXXX (PP RRR RRRR XXXXX)
	--s_waddr(RAM_ADDR_WIDTH-1 downto RAM_ADDR_WIDTH-natural(ceil(log2(real(NO_PANEL_COLUMNS))))) <= s_waddr_i(WADDR_WIDTH-1 downto WADDR_WIDTH-natural(ceil(log2(real(NO_PANEL_COLUMNS))))); -- assign address part PP (PP RRR RRRR XXXXX)
	--s_waddr(RAM_ADDR_WIDTH-natural(ceil(log2(real(NO_PANEL_COLUMNS))))-1 downto natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))) <= s_waddr_i(PIXEL_ROW_ADDRESS_BITS+natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))-1 downto natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))); -- assign address part RRRR (PP RRR RRRR XXXXX)
		
	p_decode : process(s_wclk_i, s_reset_n)
   begin
        if(s_reset_n = '0') then
			s_we <= (others => '0');
			s_data_i <= (others => '0');
        elsif(rising_edge(s_wclk_i)) then
			s_we <= (others => '0');
			s_data_i <= (others => '0');
			
			if(s_we_i = '1') then
					s_waddr(natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))-1 downto 0)	<= s_waddr_i(natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))-1 downto 0); -- assign address part XXXXX (PP RRR RRRR XXXXX)
					s_waddr(RAM_ADDR_WIDTH-1 downto RAM_ADDR_WIDTH-natural(ceil(log2(real(NO_PANEL_COLUMNS))))) <= s_waddr_i(WADDR_WIDTH-1 downto WADDR_WIDTH-natural(ceil(log2(real(NO_PANEL_COLUMNS))))); -- assign address part PP (PP RRR RRRR XXXXX)
					s_waddr(RAM_ADDR_WIDTH-natural(ceil(log2(real(NO_PANEL_COLUMNS))))-1 downto natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))) <= s_waddr_i(PIXEL_ROW_ADDRESS_BITS+natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))-1 downto natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL))))); -- assign address part RRRR (PP RRR RRRR XXXXX)
					s_we(to_integer(unsigned(s_waddr_i(WADDR_WIDTH-natural(ceil(log2(real(NO_PANEL_COLUMNS))))-1 downto PIXEL_ROW_ADDRESS_BITS+natural(ceil(log2(real(NO_PIXEL_COLUMNS_PER_PANEL)))))))) <= '1';
					s_data_i(3*COLORDEPTH-1 downto 2*COLORDEPTH) <= s_uart_rx_RGB(COLORDEPTH-1+16 downto 16); 	-- R
					s_data_i(2*COLORDEPTH-1 downto COLORDEPTH) <= s_uart_rx_RGB(COLORDEPTH-1+8 downto 8); 			-- G
					s_data_i(COLORDEPTH-1 downto 0) <= s_uart_rx_RGB(COLORDEPTH-1 downto 0); 							-- B
			end if;
        end if;
   end process p_decode;
	-- end RGB data decoder
	
	-- generate frame buffers for upper and lower half of panel row n
	half_panel_row_frame_buffers : for n in 0 to NO_PANEL_ROWS-1 generate
	begin
	
		testram_u_panelrowX : entity work.testram
		generic map (
			DATA_WIDTH => 3*COLORDEPTH,
			DATA_RANGE => NO_PIXEL_COLUMNS_PER_PANEL*NO_PANEL_COLUMNS*(2**PIXEL_ROW_ADDRESS_BITS),
			init_file => "..\img\mif_files\128x32_black_6bit.mif"
		)
		port map (
			rclk	=> s_clk,
			wclk	=> s_wclk_i,
			raddr	=> s_addr,
			waddr	=> s_waddr,
			data	=> s_data_i,
			we		=> s_we(2*n),
			q		=> s_ram_u((n+1)*3*COLORDEPTH-1 downto 3*COLORDEPTH*n)
		);
		
		testram_l_panelrowX : entity work.testram
		generic map (
			DATA_WIDTH => 3*COLORDEPTH,
			DATA_RANGE => NO_PIXEL_COLUMNS_PER_PANEL*NO_PANEL_COLUMNS*(2**PIXEL_ROW_ADDRESS_BITS),
			init_file => "..\img\mif_files\128x32_black_6bit.mif"
		)
		port map (
			rclk	=> s_clk,
			wclk	=> s_wclk_i,
			raddr	=> s_addr,
			waddr	=> s_waddr,
			data	=> s_data_i,
			we		=> s_we(2*n+1),
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
			 -- order if framebuffer data is aranged as: BGR (Bit 7 to Bit 0 = R)
			 -- s_data_o(n*(C_BLUE_1+1) + C_RED_0)   <= s_ram_u(to_integer(unsigned(s_sel))+COLORDEPTH*3*n);
			 -- s_data_o(n*(C_BLUE_1+1) + C_GREEN_0) <= s_ram_u(to_integer(unsigned(s_sel))+COLORDEPTH*3*n+COLORDEPTH);
			 -- s_data_o(n*(C_BLUE_1+1) + C_BLUE_0)  <= s_ram_u(to_integer(unsigned(s_sel))+COLORDEPTH*3*n+COLORDEPTH*2);
			 -- s_data_o(n*(C_BLUE_1+1) + C_RED_1)   <= s_ram_l(to_integer(unsigned(s_sel))+COLORDEPTH*3*n);
			 -- s_data_o(n*(C_BLUE_1+1) + C_GREEN_1) <= s_ram_l(to_integer(unsigned(s_sel))+COLORDEPTH*3*n+COLORDEPTH);
			 -- s_data_o(n*(C_BLUE_1+1) + C_BLUE_1)  <= s_ram_l(to_integer(unsigned(s_sel))+COLORDEPTH*3*n+COLORDEPTH*2);
			
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
