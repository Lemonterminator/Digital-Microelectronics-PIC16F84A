library ieee;
use ieee.std_logic_1164.all;

entity tb_hello is
end entity tb_hello;

architecture behavioural of tb_hello is
  -- Testbench stimulus and observation signals.
  signal a      : std_logic := '0';
  signal b      : std_logic := '0';
  signal x_xor  : std_logic;
  signal y      : std_logic;
begin
  -- XOR, stage 1
  u_xor: entity work.xor_gate(rtl)
    port map (
      a => a,
      b => b,
      y => x_xor
    );
  
  -- NOT, stage 2
  u_not: entity work.not_gate(rtl)
    port map (
      a => x_xor,
      y => y
    );

  -- Apply all 2-bit input combinations.
  stimulus: process
  begin
    a <= '0'; b <= '0'; wait for 10 ns;
    a <= '0'; b <= '1'; wait for 10 ns;
    a <= '1'; b <= '0'; wait for 10 ns;
    a <= '1'; b <= '1'; wait for 10 ns;
    wait;
  end process;
end architecture behavioural;
