LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.risc16_pkg.all;

ENTITY writeback_st IS
  port (
    clk    : in std_logic;
    rst_n  : in std_logic; -- asynchronous logic
    enable : in std_logic; -- enable of mcu
    -- signals from memory state and also for data forwarding
    rt_mem : in std_logic_vector(2 downto 0);
    write_data : in std_logic_vector(15 downto 0);
    -- data forwarding to  execute stage
    write_data_end : out std_logic_vector(15 downto 0);
    rt_end : out std_logic_vector(2 downto 0);
    -- to decode stage
    we_rf : out std_logic;
    tgt_dec : out std_logic_vector(15 downto 0);
    tgt_dec_addr : out std_logic_vector(2 downto 0)
  );
END ENTITY writeback_st;

ARCHITECTURE rtl OF writeback_st IS
-- registers
signal write_data_end_s : std_logic_vector(15 downto 0);
signal rt_end_s : std_logic_vector(2 downto 0);

-- signals

begin
  -----------------------------------------------------------------------------
  -- sequential
  -----------------------------------------------------------------------------
  clk_proc: process(clk, rst_n)
  begin
    if rst_n = '0' then
      write_data_end_s <= (others => '0');
      rt_end_s <= (others => '0');
    elsif clk'event and clk = '1' then
      if enable = '1' then
        write_data_end_s <= write_data;
        rt_end_s <= rt_mem;
      end if;
    end if;
  end process clk_proc;

  -----------------------------------------------------------------------------
  -- combinational
  -----------------------------------------------------------------------------
  p_tgt_we_ctrl:
  we_rf <= '0' when rt_mem = "000" else
           '1';

  -----------------------------------------------------------------------------
  -- output assigment
  -----------------------------------------------------------------------------
  write_data_end <= write_data_end_s;
  rt_end <= rt_end_s;
  tgt_dec_addr <= rt_mem;
  tgt_dec <= write_data;
END ARCHITECTURE RTL;
