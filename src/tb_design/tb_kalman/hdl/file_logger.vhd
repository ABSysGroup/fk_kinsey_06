--
-- VHDL Architecture tb_kalman.kalman_filter_tester.test
--
-- Created:
--          by - Fernando.UNKNOWN (FERNANDO-LAPTOP)
--          at - 22:13:32 25/04/2015
--
-- using Mentor Graphics HDL Designer(TM) 2012.1 (Build 6)
--

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
use ieee.numeric_std.ALL;
use IEEE.std_logic_textio.all;
library STD;
use STD.textio.all;
library common;
use common.constants.all;

entity file_logger is
   generic( 
      archivo_entrada : string := "T:\TFG2015\src\tb_design\tb_common\text\tb_entrada_kalman_filter.txt";
      archivo_salida  : string := "T:\TFG2015\src\tb_design\tb_common\text\tb_salida_kalman_filter.txt"
   );
   port( 
      clk            : in     std_logic;
      rst            : in     std_logic;
      xpo_data_out   : in     std_logic_vector (15 downto 0);
      xpo_write_fifo : in     std_logic;
      z_f            : out    std_logic_vector (15 downto 0);
      z_f_ready      : out    std_logic
   );

-- Declarations

end file_logger ;

--

architecture beh OF file_logger is
    file stimulus: TEXT open read_mode is archivo_entrada;
    signal first_time : boolean := true;
    signal xpo_write_fifo_d1 : std_logic;
begin

p_xpo_write_fifo : process (clk)
begin
  if rising_edge(clk) then
    if rst = '1' then
      xpo_write_fifo_d1 <= '0';
    else
      xpo_write_fifo_d1 <= xpo_write_fifo;
    end if;
  end if;
end process p_xpo_write_fifo;

p_read : process(clk)
	variable l: line;
	variable s: std_logic_vector(15 downto 0);
	variable read_ok : boolean;
	begin
	if rising_edge(clk) then
		if(rst = '1')then
			report "Reset p_read";
			z_f   <= (others => '0');
			z_f_ready <= '0';          
		elsif ((xpo_write_fifo_d1 = '0' and xpo_write_fifo = '1') or (first_time = true)) and (not endfile(stimulus)) then
		  first_time <= false;
		  readline(stimulus,l);
			read(l,s,read_ok);
			assert read_ok
			  report "Error during file reading: " & l.all
			  severity warning;
			z_f   <= s;
			z_f_ready <= '1', '0' after 20 ns;
		end if;
	end if;
end process p_read;  
	
--p_write : process(clk)
--	file matrixout : text open write_mode is archivo_salida;
--  variable linea : line;
--begin
--    if rising_edge(clk) then
--    		if(rst = '1')then
--    			report "Write reset";
--    		elsif (not(xpo_write_fifo'stable(10ns)) and xpo_write_fifo = '0') then
--    			write(linea, xpo_data_out);
--    			writeline(matrixout, linea);
--    		end if;
--    end if;
--end process p_write;                                                                                    

--p_write : process(xpo_write_fifo)
--	file matrixout : text open write_mode is archivo_salida;
--  variable xpo_data_out_line : line;
--begin
--    if falling_edge(xpo_write_fifo) then
--    			write(xpo_data_out_line, xpo_data_out);
--    			writeline(matrixout, xpo_data_out_line);
--    end if;
--end process p_write;

p_write : process
	file matrixout             : text open write_mode is archivo_salida;
  variable xpo_data_out_line : line;
  constant space : string := "   ";
begin
  wait until rising_edge(xpo_write_fifo);
  
  wait until rising_edge(clk);
  write(xpo_data_out_line, xpo_data_out);
  write(xpo_data_out_line, space);
  
  wait until rising_edge(clk);
  write(xpo_data_out_line, xpo_data_out);
  write(xpo_data_out_line, space);
  
  wait until rising_edge(clk);
  write(xpo_data_out_line, xpo_data_out);
  write(xpo_data_out_line, space);
  
  wait until rising_edge(clk);
  write(xpo_data_out_line, xpo_data_out);
  write(xpo_data_out_line, space);
  
  writeline(matrixout, xpo_data_out_line);
end process p_write;                                                                                 
    
END ARCHITECTURE beh;
