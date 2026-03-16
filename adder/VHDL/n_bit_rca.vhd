library ieee;
use ieee.std_logic_1164.all;

entity n_bit_rca is
    generic (
        n : positive := 8
    );
    port (
        A   : in  std_logic_vector(n - 1 downto 0);
        B   : in  std_logic_vector(n - 1 downto 0);
        S   : out std_logic_vector(n - 1 downto 0);
        CO  : out std_logic
    );
end entity n_bit_rca;

architecture structural of n_bit_rca is
    signal c : std_logic_vector(n downto 0);
begin
    c(0) <= '0';
    CO   <= c(n);

    gen_fa : for i in 0 to n - 1 generate
        first_stage : if i = 0 generate
        begin
            fa_0 : entity work.full_adder(rtl)
                port map (
                    a  => A(i),
                    b  => B(i),
                    ci => '0',
                    s  => S(i),
                    co => c(i + 1)
                );
        end generate first_stage;

        remaining_stages : if i > 0 generate
        begin
            fa_i : entity work.full_adder(rtl)
                port map (
                    a  => A(i),
                    b  => B(i),
                    ci => c(i),
                    s  => S(i),
                    co => c(i + 1)
                );
        end generate remaining_stages;
    end generate gen_fa;
end architecture structural;
