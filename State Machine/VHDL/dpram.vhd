library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dpram is
  generic (
    DATA_WIDTH : positive := 8;
    ADDR_WIDTH : positive := 7
  );
  port (
    clk      : in  std_logic;
    we       : in  std_logic;
    re       : in  std_logic;
    d        : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    d_status : in  std_logic_vector(7 downto 0);
    addr     : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    q        : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    q_status : out std_logic_vector(2 downto 0)
  );
end entity dpram;

architecture rtl of dpram is

  constant STATUS_ADDR : natural := 16#03#;

  type ram_t is array (0 to (2 ** ADDR_WIDTH) - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);

  signal ram        : ram_t := (others => (others => '0'));
  signal status_reg : std_logic_vector(2 downto 0) := (others => '0');

  function pack_status(
    status_value : std_logic_vector(2 downto 0)
  ) return std_logic_vector is
    variable packed : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  begin
    packed(2 downto 0) := status_value;
    return packed;
  end function pack_status;

begin

  read_comb : process(all)
    variable index : natural;
  begin
    q_status <= status_reg;
    q <= (others => '0');

    if re = '1' then
      index := to_integer(unsigned(addr));
      q <= ram(index);
    end if;
  end process read_comb;

  write_seq : process(clk)
    variable index : natural;
  begin
    if rising_edge(clk) then
      if we = '1' then
        index := to_integer(unsigned(addr));

        ram(index) <= d;

        if index = STATUS_ADDR then
          assert d(2 downto 0) = d_status(2 downto 0)
            report "Direct STATUS write overrides the normal ALU status path."
            severity note;
          status_reg <= d(2 downto 0);
        else
          status_reg <= d_status(2 downto 0);
          ram(STATUS_ADDR) <= pack_status(d_status(2 downto 0));
        end if;
      end if;
    end if;
  end process write_seq;

end architecture rtl;
