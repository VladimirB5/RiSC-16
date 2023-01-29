LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.risc16_pkg.all;

ENTITY decode_st IS
  port (
    clk    : in std_logic;
    rst_n  : in std_logic; -- asynchronous logic
    enable : in std_logic; -- enable of mcu
    -- signals from fetch stage
    pc_id   : in unsigned(15 downto 0);
    inst_id : in std_logic_vector(15 downto 0);
    -- interconnect signals to fetch state
    stall : out std_logic;
    -- to and from execute stage
    op_ex : out std_logic_vector(2 downto 0);
    rt_ex : out std_logic_vector(2 downto 0);
    s1_ex : out std_logic_vector(2 downto 0);
    s2_ex : out std_logic_vector(2 downto 0);
    pc_ex : out unsigned(15 downto 0);
    operand0_ex : out std_logic_vector(15 downto 0);
    operand1_ex : out std_logic_vector(15 downto 0);
    operand2_ex : out std_logic_vector(15 downto 0);
    stomp    : in std_logic;
    --
    we_rf : in std_logic; -- write enable register field
    tgt_addr : in std_logic_vector(2 downto 0);
    tgt_data : in std_logic_vector(15 downto 0)
  );
END ENTITY decode_st;

ARCHITECTURE rtl OF decode_st IS
  -- registers
  signal op_execute_c, op_execute_s : std_logic_vector(2 downto 0);
  signal rt_execute_c, rt_execute_s : std_logic_vector(2 downto 0); -- target register
  signal s1_execute_c, s1_execute_s : std_logic_vector(2 downto 0);
  signal s2_execute_c, s2_execute_s : std_logic_vector(2 downto 0);
  signal operand0_c, operand0_s     : std_logic_vector(15 downto 0);
  signal operand1_c, operand1_s     : std_logic_vector(15 downto 0); -- output register from reg field
  signal operand2_c, operand2_s     : std_logic_vector(15 downto 0); -- output register from reg field
  signal pc_execute_s               : unsigned(15 downto 0);

  -- registers field
  signal reg_c, reg_s : t_risc16_regs;

  -- signals
  signal src1, src2 : std_logic_vector(2 downto 0); -- adress to reg. field
  signal extension_mux : std_logic;
  signal i_stall : std_logic;
  begin
  -----------------------------------------------------------------------------
  -- sequential
  -----------------------------------------------------------------------------
  clk_proc: process(clk, rst_n)
  begin
    if rst_n = '0' then
      reg_s <= C_RISC16_REGS_INIT;
      pc_execute_s <= (others => '0');
      op_execute_s <= (others => '0');
      rt_execute_s <= (others => '0');
      s1_execute_s <= (others => '0');
      s2_execute_s <= (others => '0');
      operand0_s <= (others => '0');
      operand1_s <= (others => '0');
      operand2_s <= (others => '0');
    elsif clk'event and clk = '1' then
      if enable = '1' then
        reg_s <= reg_c;
        pc_execute_s <= pc_id;
        op_execute_s <= op_execute_c;
        rt_execute_s <= rt_execute_c;
        s1_execute_s <= s1_execute_c;
        s2_execute_s <= s2_execute_c;
        operand0_s <= operand0_c;
        operand1_s <= operand1_c;
        operand2_s <= operand2_c;
      end if;
    end if;
  end process;
  -----------------------------------------------------------------------------
  -- combinational
  -----------------------------------------------------------------------------
  decode_logic: process(inst_id, stomp, i_stall)
  begin
    extension_mux <= '1';
    case inst_id(15 downto 13) is
      WHEN C_ADD =>
         op_execute_c <= inst_id(15 downto 13); -- instruction
         rt_execute_c <= inst_id(12 downto 10); -- destination register (rA)
         s1_execute_c <= inst_id(9 downto 7); --rB
         s2_execute_c <= inst_id(2 downto 0); --rC
         src1         <= inst_id(9 downto 7); --rB
         src2         <= inst_id(2 downto 0); --rC
      WHEN C_ADDI =>
         op_execute_c <= inst_id(15 downto 13); -- instruction
         rt_execute_c <= inst_id(12 downto 10); -- destination register (rA)
         s1_execute_c <= inst_id(9 downto 7); --rB
         s2_execute_c <= "000";
         src1         <= inst_id(9 downto 7); --rB
         src2         <= "000";
      WHEN C_NAND =>
         op_execute_c <= inst_id(15 downto 13); -- instruction
         rt_execute_c <= inst_id(12 downto 10); -- destination register (rA)
         s1_execute_c <= inst_id(9 downto 7); --rB
         s2_execute_c <= inst_id(2 downto 0); --rC
         src1         <= inst_id(9 downto 7); --rB
         src2         <= inst_id(2 downto 0); --rC
      WHEN C_LUI =>
         op_execute_c <= inst_id(15 downto 13); -- instruction
         rt_execute_c <= inst_id(12 downto 10); -- destination register (rA)
         s1_execute_c <= "000"; --rB
         s2_execute_c <= "000"; --rC
         src1         <= "000"; --rB
         src2         <= "000"; --rC
         extension_mux <= '0';
      WHEN C_SW =>
         op_execute_c <= inst_id(15 downto 13); -- instruction
         rt_execute_c <= "000"; -- there is no destination register in SW instr
         s1_execute_c <= inst_id(9 downto 7); --rB
         s2_execute_c <= inst_id(12 downto 10); --rA
         src1         <= inst_id(9 downto 7); --rB
         src2         <= inst_id(12 downto 10); --rA
      WHEN C_LW =>
         op_execute_c <= inst_id(15 downto 13); -- instruction
         rt_execute_c <= inst_id(12 downto 10); -- destination register (rA)
         s1_execute_c <= inst_id(9 downto 7); --rB
         s2_execute_c <= "000"; --rC
         src1         <= inst_id(9 downto 7); --rB
         src2         <= "000";
      WHEN C_BEQ =>
         op_execute_c <= inst_id(15 downto 13); -- instruction
         rt_execute_c <= "000"; -- there is no destination register in BEQ
         s1_execute_c <= inst_id(12 downto 10); --rA
         s2_execute_c <= inst_id(9 downto 7); --rB
         src1         <= inst_id(12 downto 10); --rA
         src2         <= inst_id(9 downto 7); --rB
      WHEN others => -- C_JALR
         op_execute_c <= inst_id(15 downto 13); -- instruction
         rt_execute_c <= inst_id(12 downto 10); -- destination register (rA)
         s1_execute_c <= inst_id(9 downto 7); --rB
         s2_execute_c <= "000"; --rC
         src1         <= inst_id(9 downto 7); --rB
         src2         <= "000";
    end case;
    if stomp = '1' OR i_stall = '1' then -- create NOP instruction in case stomp or stall
      op_execute_c <= C_ADD; -- instruction
      rt_execute_c <= C_R0;  -- destination register (rA)
      s1_execute_c <= C_R0;  --rB
      s2_execute_c <= "000"; --rC
      src1         <= "000";
      src2         <= "000";
    end if;
  end process decode_logic;

  -- when the instruction in execute stage is LW with same destination register as argument register in decode instruction pipeline must be stalled with NOP instruction
  stall_gen: process(inst_id(15 downto 13), op_execute_s)
  begin
    i_stall <= '0';
    if op_execute_s = C_LW then
      case inst_id(15 downto 13) is
        WHEN C_ADD =>
          if inst_id(9 downto 7) = rt_execute_s or inst_id(2 downto 0) = rt_execute_s then
            i_stall <= '1';
          end if;
        WHEN C_ADDI =>
          if inst_id(9 downto 7) = rt_execute_s then
            i_stall <= '1';
          end if;
        WHEN C_NAND =>
          if inst_id(9 downto 7) = rt_execute_s or inst_id(2 downto 0) = rt_execute_s then
            i_stall <= '1';
          end if;
        WHEN C_SW =>
          if inst_id(12 downto 10) = rt_execute_s or inst_id(9 downto 7) = rt_execute_s then
            i_stall <= '1';
          end if;
        WHEN C_LW =>
          if inst_id(9 downto 7) = rt_execute_s then
            i_stall <= '1';
          end if;
        WHEN C_BEQ =>
          if inst_id(12 downto 10) = rt_execute_s or inst_id(9 downto 7) = rt_execute_s then
            i_stall <= '1';
          end if;
        WHEN C_JALR =>
          if inst_id(9 downto 7) = rt_execute_s then
            i_stall <= '1';
          end if;
        WHEN others => -- C_LUI
          i_stall <= '0';
      end case;
    end if;
  end process stall_gen;

  operand0_mux:
  operand0_c <= (inst_id(9 downto 0) & "000000") when extension_mux = '0' else
                (inst_id(6) & inst_id(6) & inst_id(6) & inst_id(6) & inst_id(6) &
                 inst_id(6) & inst_id(6) & inst_id(6) & inst_id(6) & inst_id(6 downto 0));

  reg_field_operand1: process(src1)
  begin
    operand1_c <= operand1_s; -- default in case assigment is not needed due that assigment
    case src1 is
      when C_R0 =>
        operand1_c <= (others => '0');
      when C_R1 =>
        operand1_c <= reg_s.r1;
      when C_R2 =>
        operand1_c <= reg_s.r2;
      when C_R3 =>
        operand1_c <= reg_s.r3;
      when C_R4 =>
        operand1_c <= reg_s.r4;
      when C_R5 =>
        operand1_c <= reg_s.r5;
      when C_R6 =>
        operand1_c <= reg_s.r6;
      when others => -- C_R7
        operand1_c <= reg_s.r7;
    end case;
  end process reg_field_operand1;

  reg_field_operand2: process(src2)
  begin
    operand2_c <= operand2_s;
    case src2 is
      when C_R0 =>
        operand2_c <= (others => '0');
      when C_R1 =>
        operand2_c <= reg_s.r1;
      when C_R2 =>
        operand2_c <= reg_s.r2;
      when C_R3 =>
        operand2_c <= reg_s.r3;
      when C_R4 =>
        operand2_c <= reg_s.r4;
      when C_R5 =>
        operand2_c <= reg_s.r5;
      when C_R6 =>
        operand2_c <= reg_s.r6;
      when others => -- C_R7
        operand2_c <= reg_s.r7;
    end case;
  end process reg_field_operand2;

  -- write into reg field
  reg_field_write: process(we_rf, reg_s, tgt_data, tgt_addr)
  begin
    reg_c <= reg_s;
    if we_rf = '1' then
      case tgt_addr is
        when C_R1 =>
          reg_c.r1 <= tgt_data;
        when C_R2 =>
          reg_c.r2 <= tgt_data;
        when C_R3 =>
          reg_c.r3 <= tgt_data;
        when C_R4 =>
          reg_c.r4 <= tgt_data;
        when C_R5 =>
          reg_c.r5 <= tgt_data;
        when C_R6 =>
          reg_c.r6 <= tgt_data;
        when C_R7 =>
          reg_c.r7 <= tgt_data;
        when others =>
          reg_c <= reg_s;
      end case;
    end if;
  end process reg_field_write;

  -----------------------------------------------------------------------------
  -- output assigment
  -----------------------------------------------------------------------------
  pc_ex <= pc_execute_s;
  operand0_ex   <= operand0_s;
  operand1_ex   <= operand1_s;
  operand2_ex   <= operand2_s;
  op_ex         <= op_execute_s;
  rt_ex         <= rt_execute_s;
  s1_ex         <= s1_execute_s;
  s2_ex         <= s2_execute_s;
  stall      <= i_stall;
END ARCHITECTURE RTL;

