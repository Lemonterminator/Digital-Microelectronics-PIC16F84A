library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library work;
use work.alu_pkg.all;

entity tb_ex04 is
end entity tb_ex04;

architecture behavioral of tb_ex04 is

  signal a          : std_logic_vector(7 downto 0) := (others => '0');
  signal b          : std_logic_vector(7 downto 0) := (others => '0');
  signal op         : alu_op := NOP;
  signal bit_select : std_logic_vector(2 downto 0) := (others => '0');
  signal status_in  : std_logic_vector(2 downto 0) := (others => '0');
  signal status     : std_logic_vector(2 downto 0) := (others => '0');
  signal result     : std_logic_vector(7 downto 0) := (others => '0');
  signal skip_next  : std_logic := '0';

  file input_file  : text open read_mode is "input.txt";
  file output_file : text open write_mode is "output.txt";

  function matches_name(lhs : string; rhs : string) return boolean is
  begin
    if lhs'length < rhs'length then
      return false;
    end if;

    if lhs(lhs'low to lhs'low + rhs'length - 1) /= rhs then
      return false;
    end if;

    if lhs'length > rhs'length then
      for index in lhs'low + rhs'length to lhs'high loop
        if lhs(index) /= ' ' then
          return false;
        end if;
      end loop;
    end if;

    return true;
  end function matches_name;

  function to_alu_op(name : string) return alu_op is
  begin
    if matches_name(name, "ADDWF") then
      return ADDWF;
    elsif matches_name(name, "ANDWF") then
      return ANDWF;
    elsif matches_name(name, "ADDLW") then
      return ADDLW;
    elsif matches_name(name, "ANDLW") then
      return ANDLW;
    elsif matches_name(name, "BCF") then
      return BCF;
    elsif matches_name(name, "BTFSC") then
      return BTFSC;
    elsif matches_name(name, "BSF") then
      return BSF;
    elsif matches_name(name, "BTFSS") then
      return BTFSS;
    elsif matches_name(name, "CLRF") then
      return CLRF;
    elsif matches_name(name, "CLRW") then
      return CLRW;
    elsif matches_name(name, "COMF") then
      return COMF;
    elsif matches_name(name, "DECF") then
      return DECF;
    elsif matches_name(name, "DECFSZ") then
      return DECFSZ;
    elsif matches_name(name, "INCF") then
      return INCF;
    elsif matches_name(name, "INCFSZ") then
      return INCFSZ;
    elsif matches_name(name, "IORLW") then
      return IORLW;
    elsif matches_name(name, "MOVF") then
      return MOVF;
    elsif matches_name(name, "MOVWF") then
      return MOVWF;
    elsif matches_name(name, "CALL") then
      return CALL;
    elsif matches_name(name, "GOTO") then
      return GOTO;
    elsif matches_name(name, "MOVLW") then
      return MOVLW;
    elsif matches_name(name, "RETLW") then
      return RETLW;
    elsif matches_name(name, "RETUR") then
      return RETUR;
    elsif matches_name(name, "IORWF") then
      return IORWF;
    elsif matches_name(name, "NOP") then
      return NOP;
    elsif matches_name(name, "RLF") then
      return RLF;
    elsif matches_name(name, "RRF") then
      return RRF;
    elsif matches_name(name, "SUBLW") then
      return SUBLW;
    elsif matches_name(name, "SUBWF") then
      return SUBWF;
    elsif matches_name(name, "SWAPF") then
      return SWAPF;
    elsif matches_name(name, "XORLW") then
      return XORLW;
    elsif matches_name(name, "XORWF") then
      return XORWF;
    end if;

    assert false report "Unknown ALU opcode in input file: " & name severity failure;
    return NOP;
  end function to_alu_op;

begin

  uut : entity work.alu
    port map (
      a          => a,
      b          => b,
      op         => op,
      bit_select => bit_select,
      status_in  => status_in,
      status     => status,
      result     => result,
      skip_next  => skip_next
    );

  stim_proc : process
    variable in_line      : line;
    variable out_line     : line;
    variable line_content : string(1 to 120);
    variable line_length  : natural;
    variable op_name      : string(1 to 10);
    variable a_int        : integer;
    variable b_int        : integer;
    variable bs_int       : integer;
    variable st_int       : integer;
    variable idx          : natural;
  begin
    while not endfile(input_file) loop
      readline(input_file, in_line);

      line_content := (others => ' ');
      line_length := in_line'length;
      if line_length > 120 then
        line_length := 120;
      end if;
      line_content(1 to line_length) := in_line.all(1 to line_length);

      idx := 1;
      while (idx <= line_length) and (line_content(idx) /= ' ') loop
        idx := idx + 1;
      end loop;

      op_name := (others => ' ');
      if idx > 1 then
        op_name(1 to idx - 1) := line_content(1 to idx - 1);
      end if;

      while (idx <= line_length) and (line_content(idx) = ' ') loop
        idx := idx + 1;
      end loop;

      a_int := 0;
      while (idx <= line_length) and (line_content(idx) >= '0') and (line_content(idx) <= '9') loop
        a_int := a_int * 10 + (character'pos(line_content(idx)) - character'pos('0'));
        idx := idx + 1;
      end loop;

      while (idx <= line_length) and (line_content(idx) = ' ') loop
        idx := idx + 1;
      end loop;

      b_int := 0;
      while (idx <= line_length) and (line_content(idx) >= '0') and (line_content(idx) <= '9') loop
        b_int := b_int * 10 + (character'pos(line_content(idx)) - character'pos('0'));
        idx := idx + 1;
      end loop;

      while (idx <= line_length) and (line_content(idx) = ' ') loop
        idx := idx + 1;
      end loop;

      bs_int := 0;
      while (idx <= line_length) and (line_content(idx) >= '0') and (line_content(idx) <= '9') loop
        bs_int := bs_int * 10 + (character'pos(line_content(idx)) - character'pos('0'));
        idx := idx + 1;
      end loop;

      while (idx <= line_length) and (line_content(idx) = ' ') loop
        idx := idx + 1;
      end loop;

      st_int := 0;
      while (idx <= line_length) and (line_content(idx) >= '0') and (line_content(idx) <= '9') loop
        st_int := st_int * 10 + (character'pos(line_content(idx)) - character'pos('0'));
        idx := idx + 1;
      end loop;

      op         <= to_alu_op(op_name);
      a          <= std_logic_vector(to_unsigned(a_int, 8));
      b          <= std_logic_vector(to_unsigned(b_int, 8));
      bit_select <= std_logic_vector(to_unsigned(bs_int, 3));
      status_in  <= std_logic_vector(to_unsigned(st_int, 3));

      wait for 10 ns;

      out_line := null;
      write(out_line, string'("Operation: "));
      write(out_line, op_name);
      write(out_line, string'(" | operand_a: "));
      write(out_line, a_int);
      write(out_line, string'(" | operand_b: "));
      write(out_line, b_int);
      write(out_line, string'(" | Result: "));
      write(out_line, to_integer(unsigned(result)));
      write(out_line, string'(" | Status: "));
      write(out_line, to_integer(unsigned(status)));
      write(out_line, string'(" | Skip: "));
      if skip_next = '1' then
        write(out_line, 1);
      else
        write(out_line, 0);
      end if;
      writeline(output_file, out_line);
    end loop;

    wait;
  end process stim_proc;

end architecture behavioral;
