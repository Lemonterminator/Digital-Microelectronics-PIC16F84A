library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

library work;
use work.alu_pkg.all;

entity tb_ex06 is
end entity tb_ex06;

architecture behavioral of tb_ex06 is

  subtype opcode_t is std_logic_vector(13 downto 0);
  subtype pc_t is std_logic_vector(12 downto 0);
  subtype data_t is std_logic_vector(7 downto 0);
  subtype addr_t is std_logic_vector(6 downto 0);
  subtype bit_t is std_logic_vector(2 downto 0);

  signal clk        : std_logic := '0';
  signal opcode     : opcode_t := (others => '0');
  signal op         : alu_op := NOP;
  signal we_mem     : std_logic := '0';
  signal re_mem     : std_logic := '0';
  signal we_w       : std_logic := '0';
  signal instr_ret  : std_logic := '0';
  signal bit_select : bit_t := (others => '0');
  signal data       : data_t := (others => '0');
  signal pc         : pc_t := (others => '0');
  signal addr       : addr_t := (others => '0');

  signal mem_clk      : std_logic := '0';
  signal mem_we       : std_logic := '0';
  signal mem_re       : std_logic := '0';
  signal mem_d        : data_t := (others => '0');
  signal mem_d_status : data_t := (others => '0');
  signal mem_addr     : addr_t := (others => '0');
  signal mem_q        : data_t := (others => '0');
  signal mem_q_status : bit_t := (others => '0');

  function u14(value : natural) return opcode_t is
  begin
    return std_logic_vector(to_unsigned(value, 14));
  end function u14;

  function u13(value : natural) return pc_t is
  begin
    return std_logic_vector(to_unsigned(value mod 8192, 13));
  end function u13;

  function u8(value : natural) return data_t is
  begin
    return std_logic_vector(to_unsigned(value mod 256, 8));
  end function u8;

  function u7(value : natural) return addr_t is
  begin
    return std_logic_vector(to_unsigned(value mod 128, 7));
  end function u7;

  function u3(value : natural) return bit_t is
  begin
    return std_logic_vector(to_unsigned(value mod 8, 3));
  end function u3;

  function byte_opcode(
    prefix : std_logic_vector(5 downto 0);
    d      : std_logic;
    f      : natural
  ) return opcode_t is
  begin
    return prefix & d & u7(f);
  end function byte_opcode;

  function bit_opcode(
    prefix : std_logic_vector(3 downto 0);
    b      : natural;
    f      : natural
  ) return opcode_t is
  begin
    return prefix & u3(b) & u7(f);
  end function bit_opcode;

  function literal_opcode(
    prefix : std_logic_vector(5 downto 0);
    k      : natural
  ) return opcode_t is
  begin
    return prefix & u8(k);
  end function literal_opcode;

  function control_opcode(
    prefix : std_logic_vector(2 downto 0);
    k      : natural
  ) return opcode_t is
  begin
    return prefix & std_logic_vector(to_unsigned(k mod 2048, 11));
  end function control_opcode;

