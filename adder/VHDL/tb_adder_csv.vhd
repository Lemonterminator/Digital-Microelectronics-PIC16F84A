library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_adder_csv is
end entity tb_adder_csv;

architecture behavioural of tb_adder_csv is
    constant n : positive := 8;

    signal A      : std_logic_vector(n - 1 downto 0) := (others => '0');
    signal B      : std_logic_vector(n - 1 downto 0) := (others => '0');
    signal S_rca  : std_logic_vector(n - 1 downto 0);
    signal CO_rca : std_logic;
    signal S_add  : std_logic_vector(n - 1 downto 0);
    signal CO_add : std_logic;
begin
    dut1 : entity work.n_bit_rca(structural)
        generic map (
            n => n
        )
        port map (
            A  => A,
            B  => B,
            S  => S_rca,
            CO => CO_rca
        );

    dut2 : entity work.n_bit_adder(rtl)
        generic map (
            n => n
        )
        port map (
            A  => A,
            B  => B,
            S  => S_add,
            CO => CO_add
        );

    stimulus : process
        file input_csv  : text open read_mode is "../Verilog/adder_input.csv";
        file output_csv : text open write_mode is "adder_output.csv";
        variable in_line    : line;
        variable out_line   : line;
        variable comma      : character;
        variable a_int      : integer;
        variable b_int      : integer;
        variable co_rca_int : integer;
        variable co_add_int : integer;
    begin
        write(out_line, string'("A,B,S_rca,CO_rca,S_add,CO_add"));
        writeline(output_csv, out_line);

        while not endfile(input_csv) loop
            readline(input_csv, in_line);

            if in_line'length = 0 then
                next;
            end if;

            read(in_line, a_int);
            read(in_line, comma);
            read(in_line, b_int);

            A <= std_logic_vector(to_unsigned(a_int, n));
            B <= std_logic_vector(to_unsigned(b_int, n));

            wait for 10 ns;

            if CO_rca = '1' then
                co_rca_int := 1;
            else
                co_rca_int := 0;
            end if;

            if CO_add = '1' then
                co_add_int := 1;
            else
                co_add_int := 0;
            end if;

            write(out_line, a_int);
            write(out_line, string'(","));
            write(out_line, b_int);
            write(out_line, string'(","));
            write(out_line, to_integer(unsigned(S_rca)));
            write(out_line, string'(","));
            write(out_line, co_rca_int);
            write(out_line, string'(","));
            write(out_line, to_integer(unsigned(S_add)));
            write(out_line, string'(","));
            write(out_line, co_add_int);
            writeline(output_csv, out_line);

            assert S_rca = S_add and CO_rca = CO_add
                report "Mismatch between DUT1 and DUT2"
                severity error;
        end loop;

        wait;
    end process;
end architecture behavioural;
