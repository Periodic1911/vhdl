library ieee;
use ieee.std_logic_1164.all; use ieee.numeric_std.all; use ieee.math_real.all;

entity ram is
	generic(width: integer := 8; space: integer := 16);
	port(
	clk,reset:	in	STD_LOGIC;
	addr:		in	STD_LOGIC_VECTOR(space-1 downto 0);
	w:		in	STD_LOGIC_VECTOR(width-1 downto 0);
	d:		out	STD_LOGIC_VECTOR(width-1 downto 0);
	we:		in	STD_LOGIC
	);
end;

architecture beh of ram is
type ramtype is array((2**space)-1 downto 0) of std_logic_vector(width-1 downto 0);
signal mem: ramtype;
begin
	process (we,addr,w) is
	begin
		if(we = '1') then
			mem(to_integer(unsigned(addr))) <= w;
		end if;
		d <= mem(to_integer(unsigned(addr)));
	end process;
		
end beh;
