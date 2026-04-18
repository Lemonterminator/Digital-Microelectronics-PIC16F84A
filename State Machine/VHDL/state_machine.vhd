library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.alu_pkg.all;

entity state_machine is
  port (
    clk        : in  std_logic;
    opcode     : in  std_logic_vector(13 downto 0);
    op         : out alu_op;
    we_mem     : out std_logic;
    re_mem     : out std_logic;
    we_w       : out std_logic;
    instr_ret  : out std_logic;
    bit_select : out std_logic_vector(2 downto 0);
    data       : out std_logic_vector(7 downto 0);
    pc         : out std_logic_vector(12 downto 0);
    addr       : out std_logic_vector(6 downto 0)
  );
end entity state_machine;

architecture rtl of state_machine is

  type state_t is (iFetch, Mread, Execute, Mwrite);

  signal state             : state_t := iFetch;
  signal op_reg            : alu_op := NOP;
  signal bit_select_reg    : std_logic_vector(2 downto 0) := (others => '0');
  signal data_reg          : std_logic_vector(7 downto 0) := (others => '0');
  signal addr_reg          : std_logic_vector(6 downto 0) := (others => '0');
  signal pc_reg            : unsigned(12 downto 0) := (others => '0');
  signal writes_memory_reg : std_logic := '0';
  signal writes_w_reg      : std_logic := '0';
  signal we_mem_reg        : std_logic := '0';
  signal re_mem_reg        : std_logic := '0';
  signal we_w_reg          : std_logic := '0';
  signal instr_ret_reg     : std_logic := '0';

  function is_nop(
    instruction : std_logic_vector(13 downto 0)
  ) return boolean is
  begin
    return instruction(13 downto 7) = "0000000" and
           instruction(4 downto 0) = "00000";
  end function is_nop;

  procedure select_byte_destination(
    constant destination_is_file : in  std_logic;
    variable writes_memory       : out std_logic;
    variable writes_w            : out std_logic
  ) is
  begin
    if destination_is_file = '1' then
      writes_memory := '1';
      writes_w      := '0';
    else
      writes_memory := '0';
      writes_w      := '1';
    end if;
  end procedure select_byte_destination;

  procedure decode_instruction(
    constant instruction   : in  std_logic_vector(13 downto 0);
    variable decoded_op    : out alu_op;
    variable decoded_addr  : out std_logic_vector(6 downto 0);
    variable decoded_bit   : out std_logic_vector(2 downto 0);
    variable decoded_data  : out std_logic_vector(7 downto 0);
    variable needs_read    : out std_logic;
    variable writes_memory : out std_logic;
    variable writes_w      : out std_logic;
    variable valid         : out boolean
  ) is
  begin
    decoded_op    := NOP;
    decoded_addr  := instruction(6 downto 0);
    decoded_bit   := (others => '0');
    decoded_data  := instruction(7 downto 0);
    needs_read    := '0';
    writes_memory := '0';
    writes_w      := '0';
    valid         := true;

    if instruction(13 downto 10) = "0100" then
      decoded_op    := BCF;
      decoded_bit   := instruction(9 downto 7);
      needs_read    := '1';
      writes_memory := '1';
    elsif instruction(13 downto 10) = "0101" then
      decoded_op    := BSF;
      decoded_bit   := instruction(9 downto 7);
      needs_read    := '1';
      writes_memory := '1';
    elsif instruction(13 downto 10) = "0110" then
      decoded_op  := BTFSC;
      decoded_bit := instruction(9 downto 7);
      needs_read  := '1';
    elsif instruction(13 downto 10) = "0111" then
      decoded_op  := BTFSS;
      decoded_bit := instruction(9 downto 7);
      needs_read  := '1';
    elsif instruction(13 downto 11) = "100" then
      decoded_op := CALL;
    elsif instruction(13 downto 11) = "101" then
      decoded_op := GOTO;
    elsif instruction(13 downto 10) = "1100" then
      decoded_op := MOVLW;
      writes_w   := '1';
    elsif instruction(13 downto 10) = "1101" then
      decoded_op := RETLW;
      writes_w   := '1';
    elsif instruction(13 downto 9) = "11111" then
      decoded_op := ADDLW;
      writes_w   := '1';
    elsif instruction(13 downto 9) = "11110" then
      decoded_op := SUBLW;
      writes_w   := '1';
    elsif instruction(13 downto 8) = "111001" then
      decoded_op := ANDLW;
      writes_w   := '1';
    elsif instruction(13 downto 8) = "111000" then
      decoded_op := IORLW;
      writes_w   := '1';
    elsif instruction(13 downto 8) = "111010" then
      decoded_op := XORLW;
      writes_w   := '1';
    else
      case instruction(13 downto 8) is
        when "000111" =>
          decoded_op := ADDWF;
          needs_read := '1';
          select_byte_destination(instruction(7), writes_memory, writes_w);

        when "000101" =>
          decoded_op := ANDWF;
          needs_read := '1';
          select_byte_destination(instruction(7), writes_memory, writes_w);

        when "000001" =>
          if instruction(7) = '1' then
            decoded_op    := CLRF;
            writes_memory := '1';
          else
            decoded_op := CLRW;
            writes_w   := '1';
          end if;

        when "001001" =>
          decoded_op := COMF;
          needs_read := '1';
          select_byte_destination(instruction(7), writes_memory, writes_w);

        when "000011" =>
          decoded_op := DECF;
          needs_read := '1';
          select_byte_destination(instruction(7), writes_memory, writes_w);

        when "001011" =>
          decoded_op := DECFSZ;
          needs_read := '1';
          select_byte_destination(instruction(7), writes_memory, writes_w);

        when "001010" =>
          decoded_op := INCF;
          needs_read := '1';
          select_byte_destination(instruction(7), writes_memory, writes_w);

        when "001111" =>
          decoded_op := INCFSZ;
          needs_read := '1';
          select_byte_destination(instruction(7), writes_memory, writes_w);

        when "000100" =>
          decoded_op := IORWF;
          needs_read := '1';
          select_byte_destination(instruction(7), writes_memory, writes_w);

        when "001000" =>
          decoded_op := MOVF;
          needs_read := '1';
          select_byte_destination(instruction(7), writes_memory, writes_w);

        when "000000" =>
          if instruction(7) = '1' then
            decoded_op    := MOVWF;
            writes_memory := '1';
          elsif instruction = std_logic_vector(to_unsigned(16#0008#, 14)) then
            decoded_op := RETUR;
          elsif is_nop(instruction) then
            decoded_op := NOP;
          else
            valid := false;
          end if;

        when "001101" =>
          decoded_op := RLF;
          needs_read := '1';
          select_byte_destination(instruction(7), writes_memory, writes_w);

        when "001100" =>
          decoded_op := RRF;
          needs_read := '1';
          select_byte_destination(instruction(7), writes_memory, writes_w);

        when "000010" =>
          decoded_op := SUBWF;
          needs_read := '1';
          select_byte_destination(instruction(7), writes_memory, writes_w);

        when "001110" =>
          decoded_op := SWAPF;
          needs_read := '1';
          select_byte_destination(instruction(7), writes_memory, writes_w);

        when "000110" =>
          decoded_op := XORWF;
          needs_read := '1';
          select_byte_destination(instruction(7), writes_memory, writes_w);

        when others =>
          valid := false;
      end case;
    end if;
  end procedure decode_instruction;

begin

  op         <= op_reg;
  we_mem     <= we_mem_reg;
  re_mem     <= re_mem_reg;
  we_w       <= we_w_reg;
  instr_ret  <= instr_ret_reg;
  bit_select <= bit_select_reg;
  data       <= data_reg;
  pc         <= std_logic_vector(pc_reg);
  addr       <= addr_reg;

  state_seq : process(clk)
    variable decoded_op            : alu_op;
    variable decoded_addr          : std_logic_vector(6 downto 0);
    variable decoded_bit           : std_logic_vector(2 downto 0);
    variable decoded_data          : std_logic_vector(7 downto 0);
    variable decoded_needs_read    : std_logic;
    variable decoded_writes_memory : std_logic;
    variable decoded_writes_w      : std_logic;
    variable decoded_valid         : boolean;
  begin
    if rising_edge(clk) then
      we_mem_reg    <= '0';
      re_mem_reg    <= '0';
      we_w_reg      <= '0';
      instr_ret_reg <= '0';

      case state is
        when iFetch =>
          decode_instruction(
            opcode,
            decoded_op,
            decoded_addr,
            decoded_bit,
            decoded_data,
            decoded_needs_read,
            decoded_writes_memory,
            decoded_writes_w,
            decoded_valid
          );

          assert decoded_valid
            report "Unsupported PIC16F84A opcode " &
                   integer'image(to_integer(unsigned(opcode)))
            severity failure;

          op_reg            <= decoded_op;
          addr_reg          <= decoded_addr;
          bit_select_reg    <= decoded_bit;
          data_reg          <= decoded_data;
          writes_memory_reg <= decoded_writes_memory;
          writes_w_reg      <= decoded_writes_w;

          if decoded_needs_read = '1' then
            state <= Mread;
          else
            state <= Execute;
          end if;

        when Mread =>
          re_mem_reg <= '1';
          state      <= Execute;

        when Execute =>
          state <= Mwrite;

        when Mwrite =>
          we_mem_reg    <= writes_memory_reg;
          we_w_reg      <= writes_w_reg;
          instr_ret_reg <= '1';
          pc_reg        <= pc_reg + 1;
          state         <= iFetch;
      end case;
    end if;
  end process state_seq;

end architecture rtl;
