library ieee;
use ieee.std_logic_1164.all;

-- 2-input NAND gate.
entity nand_gate is
  port (
    a : in  std_logic;
    b : in  std_logic;
    y : out std_logic
  );
end entity nand_gate;

architecture rtl of nand_gate is
begin
  y <= a nand b;
end architecture rtl;
