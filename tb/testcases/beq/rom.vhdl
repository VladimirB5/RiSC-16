LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.risc16_pkg.all;

-- loop program which is focused on beq instruction
-- test pass when
-- DATA RAM[0] = 0x0008 and DATA RAM[1] = 0x0008

entity rom is
generic(
    address_length: natural := 4;
    data_length: natural := 16);
port(
    clk : in std_logic;
    re: in std_logic;
    valid : out std_logic;
    address: in std_logic_vector((data_length - 1) downto 0);
    data_output: out std_logic_vector ((data_length - 1) downto 0)
);
end entity rom;

architecture RTL of rom is
    type rom_type is array (0 to (2**(address_length) -1)) of std_logic_vector((data_length - 1) downto 0);

    -- set the data on each adress to some value)
    constant mem: rom_type:=
    (
        (C_ADDI, C_R7, C_R0, "0001000"), -- 0 R7 = R0 + 8 -> R7 = 8
        (C_ADDI, C_R5, C_R0, "0000010"), -- 1 R5 = R0 + 2 -> R5 = 2
        (C_BEQ, C_R7, C_R2, "0000010"), -- 2 if R7 == R2 -> go to PC + 1 + 2 -> address 5
        (C_ADDI, C_R2, C_R2, "0000001"), -- 3 R2 = R2 + 1
        (C_JALR, C_R3, C_R5, "0000000"), -- 4 R3 = PC + 1 -> R3 = 5, PC = R5 -> PC = 2
        (C_SW, C_R2, C_R0, "0000000"), -- 5 mem[0] = R2 -> mem[0] = 0x0008
        (C_SW, C_R7, C_R0, "0000001"), -- 6 mem[1] = R7 -> mem[1] = 0x0008
        C_NOP, -- 7
        C_NOP, -- 8
        C_NOP, -- 9
        C_NOP, -- 10
        C_NOP, -- 11
        C_NOP, -- 12
        C_NOP, -- 13
        (C_ADDI, C_R5, C_R0, "0000111"), -- 14 R5 = R0 + 7 -> R5 = 7
        (C_JALR, C_R5, C_R5, "0000001")  -- 15 R5 = PC + 1, PC = R5 -> PC = 7
    );

begin


data_output <= mem(to_integer(unsigned(address(3 downto 0)))) when re = '1' else
               (others => 'X');

process(clk) is
begin
    if(rising_edge(clk)) then
      if re = '1' then
        valid <= '1';
      else
        valid <= '0';
      end if;
    end if;
end process;

end RTL;
