-- ADAFRUITMATRIX -- FPGA design to drive combinations of 32x32 RGB LED Matrices
--
-- UART Receiver - modified from: http://www.lothar-miller.de/s9y/categories/42-RS232
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

-- UART receiver entity
-- Last modified: 28.04.2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart is

    generic ( 
        clock    : integer   := 30000000;   -- Hz
        baudrate : integer   :=  460800     -- bits/sec
    ); 
    
    port ( 
        rxd     : in   STD_LOGIC;
        rx_data : out  STD_LOGIC_VECTOR (7 downto 0);
        rx_busy : out  STD_LOGIC;
        clk     : in   STD_LOGIC
    );
    
end uart;

architecture behavioral of uart is

    signal rxd_sr   : std_logic_vector (3 downto 0) := "1111";      -- shift register for edge detection
    signal rxsr     : std_logic_vector (7 downto 0) := "00000000";  -- 8 data bits
    signal rxbitcnt : integer range 0 to 9 := 0;                    -- counter for the received bits
    signal rxcnt    : integer range 0 to (clock/baudrate)-1;        -- counter for the samples (uart bits get sampled with clock rate)

begin  
	
    -- process which samples the UART input (rxd) to get the 8 data bits; valid bit values (0 or 1) are always taken in the middle of a uart input bit
    process begin
        wait until rising_edge(clk);
            rxd_sr <= rxd_sr(rxd_sr'left-1 downto 0) & rxd;     -- move lower 3 bits of rxd_sr to the left and concatenate current sample (rxd) to the LSB position
        if (rxbitcnt<9) then                                    -- reception of UART frame ongoing
            if(rxcnt<(clock/baudrate)-1) then                   -- count up samples of current bit
                rxcnt    <= rxcnt+1;
            else                                                -- if current bit is sampleded completely (clock/baudrate samples) - increase bit counter and add value of current bit to the left side of rxsr
                rxcnt    <= 0;
                rxbitcnt <= rxbitcnt+1;
                rxsr     <= rxd_sr(rxd_sr'left-1) & rxsr(rxsr'left downto 1); -- on the UART line (rxd) the LSB is sent first, therefore the currently received bit is always concatenated on the left side
            end if;
        else -- wait for start bit
            if (rxd_sr(3 downto 2) = "10") then         -- if a falling edge is detected -> start bit is received
                rxcnt    <= ((clock/baudrate)-1)/2;     -- preload the sample counter with half bit time to take valid bit values always in the middle of an input uart bit
                rxbitcnt <= 0;
            end if;
        end if;
    end process;
  
    rx_data <= rxsr;                                -- received UART frame (8 data bits) is valid when rx_busy gets 0
    rx_busy <= '1' when (rxbitcnt<9) else '0';      -- while reception of the UART frame rx_busy is high, once all 8 data bits are ready rx_busy is set to low

end behavioral;