library ieee;
use ieee.std_logic_1164.all;

entity tb_hello is
end entity;

architecture sim of tb_hello is
  signal a : std_logic := '0';
  signal b : std_logic := '0';
  signal y : std_logic;
begin
  dut: entity work.hello
    port map (
      a => a,
      b => b,
      y => y
    );

  stimulus: process
  begin
    a <= '0'; b <= '0'; wait for 10 ns;
    a <= '0'; b <= '1'; wait for 10 ns;
    a <= '1'; b <= '0'; wait for 10 ns;
    a <= '1'; b <= '1'; wait for 10 ns;
    wait;
  end process;
end architecture;
