library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity data_ram is
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
end entity data_ram;

architecture RTL of data_ram is

   --type ram_type is array (0 to (2**address'length)-1) of std_logic_vector(datain'range);
   type ram_type is array (0 to 7) of std_logic_vector(datain'range);
   signal ram : ram_type;
   signal read_address : std_logic_vector(address'range);

begin

  RamProc: process(clk) is

  begin
    if rising_edge(clk) then
      if we = '1' then
        ram(to_integer(unsigned(address(2 downto 0)))) <= datain;
      end if;
      read_address <= address;
    end if;
  end process RamProc;

  dataout <= ram(to_integer(unsigned(read_address(2 downto 0))));

  dataout_2 <= ram(to_integer(unsigned(address_1(2 downto 0))));

end architecture RTL;
