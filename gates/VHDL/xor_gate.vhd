library ieee;
use ieee.std_logic_1164.all;

-- 2-input XOR gate.
entity xor_gate is
  port (
    a : in  std_logic;
    b : in  std_logic;
    y : out std_logic
  );
end entity xor_gate;

architecture rtl of xor_gate is
begin
  y <= a xor b;
end architecture rtl;
