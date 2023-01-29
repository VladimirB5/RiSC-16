LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.risc16_pkg.all;

ENTITY fetch_st IS
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
    -- interconnect signals interface
    stall  : in std_logic;
    stomp  : in std_logic;
    pc_mux : in std_logic_vector(1 downto 0);
    pc_jal : in unsigned(15 downto 0);
    pc_beq : in unsigned(15 downto 0);
    -- signals to next stage
    pc_id   : out unsigned(15 downto 0);
    inst_id : out std_logic_vector(15 downto 0)
  );
END ENTITY fetch_st;

ARCHITECTURE rtl OF fetch_st IS
  -- registers 
  signal pc_id_c, pc_id_s : unsigned(15 downto 0);
  signal inst_c, inst_s   : std_logic_vector(15 downto 0);
  signal pc_if_c, pc_if_s : unsigned(15 downto 0);
  signal re_c, re_s       : std_logic;
  -- signals

  begin
  -----------------------------------------------------------------------------
  -- sequential 
  ----------------------------------------------------------------------------- 
  clk_proc: process(clk, rst_n)
  begin
    if rst_n = '0' then 
      pc_id_s <= (others => '0');
      inst_s  <= (others => '0');
      pc_if_s <= (others => '0');
      re_s    <= '0';
    elsif clk'event and clk = '1' then
      if enable = '1' then 
        pc_id_s <= pc_id_c;
        inst_s  <= inst_c;
        pc_if_s <= pc_if_c;
        re_s    <= re_c;
      end if;
    end if;
  end process;
  -----------------------------------------------------------------------------
  -- combinational 
  -----------------------------------------------------------------------------  
  pc_if_proc: process(stall, pc_mux, inst_valid, pc_if_s, pc_beq, pc_jal)
  begin 
    pc_if_c <= pc_if_s;
    if stall = '1' then
      pc_if_c <= pc_if_s;
    elsif pc_mux = "01" then -- beq
      pc_if_c <= pc_beq;
    elsif pc_mux = "10" then -- jal
      pc_if_c <= pc_jal;
    elsif inst_valid = '1' then
      pc_if_c <= pc_if_s + 1;
    end if;
  end process pc_if_proc;
  
  pc_id_c <= pc_if_s when stall = '0' and inst_valid = '1' else
             pc_id_s;

  re_c <= '1' when enable = '1'  else
          '0';
  
  inst_mux_proc:
  inst_c <= inst_data when inst_valid = '1' and stall = '0' and stomp = '0' else
            (others => '0') when stomp = '1' else -- use NOP when there is stomp event
            inst_s;

  -----------------------------------------------------------------------------
  -- output assigment 
  -----------------------------------------------------------------------------  
  inst_addr <= std_logic_vector(pc_if_s);
  inst_re   <= re_s;
  pc_id     <= pc_id_s;
  inst_id   <= inst_s;
END ARCHITECTURE RTL; 
