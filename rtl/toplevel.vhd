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
-- Last modified: 19.05.2016

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.calc_pkg.all;

entity toplevel is
  
    generic ( 
        NO_PANEL_ROWS : natural := 1;               -- number of panel rows
        NO_PANEL_COLUMNS : natural := 4;            -- number of panel columns
        COLORDEPTH : natural := 6;                  -- colordepth in Bit
        PIXEL_ROW_ADDRESS_BITS : natural := 4;      -- 4 address lines A-D for the pixel rows
        NO_PIXEL_COLUMNS_PER_PANEL : natural := 32  -- number of pixels in one row of one panel
    );
 
    port (
        s_clk_i     : in  std_logic;                -- clock input
        s_reset_n_i : in  std_logic;                -- reset input
        s_wobble_i  : in  std_logic;                -- wobble input for brightness dimming
        s_uart_rx_i : in std_logic;                 -- uart receiver input RX  
        s_data_o    : out std_logic_vector((NO_PANEL_ROWS*6) - 1 downto 0);                     -- RGB output signals (R0/R1, G0/G1, B0/B1) (6 per panel row)
        s_row_o     : out std_logic_vector((NO_PANEL_ROWS*PIXEL_ROW_ADDRESS_BITS)-1 downto 0);  -- output signals for address lines DCBA (4 per panel row)
        s_lat_o     : out std_logic_vector(NO_PANEL_ROWS-1 downto 0);                           -- STB / LATCH output (1 per panel row)
        s_oe_o      : out std_logic_vector(NO_PANEL_ROWS-1 downto 0);                           -- OE output (1 per panel row)
        s_clk_o     : out std_logic_vector(NO_PANEL_ROWS-1 downto 0)                            -- CLK output (1 per panel row)
    );         
       
  
end toplevel;

architecture rtl of toplevel is
    -- constants
    constant C_NO_PANEL_COLUMNS_BIT           : natural := log2ceil(NO_PANEL_COLUMNS);             -- number of bits necessary to represent NO_PANEL_COLUMNS
    constant C_NO_PIXEL_COLUMNS_PER_PANEL_BIT : natural := log2ceil(NO_PIXEL_COLUMNS_PER_PANEL);   -- number of bits necessary to represent NO_PIXEL_COLUMNS_PER_PANEL (32 at the current panels)
    constant C_NO_PANEL_ROWS_BIT              : natural := log2ceil(NO_PANEL_ROWS);                -- number of bits necessary to represent NO_PANEL_ROWS
    constant WADDR_WIDTH                      : natural := C_NO_PANEL_COLUMNS_BIT + PIXEL_ROW_ADDRESS_BITS + C_NO_PANEL_ROWS_BIT + 1 + C_NO_PIXEL_COLUMNS_PER_PANEL_BIT + 1;
    -- end constants
 
    -- matrix driver
    signal s_reset_n : std_logic;
    signal s_clk     : std_logic;
    signal s_locked  : std_logic_vector(1 downto 0);
    signal s_reset   : std_logic;

    signal s_wobble                     : std_logic_vector(1 downto 0);
    signal s_brightcnt, s_brightcnt_nxt : unsigned(27 downto 0);
    signal s_direction                  : std_logic;
    -- end matrix driver
 
    -- UART receiver
    signal s_uart_rx         : std_logic;
    signal s_uart_rx_busy    : std_logic;
    signal s_uart_rx_data    : std_logic_vector(7 downto 0);
    signal s_uart_rx_packet  : std_logic_vector(47 downto 0) := (others => '0');    -- 6 Byte input buffer for RGB packets
    signal s_uart_rx_count   : unsigned(2 downto 0);                                -- to count received bytes
    signal s_uart_data_taken : std_logic := '0';
    signal s_uart_cs         : std_logic_vector(7 downto 0);
 
    signal s_wdata_i         : std_logic_vector(3*8-1 downto 0);    -- 3x8 bit wide RGB output which goes to the decoder for framebuffers
    signal s_waddr_i         : std_logic_vector(C_NO_PANEL_COLUMNS_BIT + PIXEL_ROW_ADDRESS_BITS + C_NO_PANEL_ROWS_BIT + C_NO_PIXEL_COLUMNS_PER_PANEL_BIT + 1 downto 0); -- write address input to decoder for framebuffers (e.g. format at 4x4 panels: "A-TTT-RRRR-PP-XXXXX" -> 15 Bit)
    signal s_we_i            : std_logic;   -- write enable input to decoder for framebuffers
    signal s_wclk_i          : std_logic;   -- write clock (for decoder, UART receiver and framebuffer writing) 
    -- end UART receiver

