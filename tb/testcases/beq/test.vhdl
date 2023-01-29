LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

ENTITY test IS
  port (
    clk    : in std_logic;
    rst_n  : out std_logic; -- asynchronous logic
    enable : out std_logic; -- enable of mcu
    stop_sim : out boolean;
    address_1 : out std_logic_vector(15 downto 0);
    dataout_2 : in std_logic_vector(15 downto 0)
  );
END ENTITY test;


architecture TB of test is

begin

sim: process
begin
  rst_n <= '0';
  enable <= '1';
  wait for 100 ns;
  rst_n <= '1';

  wait for 100 us;

  address_1 <= x"0000";
  wait for 10 ns;
  if dataout_2 /= x"0008" then
    report "RAM[0] bad value" severity error;
  else
    report "RAM[0] OK";
  end if;

  address_1 <= x"0001";
  wait for 10 ns;
  if dataout_2 /= x"0008" then
    report "RAM[1] bad value" severity error;
  else
    report "RAM[1] OK";
  end if;

  stop_sim <= true;
  wait;
end process;

end architecture TB;
