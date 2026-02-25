library ieee;
use ieee.std_logic_1164.all;

-- 3-input MUX
entity mux_8_bit is
    port (
        A   :   in  std_logic_vector(7 downto 0);
        B   :   in  std_logic_vector(7 downto 0);
        s   :   in  std_logic;
        Q   :   out std_logic_vector(7 downto 0)
    );
end entity mux_8_bit;

architecture rtl of mux_8_bit is
    process(A, B, s)
    begin
        if s = '1' then
            Q <= B;
        else
            Q <= A;
        end if;
    end process;
end architecture rtl;