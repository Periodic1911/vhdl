library ieee;
use ieee.std_logic_1164.all; use ieee.numeric_std.all; use ieee.math_real.all;

entity pwm_tb is
end;

architecture beh of pwm_tb is
signal val: std_logic_vector(7 downto 0);
signal q,clk,reset: std_logic;
begin
	uut: entity work.pwm
	port map(clk=>clk,reset=>reset,q=>q,val=>val);
	process is
	begin
		clk <= '0'; wait for 5 ns;
		clk <= '1'; wait for 5 ns;
	end process;

	process is
	begin
		reset <= '1';
		wait for 20 ns;
		reset <= '0';
		val <= x"F0";
		wait for 2560*2 ns;
		val <= x"20";
		wait for 2560*2 ns;
		val <= x"00";
		wait for 2560*2 ns;
		val <= x"FF";
		wait;
	end process;
		
end beh;
