-- ADAFRUITMATRIX -- FPGA design to drive combinations of 32x32 RGB LED Matrices
--
-- Copyright (C) 2016  Harald Netzer (Source: http://electronics.stackexchange.com/questions/183765/standard-integer-width-function-in-vhdl)
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

-- Package containing calculation functions
-- Last modified: 28.04.2016

package calc_pkg is
    function log2ceil(arg : positive) return natural; 
end package calc_pkg;

package body calc_pkg is
    function log2ceil(arg : positive) return natural is     -- log2 function to calculate data widths in bits
        variable tmp : positive     := 1;
        variable log : natural      := 0;
        begin
            if arg = 1 then return 0; end if;
            while arg > tmp loop
                tmp := tmp * 2;
                log := log + 1;
            end loop;
        return log;
    end function;
end package body;
