library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.alu_pkg.all;

entity alu is
  port (
    a          : in  std_logic_vector(7 downto 0);
    b          : in  std_logic_vector(7 downto 0);
    op         : in  alu_op;
    bit_select : in  std_logic_vector(2 downto 0);
    status_in  : in  std_logic_vector(2 downto 0);
    status     : out std_logic_vector(2 downto 0);
    result     : out std_logic_vector(7 downto 0);
    skip_next  : out std_logic
  );
end entity alu;

architecture rtl of alu is

  function get_bit(
    value     : std_logic_vector(7 downto 0);
    bit_index : std_logic_vector(2 downto 0)
  ) return std_logic is
  begin
    return value(to_integer(unsigned(bit_index)));
  end function get_bit;

  function set_bit(
    value     : std_logic_vector(7 downto 0);
    bit_index : std_logic_vector(2 downto 0);
    bit_value : std_logic
  ) return std_logic_vector is
    variable temp : std_logic_vector(7 downto 0);
  begin
    temp := value;
    temp(to_integer(unsigned(bit_index))) := bit_value;
    return temp;
  end function set_bit;

  function zero_flag(
    value : std_logic_vector(7 downto 0)
  ) return std_logic is
  begin
    if value = x"00" then
      return '1';
    end if;

    return '0';
  end function zero_flag;

  function complement(
    value : std_logic_vector(7 downto 0)
  ) return std_logic_vector is
  begin
    return not value;
  end function complement;

  function decrement(
    value : std_logic_vector(7 downto 0)
  ) return std_logic_vector is
  begin
    return std_logic_vector(unsigned(value) - 1);
  end function decrement;

  function increment(
    value : std_logic_vector(7 downto 0)
  ) return std_logic_vector is
  begin
    return std_logic_vector(unsigned(value) + 1);
  end function increment;

  function swap_nibbles(
    value : std_logic_vector(7 downto 0)
  ) return std_logic_vector is
  begin
    return value(3 downto 0) & value(7 downto 4);
  end function swap_nibbles;

  function rotate_left_through_carry(
    value    : std_logic_vector(7 downto 0);
    carry_in : std_logic
  ) return std_logic_vector is
  begin
    return value(6 downto 0) & carry_in;
  end function rotate_left_through_carry;

  function rotate_right_through_carry(
    value    : std_logic_vector(7 downto 0);
    carry_in : std_logic
  ) return std_logic_vector is
  begin
    return carry_in & value(7 downto 1);
  end function rotate_right_through_carry;

  procedure update_zero_only(
    value       : in  std_logic_vector(7 downto 0);
    status_curr : in  std_logic_vector(2 downto 0);
    status_out  : out std_logic_vector(2 downto 0)
  ) is
  begin
    status_out := status_curr;
    status_out(STATUS_Z) := zero_flag(value);
  end procedure update_zero_only;

  procedure do_add(
    lhs         : in  std_logic_vector(7 downto 0);
    rhs         : in  std_logic_vector(7 downto 0);
    status_curr : in  std_logic_vector(2 downto 0);
    result_out  : out std_logic_vector(7 downto 0);
    status_out  : out std_logic_vector(2 downto 0)
  ) is
    variable sum9       : unsigned(8 downto 0);
    variable nibble_sum : unsigned(4 downto 0);
  begin
    sum9       := ('0' & unsigned(lhs)) + ('0' & unsigned(rhs));
    nibble_sum := ('0' & unsigned(lhs(3 downto 0))) + ('0' & unsigned(rhs(3 downto 0)));

    result_out := std_logic_vector(sum9(7 downto 0));
    status_out := status_curr;
    status_out(STATUS_C)  := sum9(8);
    status_out(STATUS_DC) := nibble_sum(4);
    status_out(STATUS_Z)  := zero_flag(result_out);
  end procedure do_add;

  procedure do_sub(
    lhs         : in  std_logic_vector(7 downto 0);
    rhs         : in  std_logic_vector(7 downto 0);
    status_curr : in  std_logic_vector(2 downto 0);
    result_out  : out std_logic_vector(7 downto 0);
    status_out  : out std_logic_vector(2 downto 0)
  ) is
  begin
    result_out := std_logic_vector(unsigned(lhs) - unsigned(rhs));
    status_out := status_curr;
    status_out(STATUS_Z) := zero_flag(result_out);

    if unsigned(lhs) >= unsigned(rhs) then
      status_out(STATUS_C) := '1';
    else
      status_out(STATUS_C) := '0';
    end if;

    if unsigned(lhs(3 downto 0)) >= unsigned(rhs(3 downto 0)) then
      status_out(STATUS_DC) := '1';
    else
      status_out(STATUS_DC) := '0';
    end if;
  end procedure do_sub;

