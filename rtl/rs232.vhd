-- ADAFRUITMATRIX -- FPGA design to drive combinations of 32x32 RGB LED Matrices
--
-- UART Receiver - Source: http://www.lothar-miller.de/s9y/categories/42-RS232
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
-- Last modified: 15.04.2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RS232 is
    Generic ( Quarz_Taktfrequenz : integer   := 40000000;  -- Hertz 
              Baudrate           : integer   :=  9600      -- Bits/Sec
             ); 
    Port ( RXD      : in   STD_LOGIC;
           RX_Data  : out  STD_LOGIC_VECTOR (7 downto 0);
           RX_Busy  : out  STD_LOGIC;
           CLK      : in   STD_LOGIC
           );
end RS232;

architecture Behavioral of RS232 is
signal rxd_sr  : std_logic_vector (3 downto 0) := "1111";         -- Flankenerkennung und Eintakten
signal rxsr    : std_logic_vector (7 downto 0) := "00000000";     -- 8 Datenbits
signal rxbitcnt : integer range 0 to 9 := 0;
signal rxcnt   : integer range 0 to (Quarz_Taktfrequenz/Baudrate)-1; 

begin   
   process begin
      wait until rising_edge(CLK);
      rxd_sr <= rxd_sr(rxd_sr'left-1 downto 0) & RXD;
      if (rxbitcnt<9) then    -- Empfang läuft
         if(rxcnt<(Quarz_Taktfrequenz/Baudrate)-1) then 
            rxcnt    <= rxcnt+1;
         else
            rxcnt    <= 0; 
            rxbitcnt <= rxbitcnt+1;
            rxsr     <= rxd_sr(rxd_sr'left-1) & rxsr(rxsr'left downto 1); -- rechts schieben, weil LSB first
         end if;
      else -- warten auf Startbit
         if (rxd_sr(3 downto 2) = "10") then                 -- fallende Flanke Startbit
            rxcnt    <= ((Quarz_Taktfrequenz/Baudrate)-1)/2; -- erst mal nur halbe Bitzeit abwarten
            rxbitcnt <= 0;
         end if;
      end if;
   end process;
   RX_Data <= rxsr;
   RX_Busy <= '1' when (rxbitcnt<9) else '0';
end Behavioral;