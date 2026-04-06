library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.alu_pkg.all;

entity toplevel_alu_mem is
  port (
    clk          : in  std_logic;
    addr         : in  std_logic_vector(6 downto 0);
    op           : in  alu_op;
    w_in         : in  std_logic_vector(7 downto 0);
    mem_re       : in  std_logic;
    mem_we       : in  std_logic;
    bit_select   : in  std_logic_vector(2 downto 0);
    mem_data_out : out std_logic_vector(7 downto 0)
  );
end entity toplevel_alu_mem;

architecture rtl of toplevel_alu_mem is

  signal mem_q        : std_logic_vector(7 downto 0);
  signal mem_q_status : std_logic_vector(2 downto 0);
  signal alu_result   : std_logic_vector(7 downto 0);
  signal alu_status   : std_logic_vector(2 downto 0);
  signal alu_skip     : std_logic;
  signal d_status     : std_logic_vector(7 downto 0);

begin

  d_status <= (7 downto 3 => '0') & alu_status;

  u_alu : entity work.alu
    port map (
      a          => w_in,
      b          => mem_q,
      op         => op,
      bit_select => bit_select,
      status_in  => mem_q_status,
      status     => alu_status,
      result     => alu_result,
      skip_next  => alu_skip
    );

  u_dpram : entity work.dpram
    generic map (
      DATA_WIDTH => 8,
      ADDR_WIDTH => 7
    )
    port map (
      clk      => clk,
      we       => mem_we,
      re       => mem_re,
      d        => alu_result,
      d_status => d_status,
      addr     => addr,
      q        => mem_q,
      q_status => mem_q_status
    );

  mem_data_out <= mem_q;

end architecture rtl;
