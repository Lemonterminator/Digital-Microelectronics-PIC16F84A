library ieee;
use ieee.std_logic_1164.all;

entity tb_ex01 is
end entity tb_ex01;

architecture behavioural of tb_ex01 is
    -- Testbench stimulus and observation signals.
    signal A    : std_logic_vector(7 downto 0)  := "00000000";
    signal B    : std_logic_vector(7 downto 0)  := "00000000";
    signal s    : std_logic                     := '0';
    signal Q    : std_logic_vector(7 downto 0);
begin
    -- MUX
    dut: entity work.mux_8_bit(rtl)
    port map(
        A => A,
        B => B,
        s => s,
        Q => Q
    );

    stimulus: process
    begin
        s <= '0'; A <= "00000000"; B <= "11111111"; wait for 10 ns;
        s <= '1';                                       wait for 10 ns;
        wait;
    end process;
end architecture behavioural;
