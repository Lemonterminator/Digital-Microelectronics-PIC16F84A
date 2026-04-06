library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library work;
use work.alu_pkg.all;

entity tb_ex05 is
end entity tb_ex05;

architecture behavioral of tb_ex05 is

  signal clk          : std_logic := '0';
  signal addr         : std_logic_vector(6 downto 0) := (others => '0');
  signal op           : alu_op := NOP;
  signal w_in         : std_logic_vector(7 downto 0) := (others => '0');
  signal mem_re       : std_logic := '0';
  signal mem_we       : std_logic := '0';
  signal bit_select   : std_logic_vector(2 downto 0) := (others => '0');
  signal mem_data_out : std_logic_vector(7 downto 0) := (others => '0');

  signal chk_clk      : std_logic := '0';
  signal chk_we       : std_logic := '0';
  signal chk_re       : std_logic := '0';
  signal chk_d        : std_logic_vector(7 downto 0) := (others => '0');
  signal chk_d_status : std_logic_vector(7 downto 0) := (others => '0');
  signal chk_addr     : std_logic_vector(6 downto 0) := (others => '0');
  signal chk_q        : std_logic_vector(7 downto 0) := (others => '0');
  signal chk_q_status : std_logic_vector(2 downto 0) := (others => '0');

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

  uut : entity work.toplevel_alu_mem
    port map (
      clk          => clk,
      addr         => addr,
      op           => op,
      w_in         => w_in,
      mem_re       => mem_re,
      mem_we       => mem_we,
      bit_select   => bit_select,
      mem_data_out => mem_data_out
    );

  u_checker_dpram : entity work.dpram
    generic map (
      DATA_WIDTH => 8,
      ADDR_WIDTH => 7
    )
    port map (
      clk      => chk_clk,
      we       => chk_we,
      re       => chk_re,
      d        => chk_d,
      d_status => chk_d_status,
      addr     => chk_addr,
      q        => chk_q,
      q_status => chk_q_status
    );

  mem_checker_proc : process
    procedure pulse_checker_clock is
    begin
      chk_clk <= '0';
      wait for 5 ns;
      chk_clk <= '1';
      wait for 5 ns;
      chk_clk <= '0';
      wait for 1 ns;
    end procedure pulse_checker_clock;
  begin
    wait for 1 ns;

    -- Read enable must gate the memory data output.
    chk_addr <= std_logic_vector(to_unsigned(16, 7));
    chk_d <= x"5A";
    chk_d_status <= x"00";
    chk_we <= '1';
    chk_re <= '0';
    pulse_checker_clock;
    assert chk_q = x"00"
      report "DPRAM q must stay zero when re = '0'."
      severity failure;

    chk_we <= '0';
    chk_re <= '1';
    wait for 1 ns;
    assert chk_q = x"5A"
      report "DPRAM failed to return stored data when re = '1'."
      severity failure;

    -- Writing any non-STATUS address must mirror d_status into address 03h.
    chk_addr <= std_logic_vector(to_unsigned(20, 7));
    chk_d <= x"A5";
    chk_d_status <= x"03";
    chk_we <= '1';
    chk_re <= '0';
    pulse_checker_clock;

    chk_we <= '0';
    chk_re <= '1';
    chk_addr <= std_logic_vector(to_unsigned(3, 7));
    wait for 1 ns;
    assert chk_q = x"03"
      report "STATUS mirror at address 03h was not updated from d_status."
      severity failure;
    assert chk_q_status = "011"
      report "Dedicated STATUS output must follow d_status after non-03h writes."
      severity failure;

    -- At address 03h, the normal data input d must take precedence over d_status.
    chk_addr <= std_logic_vector(to_unsigned(3, 7));
    chk_d <= x"AA";
    chk_d_status <= x"05";
    chk_we <= '1';
    chk_re <= '0';
    pulse_checker_clock;

    chk_we <= '0';
    chk_re <= '1';
    wait for 1 ns;
    assert chk_q = x"AA"
      report "Memory data input d must have precedence when writing address 03h."
      severity failure;
    assert chk_q_status = "010"
      report "Dedicated STATUS output must reflect d(2 downto 0) at address 03h."
      severity failure;

    wait;
  end process mem_checker_proc;

  stim_proc : process
    variable in_line      : line;
    variable out_line     : line;
    variable line_content : string(1 to 120);
    variable line_length  : natural;
    variable op_name      : string(1 to 10);
    variable w_int        : integer;
    variable addr_int     : integer;
    variable re_int       : integer;
    variable we_int       : integer;
    variable bs_int       : integer;
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

      if (idx > line_length) or (line_content(1) = '#') then
        next;
      end if;

      w_int := 0;
      while (idx <= line_length) and (line_content(idx) >= '0') and (line_content(idx) <= '9') loop
        w_int := w_int * 10 + (character'pos(line_content(idx)) - character'pos('0'));
        idx := idx + 1;
      end loop;

      while (idx <= line_length) and (line_content(idx) = ' ') loop
        idx := idx + 1;
      end loop;

      addr_int := 0;
      while (idx <= line_length) and (line_content(idx) >= '0') and (line_content(idx) <= '9') loop
        addr_int := addr_int * 10 + (character'pos(line_content(idx)) - character'pos('0'));
        idx := idx + 1;
      end loop;

      while (idx <= line_length) and (line_content(idx) = ' ') loop
        idx := idx + 1;
      end loop;

      re_int := 0;
      while (idx <= line_length) and (line_content(idx) >= '0') and (line_content(idx) <= '9') loop
        re_int := re_int * 10 + (character'pos(line_content(idx)) - character'pos('0'));
        idx := idx + 1;
      end loop;

      while (idx <= line_length) and (line_content(idx) = ' ') loop
        idx := idx + 1;
      end loop;

      we_int := 0;
      while (idx <= line_length) and (line_content(idx) >= '0') and (line_content(idx) <= '9') loop
        we_int := we_int * 10 + (character'pos(line_content(idx)) - character'pos('0'));
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

      clk <= '0';
      op <= to_alu_op(op_name);
      w_in <= std_logic_vector(to_unsigned(w_int, 8));
      addr <= std_logic_vector(to_unsigned(addr_int, 7));
      if re_int = 0 then
        mem_re <= '0';
      else
        mem_re <= '1';
      end if;

      if we_int = 0 then
        mem_we <= '0';
      else
        mem_we <= '1';
      end if;
      bit_select <= std_logic_vector(to_unsigned(bs_int, 3));

      wait for 5 ns;
      clk <= '1';
      wait for 5 ns;

      out_line := null;
      write(out_line, string'("Operation: "));
      write(out_line, op_name);
      write(out_line, string'(" | w_in: "));
      write(out_line, w_int);
      write(out_line, string'(" | addr: "));
      write(out_line, addr_int);
      write(out_line, string'(" | mem_re: "));
      write(out_line, re_int);
      write(out_line, string'(" | mem_we: "));
      write(out_line, we_int);
      write(out_line, string'(" | mem_data_out: "));
      write(out_line, to_integer(unsigned(mem_data_out)));
      writeline(output_file, out_line);
    end loop;

    wait;
  end process stim_proc;

end architecture behavioral;