begin

  alu_comb : process(all)
    variable w_value     : std_logic_vector(7 downto 0);
    variable f_value     : std_logic_vector(7 downto 0);
    variable next_result : std_logic_vector(7 downto 0);
    variable next_status : std_logic_vector(2 downto 0);
    variable next_skip   : std_logic;
  begin
    w_value := a;
    f_value := b;
    next_result := f_value;
    next_status := status_in;
    next_skip   := '0';

    case op is
      when ADDWF | ADDLW =>
        do_add(w_value, f_value, status_in, next_result, next_status);

      when ANDWF | ANDLW =>
        next_result := w_value and f_value;
        update_zero_only(next_result, status_in, next_status);

      when BCF =>
        next_result := set_bit(f_value, bit_select, '0');

      when BTFSC =>
        if get_bit(f_value, bit_select) = '0' then
          next_skip := '1';
        end if;

      when BSF =>
        next_result := set_bit(f_value, bit_select, '1');

      when BTFSS =>
        if get_bit(f_value, bit_select) = '1' then
          next_skip := '1';
        end if;

      when CLRF | CLRW =>
        next_result := (others => '0');
        next_status := status_in;
        next_status(STATUS_Z) := '1';

      when COMF =>
        next_result := complement(f_value);
        update_zero_only(next_result, status_in, next_status);

      when DECF =>
        next_result := decrement(f_value);
        update_zero_only(next_result, status_in, next_status);

      when DECFSZ =>
        next_result := decrement(f_value);
        if next_result = x"00" then
          next_skip := '1';
        end if;

      when INCF =>
        next_result := increment(f_value);
        update_zero_only(next_result, status_in, next_status);

      when INCFSZ =>
        next_result := increment(f_value);
        if next_result = x"00" then
          next_skip := '1';
        end if;

      when IORLW | IORWF =>
        next_result := w_value or f_value;
        update_zero_only(next_result, status_in, next_status);

      when MOVF =>
        next_result := f_value;
        update_zero_only(next_result, status_in, next_status);

      when MOVWF | MOVLW | RETLW =>
        next_result := w_value;

      when CALL | GOTO | RETUR | NOP =>
        null;

      when RLF =>
        next_result := rotate_left_through_carry(f_value, status_in(STATUS_C));
        next_status(STATUS_C) := f_value(7);

      when RRF =>
        next_result := rotate_right_through_carry(f_value, status_in(STATUS_C));
        next_status(STATUS_C) := f_value(0);

      when SUBLW =>
        do_sub(w_value, f_value, status_in, next_result, next_status);

      when SUBWF =>
        do_sub(f_value, w_value, status_in, next_result, next_status);

      when SWAPF =>
        next_result := swap_nibbles(f_value);

      when XORLW | XORWF =>
        next_result := w_value xor f_value;
        update_zero_only(next_result, status_in, next_status);
    end case;

    result    <= next_result;
    status    <= next_status;
    skip_next <= next_skip;
  end process alu_comb;

end architecture rtl;
