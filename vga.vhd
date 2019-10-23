library ieee;
use ieee.std_logic_1164.all; use ieee.numeric_std.all;

entity vga is
	port(
	clk,reset:	in	STD_LOGIC;
	x:		out	STD_LOGIC_VECTOR(9 downto 0);
	y:		out	STD_LOGIC_VECTOR(8 downto 0);
	vis:		out	STD_LOGIC;
	hsync,vsync:	out	STD_LOGIC
	);
end;

architecture beh of vga is
signal hcnt,vcnt:	STD_LOGIC_VECTOR(9 downto 0);
begin
	x <= hcnt;
	y <= vcnt(8 downto 0);

	process (hcnt,vcnt) is
	begin
		vis <= '0';
		if(unsigned(hcnt) < 640 and unsigned(vcnt) < 480) then
			vis <= '1';
		end if;

		hsync <= '1';
		if(unsigned(hcnt) > 656 and unsigned(hcnt) <= 752) then
			hsync <= '0';
		end if;

		vsync <= '1';
		if(unsigned(vcnt) > 490 and unsigned(vcnt) <= 492) then
			vsync <= '0';
		end if;
	end process;

	process is
	begin
		wait until rising_edge(clk);
		hcnt <= std_logic_vector(unsigned(hcnt)+1);
		if(unsigned(hcnt) = 800) then
			hcnt <= (others => '0');
			vcnt <= std_logic_vector(unsigned(vcnt)+1);
			if(unsigned(vcnt) = 525) then
		       		vcnt <= (others => '0');
			end if;	       
		end if;	  
		if(reset = '1') then
			hcnt <= (others => '0');
			vcnt <= (others => '0');
		end if;     
		
	end process;
		
end beh;
