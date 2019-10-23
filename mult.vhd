-- DOESNT WORK IN SYNTHESIS
-- does in simulation (could do 10*11)
library ieee;
use ieee.std_logic_1164.all; use ieee.numeric_std.all;

entity mult is
	generic(wa: integer := 8; wb: integer := 8);
	port(
	clk,reset:	in	STD_LOGIC;
	go:		in	STD_LOGIC;
	a:		in	STD_LOGIC_VECTOR(wa-1 downto 0);
	b:		in	STD_LOGIC_VECTOR(wb-1 downto 0);
	q:		out	STD_LOGIC_VECTOR(wa+wb-1 downto 0);
	rdy:		out	STD_LOGIC
	);
end;

architecture beh of mult is
signal tempq:	STD_LOGIC_VECTOR(wa+wb-1 downto 0);
signal tempa:	STD_LOGIC_VECTOR(wa-1 downto 0);
signal tempb:	STD_LOGIC_VECTOR(wa+wb-1 downto 0);
type statetype is (ready, working);
signal state:	statetype;
begin
	process is
	begin
		wait until rising_edge(clk);

		case state is
		when working =>
			if(unsigned(tempa) = 0) then
				state <= ready;
			elsif(tempa(0) = '1') then
				tempq <= std_logic_vector(resize(unsigned(tempb)+unsigned(tempq),wa+wb));
			end if;
			
			q <= (others => '0');
			rdy <= '0';
			tempa <= '0' & tempa(wa-1 downto 1);
			tempb <= tempb(wa+wb-2 downto 0) & '0';
		when ready =>
			q <= tempq;
			rdy <= '1';
			if(go = '1') then
				state <= working;
			end if;
		end case;

		if(go = '1') then
			tempb <= std_logic_vector(resize(unsigned(b),wa+wb));
			tempa <= a;
			tempq <= (others => '0');
			state <= working;
		end if;

		if(reset = '1') then
			q <= (others => '0');
			state <= working;
		end if;
	end process;
end beh;
