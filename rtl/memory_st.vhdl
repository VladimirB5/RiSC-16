LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.risc16_pkg.all;

ENTITY memory_st IS
  port (
    clk    : in std_logic;
    rst_n  : in std_logic; -- asynchronous logic
    enable : in std_logic; -- enable of mcu
    -- signals from execute state
    op_mem : in std_logic_vector(2 downto 0);
    rt_mem : in std_logic_vector(2 downto 0);
    store_data : in std_logic_vector(15 downto 0);
    alu: in std_logic_vector(15 downto 0);
    -- signals to writeback stage
    rt_wb : out std_logic_vector(2 downto 0);
    write_data : out std_logic_vector(15 downto 0);
    -- data interface
    data_in  : out std_logic_vector(15 downto 0);
    data_addr : out std_logic_vector(15 downto 0);
    data_out : in std_logic_vector(15 downto 0);
    we_data : out std_logic
    --dat_ready : in  std_logic
  );
END ENTITY memory_st;


ARCHITECTURE rtl OF memory_st IS
-- signal
signal alu_i : std_logic_vector(15 downto 0);
signal data_i : std_logic_vector(15 downto 0);
signal mux_out_ctrl : std_logic;
signal rt_wb_s : std_logic_vector(2 downto 0);

-- registers
signal write_data_c, write_data_s : std_logic_vector(15 downto 0);

begin
  -----------------------------------------------------------------------------
  -- sequential
  -----------------------------------------------------------------------------
  clk_proc: process(clk, rst_n)
  begin
    if rst_n = '0' then
      write_data_s <= (others => '0');
      rt_wb_s <= (others => '0');
    elsif clk'event and clk = '1' then
      if enable = '1' then
        write_data_s <= write_data_c;
        rt_wb_s <= rt_mem;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- combinational
  -----------------------------------------------------------------------------
  p_mux_out_ctrl: process(op_mem)
  begin
    mux_out_ctrl <= '1';
    we_data <= '0';
    case op_mem is
      WHEN C_ADD =>
        we_data <= '0';
        mux_out_ctrl <= '1';
      WHEN C_ADDI =>
        we_data <= '0';
        mux_out_ctrl <= '1';
      WHEN C_NAND =>
        we_data <= '0';
        mux_out_ctrl <= '1';
      WHEN C_LUI =>
        we_data <= '0';
        mux_out_ctrl <= '1';
      WHEN C_SW =>
        we_data <= '1';
        mux_out_ctrl <= '1';
      WHEN C_LW =>
        we_data <= '0';
        mux_out_ctrl <= '0';
      WHEN C_BEQ =>
        we_data <= '0';
        mux_out_ctrl <= '1';
      WHEN others => -- C_JALR
        we_data <= '0';
        mux_out_ctrl <= '1';
    end case;
  end process p_mux_out_ctrl;

  alu_i <= alu;
  data_i <= store_data;

  p_mux_out:
  write_data_c <= data_out when mux_out_ctrl = '0' else
                  alu_i;

  -----------------------------------------------------------------------------
  -- output assigment
  -----------------------------------------------------------------------------
data_in <= data_i;
data_addr <= alu_i;
rt_wb <= rt_wb_s;
write_data <= write_data_s;
END ARCHITECTURE RTL;
