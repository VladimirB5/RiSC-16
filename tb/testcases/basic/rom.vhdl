LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.risc16_pkg.all;

-- basic program which use all instruction
-- test pass when
-- DATA RAM[0] = 0xFFFF and DATA RAM[1] = 0xFFDF

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
        (C_LUI, C_R1, "0001000000"), -- 0 load R1 = 64 << 6 -> R1 = 4096(0x1000)
        (C_ADDI, C_R2, C_R1, "0100000"), -- 1 R2 = R1 + 32 -> R2 = 4128 (0x1020)
        (C_ADD, C_R3, C_R1, "0000", C_R2), -- 2 R3 = R1 + R2 -> R3 = 4096+4128=8224 (0x2020)
        (C_NAND, C_R4, C_R3, "0000", C_R2), -- 3 R4 = R3 NAND R2 -> R4 = 0x2020 NAND 0x1020 = 0xFFDF
        (C_BEQ, C_R1, C_R2, "0000000"), -- 4 go to PC = 5
        (C_SW, C_R4, C_R0, "0000001"), -- 5 mem[1] = 0xFFDF
        (C_LW, C_R5, C_R0, "0000001"), -- 6 R5 = 0xFFDF
        (C_ADDI, C_R6, C_R5, "0100000"), -- 7 R6 = R5 + 0x20 -> R6 = 0xFFFF
        (C_SW, C_R6, C_R0, "0000000"), -- 8 mem[0] = 0xFFFF
        (C_ADDI, C_R1, C_R0, "0001010"), -- 9 load 8 R1 = 10
        C_NOP, -- 10
        (C_JALR, C_R2, C_R1, "0000000"), -- 11 jum to address 10
        C_NOP,
        C_NOP,
        C_NOP,
        C_NOP
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
