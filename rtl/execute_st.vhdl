LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.risc16_pkg.all;

ENTITY execute_st IS
  port (
    clk    : in std_logic;
    rst_n  : in std_logic; -- asynchronous logic
    enable : in std_logic; -- enable of mcu
    -- signals from decode state
    op_ex : in std_logic_vector(2 downto 0);
    rt_ex : in std_logic_vector(2 downto 0);
    s1_ex : in std_logic_vector(2 downto 0);
    s2_ex : in std_logic_vector(2 downto 0);
    pc_ex : in unsigned(15 downto 0);
    operand0_ex : in std_logic_vector(15 downto 0);
    operand1_ex : in std_logic_vector(15 downto 0);
    operand2_ex : in std_logic_vector(15 downto 0);
    stomp    : out std_logic;
    -- signals to and from mem stage
    op_mem : out std_logic_vector(2 downto 0);
    rt_mem : out std_logic_vector(2 downto 0);
    -- pc_mem : out std_logic_vector(15 downto 0);
    store_data : out std_logic_vector(15 downto 0);
    alu        : out std_logic_vector(15 downto 0);
    -- forwarding signals
    data_wb  : in std_logic_vector(15 downto 0);
    data_end : in std_logic_vector(15 downto 0);
    rt_wb    : in std_logic_vector(2 downto 0);
    rt_end   : in std_logic_vector(2 downto 0);
    -- pc to fetch state
    pc_mux : out std_logic_vector(1 downto 0);
    pc_id_beq  : out unsigned(15 downto 0);
    pc_id_jal : out unsigned(15 downto 0)
  );
END ENTITY execute_st;


ARCHITECTURE rtl OF execute_st IS
-- registers
signal alu_out_c, alu_out_s : std_logic_vector(15 downto 0);
signal store_data_s : std_logic_vector(15 downto 0);
signal op_mem_c, op_mem_s : std_logic_vector(2 downto 0);
signal rt_mem_c, rt_mem_s : std_logic_vector(2 downto 0);

