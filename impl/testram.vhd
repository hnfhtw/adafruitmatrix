-- ADAFRUITMATRIX -- FPGA design to drive combinations of 32x32 RGB LED Matrices
--
-- Copyright (C) 2016  Harald Netzer
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

-- RAM entity (simple dual-port RAM with two read/write addresses and clocks)
-- Last modified: 01.04.2016

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity testram is

	generic 
	(
		DATA_WIDTH : natural := 24;
		DATA_RANGE : natural := 2048;
		init_file : string
	);

	port 
	(
		rclk	: in std_logic;
		wclk	: in std_logic;
		raddr	: in std_logic_vector((natural(ceil(log2(real(DATA_RANGE))))-1) downto 0);
		waddr	: in std_logic_vector((natural(ceil(log2(real(DATA_RANGE))))-1) downto 0);
		data	: in std_logic_vector((DATA_WIDTH-1) downto 0);
		we		: in std_logic := '1';
		q		: out std_logic_vector((DATA_WIDTH -1) downto 0)
	);

end testram;

architecture rtl of testram is

	-- Build a 2-D array type for the RAM
	subtype word_t is std_logic_vector((DATA_WIDTH-1) downto 0);
	type memory_t is array(DATA_RANGE-1 downto 0) of word_t;
	
	-- Declare the RAM signal.	
	signal ram : memory_t;
	
	attribute ram_init_file : string;
	attribute ram_init_file of ram :
	signal is init_file;

begin

	process(wclk)
	begin
	if(rising_edge(wclk)) then 
		if(we = '1') then
			ram(to_integer(unsigned(waddr))) <= data;
		end if;
	end if;
	end process;

	process(rclk)
	begin
	if(rising_edge(rclk)) then 
		q <= ram(to_integer(unsigned(raddr)));
	end if;
	end process;

end rtl;
