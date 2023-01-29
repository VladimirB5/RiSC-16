LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

ENTITY tb_top IS
END ENTITY tb_top;


architecture TB of tb_top is

component risc16_top
  port (
    clk    : in std_logic;
    rst_n  : in std_logic; -- asynchronous logic
    enable : in std_logic; -- enable of mcu
    --halt   : in std_logic;
    -- instruction interface
    inst_addr       : out std_logic_vector(15 downto 0); -- PC addr
    inst_data       : in  std_logic_vector(15 downto 0);
    inst_re         : out std_logic;
    inst_valid      : in  std_logic;
    -- data interface
    dat_addr       : out std_logic_vector(15 downto 0);
    dat_in         : out std_logic_vector(15 downto 0);
    dat_out        : in  std_logic_vector(15 downto 0);
    dat_we         : out std_logic
    --dat_ready      : in  std_logic;

    --interrupt : in std_logic
  );
END component;

component rom is
generic(
    address_length: natural := 3;
    data_length: natural := 16);
port(
    clk : in std_logic;
    re: in std_logic;
    valid : out std_logic;
    address: in std_logic_vector((data_length - 1) downto 0);
    data_output: out std_logic_vector ((data_length - 1) downto 0)
);
end component;

component data_ram is
generic(
    address_length: natural := 3;
    data_length: natural := 16);
  port (
    clk     : in  std_logic;
    we      : in  std_logic;
    address : in  std_logic_vector(15 downto 0);
    datain  : in  std_logic_vector(data_length -1 downto 0);
    dataout : out std_logic_vector(data_length -1 downto 0);
    -- second interface for test
    address_1 : in std_logic_vector(15 downto 0);
    dataout_2 : out std_logic_vector(15 downto 0)
  );
end component;

component test IS
  port (
    clk    : in std_logic;
    rst_n  : out std_logic; -- asynchronous logic
    enable : out std_logic; -- enable of mcu
    stop_sim : out boolean;
    address_1 : out std_logic_vector(15 downto 0);
    dataout_2 : in std_logic_vector(15 downto 0)
  );
end component;

-- TB constants
signal stop_sim: boolean := false;
constant clk_period  : time := 10 ns;

-- signals
signal clk : std_logic;
signal rst_n : std_logic;
signal enable : std_logic;
signal inst_addr : std_logic_vector(15 downto 0);
signal inst_data : std_logic_vector(15 downto 0);
signal inst_re   : std_logic;
signal inst_valid: std_logic;
signal dat_addr  : std_logic_vector(15 downto 0);
signal dat_in    : std_logic_vector(15 downto 0);
signal dat_out   : std_logic_vector(15 downto 0);
signal dat_we    : std_logic;
signal address_1 : std_logic_vector(15 downto 0);
signal dataout_2 : std_logic_vector(15 downto 0);

begin

clock_gen: process
     begin
        clk <= '0';
        wait for clk_period/2;  --
        clk <= '1';
        wait for clk_period/2;  --
        if stop_sim = true then
          wait;
        end if;
end process;

i_risc16_top : risc16_top
port map (
    clk    => clk,
    rst_n  => rst_n,
    enable => enable,
    --halt   : in std_logic;
    -- instruction interface
    inst_addr      => inst_addr,
    inst_data      => inst_data,
    inst_re        => inst_re,
    inst_valid     => inst_valid,
    -- data interface
    dat_addr       => dat_addr,
    dat_in         => dat_in,
    dat_out        => dat_out,
    dat_we         => dat_we
    --dat_ready      : in  std_logic;

    --interrupt : in std_logic
  );

 i_rom : rom
generic map (
    address_length => 4,
    data_length    => 16)
port map(
    clk => clk,
    re  => inst_re,
    valid => inst_valid,
    address => inst_addr,
    data_output => inst_data
);

 i_data_ram : data_ram
generic map(
    address_length =>3,
    data_length => 16)
  port map (
    clk     => clk,
    we      => dat_we,
    address => dat_addr,
    datain  => dat_in,
    dataout => dat_out,
    -- second interface for test
    address_1 => address_1,
    dataout_2 => dataout_2
  );

  i_test : test
    port map(
    clk    => clk,
    rst_n  => rst_n,
    enable => enable,
    stop_sim => stop_sim,
    address_1 => address_1,
    dataout_2 => dataout_2
  );

end architecture TB;
