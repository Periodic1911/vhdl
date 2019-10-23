library ieee;
use ieee.std_logic_1164.all; use ieee.numeric_std.all; use ieee.math_real.all;

entity vga_tb is
end;

architecture beh of vga_tb is
signal clk,reset: std_logic;
signal vsync,hsync: std_logic;
signal x: std_logic_vector(9 downto 0);
signal y: std_logic_vector(8 downto 0);
signal vis: std_logic;
begin
	uut: entity work.vga
	port map(
	clk=>clk,reset=>reset,
	vsync=>vsync,hsync=>hsync,
	x=>x,y=>y,vis=>vis
	);

	clkp: process is
	begin
		clk <= '0'; wait for 5 ns;
		clk <= '1'; wait for 5 ns;
	end process;

	stim: process is
	begin
		reset <= '1';
		wait for 100 ns;
		reset <= '0';
		wait;
	end process;
end beh;