begin

  uut : entity work.state_machine
    port map (
      clk        => clk,
      opcode     => opcode,
      op         => op,
      we_mem     => we_mem,
      re_mem     => re_mem,
      we_w       => we_w,
      instr_ret  => instr_ret,
      bit_select => bit_select,
      data       => data,
      pc         => pc,
      addr       => addr
    );

  u_dpram : entity work.dpram
    generic map (
      DATA_WIDTH => 8,
      ADDR_WIDTH => 7
    )
    port map (
      clk      => mem_clk,
      we       => mem_we,
      re       => mem_re,
      d        => mem_d,
      d_status => mem_d_status,
      addr     => mem_addr,
      q        => mem_q,
      q_status => mem_q_status
    );

  stim_proc : process
    variable expected_pc : natural := 0;

    procedure pulse_controller is
    begin
      clk <= '0';
      wait for 5 ns;
      clk <= '1';
      wait for 1 ns;
      wait for 4 ns;
      clk <= '0';
      wait for 1 ns;
    end procedure pulse_controller;

    procedure pulse_memory is
    begin
      mem_clk <= '0';
      wait for 5 ns;
      mem_clk <= '1';
      wait for 1 ns;
      wait for 4 ns;
      mem_clk <= '0';
      wait for 1 ns;
    end procedure pulse_memory;

    procedure assert_no_controls(label_name : in string) is
    begin
      assert re_mem = '0'
        report label_name & ": re_mem should be low"
        severity failure;
      assert we_mem = '0'
        report label_name & ": we_mem should be low"
        severity failure;
      assert we_w = '0'
        report label_name & ": we_w should be low"
        severity failure;
      assert instr_ret = '0'
        report label_name & ": instr_ret should be low"
        severity failure;
    end procedure assert_no_controls;

    procedure assert_pc(label_name : in string; expected_value : in natural) is
    begin
      assert pc = u13(expected_value)
        report label_name & ": pc mismatch"
        severity failure;
    end procedure assert_pc;

    procedure run_no_read(
      inst                : in opcode_t;
      label_name          : in string;
      expected_op         : in alu_op;
      expected_data       : in data_t;
      expected_addr       : in addr_t;
      expected_bit_select : in bit_t;
      expected_we_w       : in std_logic;
      expected_we_mem     : in std_logic;
      variable pc_count   : inout natural
    ) is
    begin
      opcode <= inst;
      wait for 1 ns;

      pulse_controller;
      assert op = expected_op
        report label_name & ": decoded ALU operation mismatch"
        severity failure;
      assert data = expected_data
        report label_name & ": decoded literal/data mismatch"
        severity failure;
      assert addr = expected_addr
        report label_name & ": decoded address mismatch"
        severity failure;
      assert bit_select = expected_bit_select
        report label_name & ": decoded bit select mismatch"
        severity failure;
      assert_no_controls(label_name & " decode");
      assert_pc(label_name & " decode", pc_count);

      pulse_controller;
      assert_no_controls(label_name & " execute");
      assert_pc(label_name & " execute", pc_count);

      pulse_controller;
      pc_count := pc_count + 1;
      assert re_mem = '0'
        report label_name & ": re_mem should be low at write-back"
        severity failure;
      assert we_w = expected_we_w
        report label_name & ": we_w write-back mismatch"
        severity failure;
      assert we_mem = expected_we_mem
        report label_name & ": we_mem write-back mismatch"
        severity failure;
      assert instr_ret = '1'
        report label_name & ": instr_ret should pulse at write-back"
        severity failure;
      assert_pc(label_name & " write-back", pc_count);
    end procedure run_no_read;

    procedure run_with_read(
      inst                : in opcode_t;
      label_name          : in string;
      expected_op         : in alu_op;
      expected_addr       : in addr_t;
      expected_bit_select : in bit_t;
      expected_we_w       : in std_logic;
      expected_we_mem     : in std_logic;
      variable pc_count   : inout natural
    ) is
    begin
      opcode <= inst;
      wait for 1 ns;

      pulse_controller;
      assert op = expected_op
        report label_name & ": decoded ALU operation mismatch"
        severity failure;
      assert addr = expected_addr
        report label_name & ": decoded address mismatch"
        severity failure;
      assert bit_select = expected_bit_select
        report label_name & ": decoded bit select mismatch"
        severity failure;
      assert_no_controls(label_name & " decode");
      assert_pc(label_name & " decode", pc_count);

      pulse_controller;
      assert re_mem = '1'
        report label_name & ": re_mem should pulse during Mread"
        severity failure;
      assert we_mem = '0'
        report label_name & ": we_mem should be low during Mread"
        severity failure;
      assert we_w = '0'
        report label_name & ": we_w should be low during Mread"
        severity failure;
      assert instr_ret = '0'
        report label_name & ": instr_ret should be low during Mread"
        severity failure;
      assert_pc(label_name & " mread", pc_count);

      pulse_controller;
      assert_no_controls(label_name & " execute");
      assert_pc(label_name & " execute", pc_count);

      pulse_controller;
      pc_count := pc_count + 1;
      assert re_mem = '0'
        report label_name & ": re_mem should be low at write-back"
        severity failure;
      assert we_w = expected_we_w
        report label_name & ": we_w write-back mismatch"
        severity failure;
      assert we_mem = expected_we_mem
        report label_name & ": we_mem write-back mismatch"
        severity failure;
      assert instr_ret = '1'
        report label_name & ": instr_ret should pulse at write-back"
        severity failure;
      assert_pc(label_name & " write-back", pc_count);
    end procedure run_with_read;

    procedure run_dpram_checks is
    begin
      mem_addr     <= u7(16#10#);
      mem_d        <= x"5A";
      mem_d_status <= x"00";
      mem_we       <= '1';
      mem_re       <= '0';
      pulse_memory;
      assert mem_q = x"00"
        report "DPRAM q must stay zero when re = '0'"
        severity failure;

      mem_we <= '0';
      mem_re <= '1';
      wait for 1 ns;
      assert mem_q = x"5A"
        report "DPRAM failed to return stored data when re = '1'"
        severity failure;

      mem_addr     <= u7(16#14#);
      mem_d        <= x"A5";
      mem_d_status <= x"03";
      mem_we       <= '1';
      mem_re       <= '0';
      pulse_memory;

      mem_we   <= '0';
      mem_re   <= '1';
      mem_addr <= u7(16#03#);
      wait for 1 ns;
      assert mem_q = x"03"
        report "STATUS mirror at address 03h was not updated from d_status"
        severity failure;
      assert mem_q_status = "011"
        report "Dedicated STATUS output must follow d_status after non-03h writes"
        severity failure;

      mem_addr     <= u7(16#03#);
      mem_d        <= x"AA";
      mem_d_status <= x"05";
      mem_we       <= '1';
      mem_re       <= '0';
      pulse_memory;

      mem_we <= '0';
      mem_re <= '1';
      wait for 1 ns;
      assert mem_q = x"AA"
        report "Memory data input d must have precedence when writing address 03h"
        severity failure;
      assert mem_q_status = "010"
        report "Dedicated STATUS output must reflect d(2 downto 0) at address 03h"
        severity failure;
    end procedure run_dpram_checks;

  begin
    wait for 1 ns;

    run_no_read(literal_opcode("110000", 16#5A#), "MOVLW", MOVLW, x"5A", u7(16#5A#), u3(0), '1', '0', expected_pc);
    run_no_read(literal_opcode("111110", 16#20#), "ADDLW", ADDLW, x"20", u7(16#20#), u3(0), '1', '0', expected_pc);
    run_no_read(literal_opcode("111001", 16#0F#), "ANDLW", ANDLW, x"0F", u7(16#0F#), u3(0), '1', '0', expected_pc);
    run_no_read(literal_opcode("111000", 16#33#), "IORLW", IORLW, x"33", u7(16#33#), u3(0), '1', '0', expected_pc);
    run_no_read(literal_opcode("111100", 16#55#), "SUBLW", SUBLW, x"55", u7(16#55#), u3(0), '1', '0', expected_pc);
    run_no_read(literal_opcode("111010", 16#A5#), "XORLW", XORLW, x"A5", u7(16#A5#), u3(0), '1', '0', expected_pc);
    run_no_read(literal_opcode("110100", 16#42#), "RETLW", RETLW, x"42", u7(16#42#), u3(0), '1', '0', expected_pc);

    run_with_read(byte_opcode("000111", '0', 16#10#), "ADDWF d=0", ADDWF, u7(16#10#), u3(0), '1', '0', expected_pc);
    run_with_read(byte_opcode("000111", '1', 16#11#), "ADDWF d=1", ADDWF, u7(16#11#), u3(0), '0', '1', expected_pc);

    run_no_read(byte_opcode("000000", '1', 16#16#), "MOVWF", MOVWF, u8(16#96#), u7(16#16#), u3(0), '0', '1', expected_pc);
    run_no_read(byte_opcode("000001", '1', 16#14#), "CLRF", CLRF, u8(16#94#), u7(16#14#), u3(0), '0', '1', expected_pc);
    run_no_read(byte_opcode("000001", '0', 16#00#), "CLRW", CLRW, x"00", u7(16#00#), u3(0), '1', '0', expected_pc);

    run_with_read(bit_opcode("0100", 3, 16#22#), "BCF", BCF, u7(16#22#), u3(3), '0', '1', expected_pc);
    run_with_read(bit_opcode("0101", 6, 16#23#), "BSF", BSF, u7(16#23#), u3(6), '0', '1', expected_pc);
    run_with_read(bit_opcode("0110", 2, 16#24#), "BTFSC", BTFSC, u7(16#24#), u3(2), '0', '0', expected_pc);
    run_with_read(bit_opcode("0111", 4, 16#25#), "BTFSS", BTFSS, u7(16#25#), u3(4), '0', '0', expected_pc);

    run_no_read(control_opcode("100", 16#123#), "CALL", CALL, x"23", u7(16#23#), u3(0), '0', '0', expected_pc);
    run_no_read(control_opcode("101", 16#234#), "GOTO", GOTO, x"34", u7(16#34#), u3(0), '0', '0', expected_pc);
    run_no_read(u14(16#0008#), "RETUR", RETUR, x"08", u7(16#08#), u3(0), '0', '0', expected_pc);
    run_no_read(u14(16#0000#), "NOP", NOP, x"00", u7(16#00#), u3(0), '0', '0', expected_pc);

    run_dpram_checks;

    report "tb_ex06 completed successfully" severity note;
    finish;
  end process stim_proc;

end architecture behavioral;
