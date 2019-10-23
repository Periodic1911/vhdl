library ieee;
use ieee.std_logic_1164.all; use ieee.numeric_std.all; use ieee.math_real.all;

entity cpu_tb is
end;

architecture beh of cpu_tb is
signal clk,cpureset,ramreset: std_logic;
signal addr,cpuaddr: std_logic_vector(15 downto 0);
signal d,w,cpuw: std_logic_vector(7 downto 0);
signal we,cpuwe: std_logic;
signal con: std_logic;
begin
	uut: entity work.cpu
	port map(
	clk=>clk,reset=>cpureset,
	addr=>cpuaddr,
	d=>d,
	w=>cpuw,
	we=>cpuwe
	);

	ram: entity work.ram
	port map(
	clk=>clk,reset=>ramreset,
	addr=>addr,
	w=>w,
	d=>d,
	we=>we
	);

	clkp: process is
	begin
		clk <= '0'; wait for 5 ns;
		clk <= '1'; wait for 5 ns;
	end process;

	stim: process is
	begin
		cpureset <= '1';
		ramreset <= '1';
		con <= '0';
		wait for 100 ns;
		ramreset <= '0';
		addr<=x"4001";w<=x"01";we<='1'; wait for 10 ns;
		addr<=x"4002";w<=x"23";we<='1'; wait for 10 ns;
		addr<=x"4003";w<=x"11";we<='1'; wait for 10 ns;
		addr<=x"1123";w<=x"DE";we<='1'; wait for 10 ns;
		addr<=x"FFFE";w<=x"01";we<='1'; wait for 10 ns;
		addr<=x"FFFF";w<=x"40";we<='1'; wait for 10 ns;
		addr<=(others => 'Z');
		we<= 'Z';
		w<=(others => 'Z');
		con <= '1';
		cpureset <= '0';
		wait;
	end process;

	connect: process is
	begin
		addr<=(others => 'Z');
		we<= 'Z';
		w<=(others => 'Z');
		if(con = '1') then
			we <= cpuwe;w <= cpuw;addr <= cpuaddr;
		end if;
		wait for 1 ns;
	end process;
end beh;
