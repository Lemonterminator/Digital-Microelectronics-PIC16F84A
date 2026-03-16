library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity n_bit_adder is
    generic (
        n : positive := 8
    );
    port (
        A   : in  std_logic_vector(n - 1 downto 0);
        B   : in  std_logic_vector(n - 1 downto 0);
        S   : out std_logic_vector(n - 1 downto 0);
        CO  : out std_logic
    );
end entity n_bit_adder;

architecture rtl of n_bit_adder is
begin
    process (A, B)
        variable sum_ext : unsigned(n downto 0);
    begin
        sum_ext := ('0' & unsigned(A)) + ('0' & unsigned(B));
        S  <= std_logic_vector(sum_ext(n - 1 downto 0));
        CO <= sum_ext(n);
    end process;
end architecture rtl;
