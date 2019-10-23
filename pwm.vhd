library ieee;
use ieee.std_logic_1164.all; use ieee.numeric_std.all; use ieee.math_real.all;

entity pwm is
	port(
	clk,reset:	in	STD_LOGIC;
	val:		in	STD_LOGIC_VECTOR(7 downto 0);
	q:		out	STD_LOGIC
	);
end;

architecture beh of pwm is
signal cnt: std_logic_vector(7 downto 0);
begin
	q <= '1' when (unsigned(val) > unsigned(cnt)) else '0';
	process is
	begin
		wait until rising_edge(clk);
		cnt <= std_logic_vector(unsigned(cnt)+1);
		if(reset = '1') then
			cnt <= (others => '0');
		end if;
	end process;
		
end beh;
