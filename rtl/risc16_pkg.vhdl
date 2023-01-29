LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
--use IEEE.numeric_std.all;

library work;
-- Package Declaration Section
package risc16_pkg is

  -- risc16 register field
  type t_risc16_regs is record
    --r0 : std_logic_vector(15 downto 0); -- always contain 0
    r1 : std_logic_vector(15 downto 0);
    r2 : std_logic_vector(15 downto 0);
    r3 : std_logic_vector(15 downto 0);
    r4 : std_logic_vector(15 downto 0);
    r5 : std_logic_vector(15 downto 0);
    r6 : std_logic_vector(15 downto 0);
    r7 : std_logic_vector(15 downto 0);
  end record t_risc16_regs;

  CONSTANT C_RISC16_REGS_INIT : t_risc16_regs :=
            (--r0 => (others => '0'),
             r1 => (others => '0'),
             r2 => (others => '0'),
             r3 => (others => '0'),
             r4 => (others => '0'),
             r5 => (others => '0'),
             r6 => (others => '0'),
             r7 => (others => '0'));

  CONSTANT  C_ADD   : std_logic_vector(2 downto 0) := "000";
  CONSTANT  C_ADDI  : std_logic_vector(2 downto 0) := "001";
  CONSTANT  C_NAND  : std_logic_vector(2 downto 0) := "010";
  CONSTANT  C_LUI   : std_logic_vector(2 downto 0) := "011";
  CONSTANT  C_SW    : std_logic_vector(2 downto 0) := "100";
  CONSTANT  C_LW    : std_logic_vector(2 downto 0) := "101";
  CONSTANT  C_BEQ   : std_logic_vector(2 downto 0) := "110";
  CONSTANT  C_JALR  : std_logic_vector(2 downto 0) := "111";

  CONSTANT  C_R0    : std_logic_vector(2 downto 0) := "000";
  CONSTANT  C_R1    : std_logic_vector(2 downto 0) := "001";
  CONSTANT  C_R2    : std_logic_vector(2 downto 0) := "010";
  CONSTANT  C_R3    : std_logic_vector(2 downto 0) := "011";
  CONSTANT  C_R4    : std_logic_vector(2 downto 0) := "100";
  CONSTANT  C_R5    : std_logic_vector(2 downto 0) := "101";
  CONSTANT  C_R6    : std_logic_vector(2 downto 0) := "110";
  CONSTANT  C_R7    : std_logic_vector(2 downto 0) := "111";

  -- special instruction
  CONSTANT C_NOP : std_logic_vector(15 downto 0) := "0000000000000000"; -- NOP (add R0,RO,RO)
end package risc16_pkg;