--signals
signal mux_alu1_ctrl : std_logic_vector(1 downto 0);
signal mux_alu2_ctrl : std_logic_vector(1 downto 0);
signal mux_scr2_ctrl : std_logic_vector(1 downto 0);
signal alu_op : std_logic_vector(1 downto 0);
signal src1_mux : std_logic_vector(15 downto 0);
signal src2_mux : std_logic_vector(15 downto 0);
signal alu_in2  : std_logic_vector(15 downto 0);
signal pc_plus_1 : unsigned(15 downto 0);
signal alu_eq : std_logic;
signal stomp_i : std_logic;
begin

  -----------------------------------------------------------------------------
  -- sequential
  -----------------------------------------------------------------------------
  clk_proc: process(clk, rst_n)
  begin
    if rst_n = '0' then
      alu_out_s <= (others => '0');
      store_data_s <= (others => '0');
      op_mem_s <= (others => '0');
      rt_mem_s <= (others => '0');
    elsif clk'event and clk = '1' then
      if enable = '1' then
        alu_out_s <= alu_out_c;
        store_data_s <= src2_mux;
        op_mem_s <= op_ex;
        rt_mem_s <= rt_ex;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- combinational
  -----------------------------------------------------------------------------
  p_data_forward_ctrl_alu1: process(s1_ex, rt_mem_s, rt_wb, rt_end)
  begin
    mux_alu1_ctrl <= "00";
    if s1_ex = C_R0 then -- when operand is 0
      mux_alu1_ctrl <= "00";
    elsif s1_ex = rt_mem_s then
      mux_alu1_ctrl <= "01"; -- from memory stage
    elsif s1_ex = rt_wb then
      mux_alu1_ctrl <= "10"; -- from wb stage
    elsif s1_ex = rt_end then
      mux_alu1_ctrl <= "11"; -- after wb stage
    end if;
  end process p_data_forward_ctrl_alu1;

  p_data_forward_ctrl_alu2: process(s2_ex, rt_mem_s, rt_wb, rt_end)
  begin
    mux_alu2_ctrl <= "00";
    if s2_ex = C_R0 then-- when operand is 0
      mux_alu2_ctrl <= "00";
    elsif s2_ex = rt_mem_s then
      mux_alu2_ctrl <= "01"; -- from memory stage
    elsif s2_ex = rt_wb then
      mux_alu2_ctrl <= "10"; -- from wb stage
    elsif s2_ex = rt_end then
      mux_alu2_ctrl <= "11"; -- after wb stage
    end if;
  end process p_data_forward_ctrl_alu2;

  p_alu_ctrl: process(op_ex, alu_eq)
  begin
    alu_op <= "00";
    mux_scr2_ctrl <= "00";
    stomp_i <= '0';
    pc_mux <= "00";
    case op_ex is
      WHEN C_ADD =>
        alu_op <= "00";
        mux_scr2_ctrl <= "00";  -- both from reg field
      WHEN C_ADDI =>
        alu_op <= "00"; -- add
        mux_scr2_ctrl <= "01"; -- from operand 0
      WHEN C_NAND =>
        alu_op <= "01";
        mux_scr2_ctrl <= "00";  -- both from reg field
      WHEN C_LUI =>
        alu_op <= "11"; -- pass
        mux_scr2_ctrl <= "01"; -- from operand 0
      WHEN C_SW =>
        alu_op <= "00"; -- add
        mux_scr2_ctrl <= "01"; -- from operand 0
      WHEN C_LW =>
        alu_op <= "00"; -- add
        mux_scr2_ctrl <= "01"; -- from operand 0
      WHEN C_BEQ =>
        alu_op <= "10"; -- eq
        mux_scr2_ctrl <= "00"; -- both from reg field
        if alu_eq = '1' then
          stomp_i <= '1';
          pc_mux <= "01"; -- BEQ
        end if;
      WHEN others => -- C_JALR =>
        alu_op <= "11"; -- pass
        mux_scr2_ctrl <= "10"; -- pc + 1 to alu
        pc_mux <= "10";
        stomp_i <= '1';
    end case;
  end process p_alu_ctrl;

  pc_plus_1 <= pc_ex + 1;
  pc_id_beq <= pc_plus_1 + unsigned(operand0_ex);

  p_data_forward_mux_src1: process(mux_alu1_ctrl, operand1_ex, alu_out_s, data_wb, data_end)
  begin
    case mux_alu1_ctrl is
      when "00" => -- execute stage
        src1_mux <= operand1_ex;
      when "01" => -- memory stage
        src1_mux <= alu_out_s;
      when "10" =>  -- writeback stage
        src1_mux <= data_wb;
      when others => -- end
        src1_mux <= data_end;
    end case;
  end process p_data_forward_mux_src1;

  p_data_forward_mux_src2: process(mux_alu2_ctrl, operand2_ex, alu_out_s, data_wb, data_end)
  begin
    case mux_alu2_ctrl is
      when "00" => -- execute stage
        src2_mux <= operand2_ex;
      when "01" => -- memory stage
        src2_mux <= alu_out_s;
      when "10" =>  -- writeback stage
        src2_mux <= data_wb;
      when others => -- end
        src2_mux <= data_end;
    end case;
  end process p_data_forward_mux_src2;

  p_scr2_mux: process(mux_scr2_ctrl, src2_mux, operand0_ex, pc_plus_1)
  begin
    case mux_scr2_ctrl is
      when "00" =>
        alu_in2 <= src2_mux;
      when "01" =>
        alu_in2 <= operand0_ex;
      when others =>
        alu_in2 <= std_logic_vector(pc_plus_1);
    end case;
  end process p_scr2_mux;

  p_alu: process(alu_op, src1_mux, alu_in2)
  begin
    alu_eq <= '0';
    case alu_op is
      when "00" => -- add
        alu_out_c <= std_logic_vector(unsigned(src1_mux) + unsigned(alu_in2));
      when "01" => -- nand
        alu_out_c <= src1_mux nand alu_in2;
      when "10" => -- eq
        alu_out_c <= (others => '0');
        if src1_mux = alu_in2 then
          alu_eq <= '1';
        end if;
      when others => -- pass
        alu_out_c <= alu_in2;
    end case;
  end process p_alu;

  -----------------------------------------------------------------------------
  -- output assigment
  -----------------------------------------------------------------------------
  pc_id_jal <= unsigned(src1_mux);
  stomp <= stomp_i;
  alu <= alu_out_s;
  store_data <= store_data_s;
  op_mem <= op_mem_s;
  rt_mem <= rt_mem_s;
END ARCHITECTURE RTL;
