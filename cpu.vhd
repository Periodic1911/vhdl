library ieee;
use ieee.std_logic_1164.all; use ieee.numeric_std.all; use ieee.math_real.all;

entity cpu is
	port(
	clk,reset:	in	STD_LOGIC;
	addr:		out	STD_LOGIC_VECTOR(16-1 downto 0);
	d:		in	STD_LOGIC_VECTOR(8-1 downto 0);
	w:		out	STD_LOGIC_VECTOR(8-1 downto 0);
	we:		out	STD_LOGIC
	);
end;

architecture beh of cpu is
signal a,x,op : std_logic_vector(8-1 downto 0);
signal ctrl : std_logic_vector(1 downto 0);
signal ra,wa,rx,wx,pce1,pce2,pci,pcw,ade1,ade2,adw,ce,a2p : std_logic;
signal adi: std_logic_vector(1 downto 0);
signal alu : std_logic_vector(3 downto 0);
signal c,z: std_logic;

signal aluq,xq: std_logic_vector(8-1 downto 0);

signal pc, ad: std_logic_vector(16-1 downto 0);
begin

	addr <= pc when pcw = '1' else (others => 'Z');
	addr <= ad when adw = '1' else (others => 'Z');
	regs: process is
	begin
		wait until rising_edge(clk);
		--w <= x"00";
		ctrl <= "ZZ";
		if(wa = '1') then a <= aluq; end if;
		if(wx = '1') then x <= aluq; end if;
		if(pce1 = '1') then pc(8-1 downto 0) <= aluq; end if;
		if(pce2 = '1') then pc(16-1 downto 8) <= aluq; end if;
		if(ade1 = '1') then ad(8-1 downto 0) <= aluq; end if;
		if(ade2 = '1') then ad(16-1 downto 8) <= aluq; end if;
		if(ce = '1') then op <= d; end if;
		if(a2p = '1') then pc <= ad; end if;
		if(pci = '1') then
			pc <= std_logic_vector(resize(unsigned(pc)+1,16));
		end if;
		if(reset = '1') then
			pc <= x"FFFE";
			ad <= (others => '0');
			a <= (others => '0');
			x <= (others => '0');
			ctrl <= (others => '0');
			op <= x"07"; --JMP I
		end if;
	end process;

	alup: process(rx,ra,d) is
	variable alua: std_logic_vector(8-1 downto 0);
	begin
		alua := x"00";
		if(rx = '1') then alua := x; end if;
		if(ra = '1') then alua := a; end if;

		aluq <= (others => '0');
		c<='0';z<='0';
		case alu is
		when x"0" => aluq <= alua; --A
		when x"1" => aluq <= d; --B
		when x"2" => --A+B
			aluq <= std_logic_vector(resize(unsigned(alua)+unsigned(d),8));
			c <= alua(7) and d(7);
		when x"3" => aluq <= (others => '0'); --0
		when x"4" => --ROR A
			aluq <= alua(0) & alua(8-2 downto 0);
			c <= alua(0);
		when x"5" => --ROL A
			aluq <= alua(8-1 downto 1) & alua(8-1);
			c <= alua(8-1);
		when x"6" => --RS A
			aluq <= alua(0) & alua(8-2 downto 0);
		when x"7" => --LS A
			aluq <= alua(8-1 downto 1) & alua(8-1);
		when x"8" => --A and B
			aluq <= alua and d;
		when x"9" => --A or B
			aluq <= alua or d;
		when x"A" => --A xor B
			aluq <= alua xor d;
		when x"B" => --not A
			aluq <= not alua;
		when x"C" => --2's complement A
			aluq <= std_logic_vector(resize(unsigned(not alua)+1,8));
		when others =>
		end case;
	end process;
	z <= '1' when aluq = x"00" else '0';

	-- this is a big one
	decode: process is
	begin
		wait until rising_edge(clk);
		--defaults
		ctrl <= "ZZ";
		ra<='Z';wa<='Z';we<='Z';alu<="ZZZZ";pce1<='Z';pce2<='Z';pci<='Z';a2p<='Z';
		rx<='Z';wx<='Z';pcw<='Z';ade1<='Z';ade2<='Z';adw<='Z';adi<="ZZ";ce<='Z';
		case op is
		when x"00" => --NOP
			ce<='1';pci<='1';pcw<='1';
		when x"01" => --ADD I
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= "01";
		when "01" => --load address high byte
			alu<="0001";ade2<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			alu<="0010";ra<='1';wa<='1';adw<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"02" => --ADD I+R
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= "01";
		when "01" => --load address high byte
			alu<="0001";ade2<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			alu<="0010";ra<='1';wa<='1';adw<='1';adi<="10";
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"03" => --ADD ZP
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			alu<="0001";ade2<='1';pci<='1';pcw<='1';adi<="01";
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"07"  => --JMP I
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= "01";
		when "01" => --load address high byte
			alu<="0001";ade2<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			a2p<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"08"  => --JMPC I
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= not c & '1';
		when "01" => --load address high byte
			alu<="0001";ade2<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			a2p<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"09"  => --JMPNC I
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= c & '1';
		when "01" => --load address high byte
			alu<="0001";ade2<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			a2p<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"0A"  => --JMPZ I
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= not z & '1';
		when "01" => --load address high byte
			alu<="0001";ade2<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			a2p<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"0B"  => --JMPNZ I
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= z & '1';
		when "01" => --load address high byte
			alu<="0001";ade2<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			a2p<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"0C"  => --ROR
			ra<='1';wa<='1';alu<="0100";
			ce<='1';pci<='1';pcw<='1';
		when x"0D"  => --ROL
			ra<='1';wa<='1';alu<="0100";
			ce<='1';pci<='1';pcw<='1';
		when x"0E"  => --RSA
			ra<='1';wa<='1';alu<="0110";
			ce<='1';pci<='1';pcw<='1';
		when x"0F"  => --LSA
			ra<='1';wa<='1';alu<="0111";
			ce<='1';pci<='1';pcw<='1';
		when x"10"  => --SXA
			rx<='1';wa<='1';alu<="0000";
			ce<='1';pci<='1';pcw<='1';
		when x"11"  => --SAX
			ra<='1';wx<='1';alu<="0000";
			ce<='1';pci<='1';pcw<='1';
		when x"12"  => --CLX
			wx<='1';alu<="0011";
			ce<='1';pci<='1';pcw<='1';
		when x"13"  => --CLA
			wa<='1';alu<="0011";
			ce<='1';pci<='1';pcw<='1';
		when x"14" => --STA I
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= "01";
		when "01" => --load address high byte
			alu<="0001";ade2<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			alu<="0001";ra<='1';adi<="00";adw<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"15" => --STA I+R
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= "01";
		when "01" => --load address high byte
			alu<="0001";ade2<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			alu<="0001";ra<='1';adi<="10";adw<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"16" => --STA ZP
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			alu<="0001";ra<='1';adi<="01";adw<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"17"  => --LDA I
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= "01";
		when "01" => --load address high byte
			alu<="0001";ade2<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			alu<="0000";we<='1';wa<='1';adi<="00";adw<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"18"  => --LDA I+R
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= "01";
		when "01" => --load address high byte
			alu<="0001";ade2<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			alu<="0000";we<='1';wa<='1';adi<="10";adw<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"19"  => --LDA ZP
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			alu<="0000";we<='1';wa<='1';adi<="01";adw<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"1A"  => --STX I
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= "01";
		when "01" => --load address high byte
			alu<="0001";ade2<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			alu<="0000";rx<='1';adi<="00";adw<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"1B"  => --STX I+R
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= "01";
		when "01" => --load address high byte
			alu<="0001";ade2<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			alu<="0000";rx<='1';adi<="10";adw<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"1C"  => --STX ZP
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			alu<="0000";rx<='1';adi<="01";adw<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"1D"  => --LDX I
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= "01";
		when "01" => --load address high byte
			alu<="0001";ade2<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			we<='1';alu<="0000";wx<='1';adi<="00";adw<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"1E"  => --LDX I+R
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= "01";
		when "01" => --load address high byte
			alu<="0001";ade2<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			we<='1';alu<="0000";wx<='1';adi<="10";adw<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"1F"  => --LDX ZP
		case ctrl is
		when "00" => --load address low byte
			alu<="0001";ade1<='1';pci<='1';pcw<='1';
			ctrl <= "10";
		when "10" => --execute
			we<='1';alu<="0000";wx<='1';adi<="01";adw<='1';
			ctrl <= "11";
		when "11" => --load next
			ce<='1';pci<='1';pcw<='1';
			ctrl <= "00";
		when others =>
		end case;
		when x"20"  => --CLAX
			rx<='1';ra<='1';alu<="0011";
			ce<='1';pci<='1';pcw<='1';
		when others =>
		end case;
		if(reset = '1') then
			ctrl <= "ZZ";
			ra<='Z';wa<='Z';we<='Z';alu<="ZZZZ";pce1<='Z';pce2<='Z';pci<='Z';a2p<='Z';
			rx<='Z';wx<='Z';pcw<='Z';ade1<='Z';ade2<='Z';adw<='Z';adi<="ZZ";ce<='Z';
		end if;
	end process;
		
end beh;
