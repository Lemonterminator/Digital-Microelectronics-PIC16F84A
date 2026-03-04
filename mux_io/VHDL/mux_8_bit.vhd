library ieee;
use ieee.std_logic_1164.all;

entity mux_8_bit is
    port (
        s : in  std_logic;
        A : in  std_logic_vector(7 downto 0);
        B : in  std_logic_vector(7 downto 0);
        Q : out std_logic_vector(7 downto 0)
    );
end entity mux_8_bit;

architecture rtl of mux_8_bit is
begin
    Q   <=  A when s = '0' else 
        <=  B when s = '1' else
        (others =>'0');
end architecture rtl;
