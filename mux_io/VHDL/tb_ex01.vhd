library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_ex01 is
end entity tb_ex01;

architecture behavioural of tb_ex01 is
    -- Testbench stimulus and observation signals.
    signal A    : std_logic_vector(7 downto 0)  := (others=>'0');
    signal B    : std_logic_vector(7 downto 0)  := (others=>'0');
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
        file input_file     :   TEXT open READ_MODE is "input";
        file output_file    :   TEXT open WRITE_MODE is "output";

        -- line variable and data variable
        variable current_line   :   LINE;
        variable output_line    :   LINE;
        variable vector_data    :   std_logic_vector(16 downto  0);
        variable good           :   boolean;
        variable ln             :   integer := 0;

    begin
        report "Starting stimulus process";
        while not endfile(input_file) loop
            readline(input_file, current_line);
            ln := ln + 1;

            read (current_line, vector_data, good); 
            assert good report "Bad input format at line " & integer'image(ln) severity error;
            if not good then
                next;
            end if;

            A   <=  vector_data(16 downto 9);
            B   <=  vector_data(8 downto 1);
            s   <=  vector_data(0);
            wait for 10 ns;
            write(output_line, Q);
            writeline(output_file, output_line);
        end loop;
        report "End of stimulus";
        file_close(input_file);
        file_close(output_file);
        wait;
    end process;


end architecture behavioural;