begin

    -- instantiate the uart entity   
    uart : entity work.uart
        generic map (
            clock => 30000000,          -- clk frequency in Hz
            baudrate => 460800          -- UART baudrate in Bit/s
        )
        port map (
            rxd     => s_uart_rx,       -- uart received serial data
            rx_data => s_uart_rx_data,  -- Received data 
            rx_busy => s_uart_rx_busy,  -- Received data ready to uPC read
            clk     => s_clk            -- Main clock
        );

    -- instantiate the matrix entity
    matrix : entity work.matrix
        generic map (
            NO_PANEL_ROWS => NO_PANEL_ROWS,                             -- number of panel rows
            NO_PANEL_COLUMNS =>  NO_PANEL_COLUMNS,                      -- number of panel columns
            COLORDEPTH => COLORDEPTH,                                   -- colordepth in Bit
            PIXEL_ROW_ADDRESS_BITS => PIXEL_ROW_ADDRESS_BITS,           -- 4 address lines A-D for the pixel rows
            NO_PIXEL_COLUMNS_PER_PANEL => NO_PIXEL_COLUMNS_PER_PANEL    -- number of pixels in one row of one panel
        )
        port map (
            s_clk_i     => s_clk,       -- clock input
            s_reset_n_i => s_reset_n,   -- reset input
            s_wobble_i  => s_wobble_i,  -- wobble input for brightness dimming
            s_wclk_i    => s_wclk_i,    -- framebuffer write clock
            s_waddr_i   => s_waddr_i,   -- framebuffer write adress
            s_wdata_i   => s_wdata_i,   -- framebuffer write data
            s_we_i      => s_we_i,      -- framebuffer write enable
            s_data_o    => s_data_o,    -- RGB output signals (R0/R1, G0/G1, B0/B1) (6 per panel row)
            s_row_o     => s_row_o,     -- output signals for address lines DCBA (4 per panel row)
            s_lat_o     => s_lat_o,     -- STB / LATCH output (1 per panel row)
            s_oe_o      => s_oe_o,      -- OE output (1 per panel row)
            s_clk_o     => s_clk_o
        );
                
    -- uart receive process which fetches the received uart bytes, builds valid RGB packets (considering the checksum CS) and puts out the writing adress, data and write enable for the framebuffer decoder
    p_uart_rx : process(s_wclk_i, s_reset_n)
    begin
        if(s_reset_n = '0') then
            s_we_i <= '0';
            s_uart_rx_count <= (others => '0');
        elsif(rising_edge(s_wclk_i)) then
            s_uart_rx <= s_uart_rx_i;
            s_wdata_i <= (others => '0');
            s_waddr_i <= (others => '0');
            s_we_i <= '0';
   
            if(s_uart_rx_busy = '1') then
                s_uart_data_taken <= '0';
            end if;   
  
            if(s_uart_rx_busy = '0' and s_uart_rx_count < 6 and s_uart_data_taken = '0') then
                s_uart_rx_packet(47-(8*to_integer(s_uart_rx_count)) downto 40-(8*to_integer(s_uart_rx_count))) <= s_uart_rx_data;
                s_uart_data_taken <= '1';
                s_uart_cs <= (s_uart_rx_packet(47 downto 40) xor s_uart_rx_packet(39 downto 32) xor s_uart_rx_packet(31 downto 24) xor s_uart_rx_packet(23 downto 16) xor s_uart_rx_packet(15 downto 8));
                s_uart_rx_count <= s_uart_rx_count + 1;
            elsif(s_uart_rx_count = 6) then   
                if(s_uart_rx_packet(7 downto 0) = s_uart_cs) then   -- if received checksum fits with calculated checksum -> use RGB packet content
                    s_wdata_i <= s_uart_rx_packet(31 downto 8);
                    
                    -- address assignment for input address format: PP TTT RRRR XXXXX:
                    --s_waddr_i(C_NO_PIXEL_COLUMNS_PER_PANEL_BIT-1 downto 0) <= s_uart_rx_packet(40+C_NO_PIXEL_COLUMNS_PER_PANEL_BIT-1 downto 40);             -- X coordinate -> Bit 0 to 4 (44 downto 40)-> s_waddr_i(4 downto 0) (XXXXX of s_waddr_i)
                    --s_waddr_i(WADDR_WIDTH-1 downto WADDR_WIDTH-C_NO_PANEL_COLUMNS_BIT) <= s_uart_rx_packet(40+C_NO_PIXEL_COLUMNS_PER_PANEL_BIT+C_NO_PANEL_COLUMNS_BIT-1 downto 40+C_NO_PIXEL_COLUMNS_PER_PANEL_BIT);       -- X coordinate -> Bit 5 and 6 (46 downto 45)-> s_waddr_i(13 downto 12) (PP of s_waddr_i)
                    --s_waddr_i(C_NO_PIXEL_COLUMNS_PER_PANEL_BIT+PIXEL_ROW_ADDRESS_BITS-1 downto C_NO_PIXEL_COLUMNS_PER_PANEL_BIT) <= s_uart_rx_packet(32+PIXEL_ROW_ADDRESS_BITS-1 downto 32);  -- Y coordinate -> Bit 0 to 3 (35 downto 32)-> s_waddr_i(8 downto 5) (RRRR of s_waddr_i)
                    --s_waddr_i(WADDR_WIDTH-C_NO_PANEL_COLUMNS_BIT-1 downto C_NO_PIXEL_COLUMNS_PER_PANEL_BIT+PIXEL_ROW_ADDRESS_BITS) <= s_uart_rx_packet(32+PIXEL_ROW_ADDRESS_BITS+C_NO_PANEL_ROWS_BIT downto 32+PIXEL_ROW_ADDRESS_BITS); -- Y coordinate -> Bit 4 to 6 (36 downto 38)-> s_waddr_i(11 downto 9) (TTT of s_waddr_i)
                    
                    -- address assignment for input address format: TTT RRRR PP XXXXX:
                    s_waddr_i(C_NO_PIXEL_COLUMNS_PER_PANEL_BIT+C_NO_PANEL_COLUMNS_BIT-1 downto 0) <= s_uart_rx_packet(40+C_NO_PIXEL_COLUMNS_PER_PANEL_BIT+C_NO_PANEL_COLUMNS_BIT-1 downto 40);  -- assign x coordinate of pixel to address part PP XXXXX of s_waddr_i
                    s_waddr_i(C_NO_PIXEL_COLUMNS_PER_PANEL_BIT+C_NO_PANEL_COLUMNS_BIT+PIXEL_ROW_ADDRESS_BITS+C_NO_PANEL_ROWS_BIT+1 downto C_NO_PIXEL_COLUMNS_PER_PANEL_BIT+C_NO_PANEL_COLUMNS_BIT) <= s_uart_rx_packet(32+PIXEL_ROW_ADDRESS_BITS+C_NO_PANEL_ROWS_BIT+1 downto 32);  -- assign y coordinate of pixel to address part A TTT RRRR of s_waddr_i
                    
                    s_we_i <= '1';
                    s_uart_rx_count <= (others => '0'); 
                    s_uart_rx_packet <= (others => '0');
                else    -- synchronize if received checksum did not fit with calculated checksum
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
 
    -- generate clock for the panel
    -- c1 is shifted by 180deg
    pll_i : entity work.pll
        port map (
            areset => s_reset,
            inclk0 => s_clk_i,
            c0     => s_clk,
            locked => s_locked(0)
        );
   
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

    s_wclk_i <= s_clk;
    
end rtl;
