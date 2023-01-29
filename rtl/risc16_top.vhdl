LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.risc16_pkg.all;

ENTITY risc16_top IS
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
    -- data interface
    dat_addr       : out std_logic_vector(15 downto 0);
    dat_in         : out std_logic_vector(15 downto 0);
    dat_out        : in  std_logic_vector(15 downto 0);
    dat_we         : out std_logic
    --dat_ready      : in  std_logic;

    --interrupt : in std_logic
  );
END ENTITY risc16_top;

ARCHITECTURE rtl OF risc16_top IS
  -- components
  component fetch_st IS
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
  END component;

  component decode_st IS
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
  END component;

  component execute_st IS
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
  END component;

  component memory_st IS
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
  END component;

  component writeback_st IS
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
  END component;

  -- signals
  -- signal IF to ID stage
  signal pc_fe_id : unsigned(15 downto 0);
  signal inst_fe_id : std_logic_vector(15 downto 0);
  signal stall : std_logic;
  -- signals ID to EX state
  signal op_id_if, rt_id_if, s1_id_if, s2_id_if : std_logic_vector(2 downto 0);
  signal pc_id_ex : unsigned(15 downto 0);
  signal operand0_id_ex, operand1_id_ex, operand2_id_ex : std_logic_vector(15 downto 0);
  signal stomp : std_logic;
  -- signals ex to if
  signal pc_mux_ex_if : std_logic_vector(1 downto 0);
  signal pc_jal_ex_if : unsigned (15 downto 0);
  signal pc_beq_ex_if : unsigned (15 downto 0);
  -- signals between ex and mem
  signal op_ex_mem : std_logic_vector(2 downto 0);
  signal rt_ex_mem : std_logic_vector(2 downto 0);
  signal store_data : std_logic_vector(15 downto 0);
  signal alu : std_logic_vector(15 downto 0);
  -- signals between write back and decode
  signal we_rf : std_logic;
  signal tgt_dec : std_logic_vector(15 downto 0);
  signal tgt_dec_addr : std_logic_vector(2 downto 0);
  -- data frowarding signals TODO
  signal data_wb : std_logic_vector(15 downto 0);
  signal data_end : std_logic_vector(15 downto 0);
  signal rt_wb : std_logic_vector(2 downto 0);
  signal rt_end : std_logic_vector(2 downto 0);


  begin

  i_fetch : fetch_st
  port map (
    clk    => clk,
    rst_n  => rst_n,  -- asynchronous logic
    enable => enable, -- enable of mcu
    --halt   => halt,
    -- instruction interface
    inst_addr       => inst_addr, -- PC addr
    inst_data       => inst_data,
    inst_re         => inst_re,
    inst_valid      => inst_valid,
    -- interconnect signals interface
    stall  => stall,
    stomp  => stomp,
    pc_mux => pc_mux_ex_if,
    pc_jal => pc_jal_ex_if,
    pc_beq => pc_beq_ex_if,
    -- signals to next stage
    pc_id   => pc_fe_id,
    inst_id => inst_fe_id
  );

  i_decode_st : decode_st
  port map(
    clk    => clk,
    rst_n  => rst_n, -- asynchronous logic
    enable => enable,-- enable of mcu
    -- signals from fetch stage
    pc_id   => pc_fe_id,
    inst_id => inst_fe_id,
    -- interconnect signals to fetch state
    stall => stall,
    -- to and from execute stage
    op_ex => op_id_if,
    rt_ex => rt_id_if,
    s1_ex => s1_id_if,
    s2_ex => s2_id_if,
    pc_ex => pc_id_ex,
    operand0_ex => operand0_id_ex,
    operand1_ex => operand1_id_ex,
    operand2_ex => operand2_id_ex,
    stomp    => stomp,
    --
    we_rf => we_rf,
    tgt_addr => tgt_dec_addr,
    tgt_data => tgt_dec
  );

  i_execute_st : execute_st
  port map (
    clk    => clk,
    rst_n  => rst_n,
    enable => enable,
    -- signals from decode state
    op_ex => op_id_if,
    rt_ex => rt_id_if,
    s1_ex => s1_id_if,
    s2_ex => s2_id_if,
    pc_ex => pc_id_ex,
    operand0_ex => operand0_id_ex,
    operand1_ex => operand1_id_ex,
    operand2_ex => operand2_id_ex,
    stomp    => stomp,
    -- signals to and from mem stage
    op_mem => op_ex_mem,
    rt_mem => rt_ex_mem,
    -- pc_mem : out std_logic_vector(15 downto 0);
    store_data => store_data,
    alu        => alu,
    -- forwarding signals
    data_wb  => data_wb,
    data_end => data_end,
    rt_wb    => rt_wb,
    rt_end   => rt_end,
    -- pc to fetch state
    pc_mux => pc_mux_ex_if,
    pc_id_beq  => pc_beq_ex_if,
    pc_id_jal => pc_jal_ex_if
  );

  i_memory_st : memory_st
  port map (
    clk    => clk,
    rst_n  => rst_n,
    enable => enable,
    -- signals from execute state
    op_mem => op_ex_mem,
    rt_mem => rt_ex_mem,
    store_data => store_data,
    alu => alu,
    -- signals to writeback stage
    rt_wb => rt_wb,
    write_data => data_wb,
    -- data interface
    data_in  => dat_in,
    data_addr => dat_addr,
    data_out => dat_out,
    we_data => dat_we
    --dat_ready =>
  );


  i_writeback_st : writeback_st
  port map(
    clk    => clk,
    rst_n  => rst_n,
    enable => enable,
    -- signals from memory state and also for data forwarding
    rt_mem => rt_wb,
    write_data => data_wb,
    -- data forwarding to  execute stage
    write_data_end => data_end,
    rt_end => rt_end,
    -- to decode stage
    we_rf => we_rf,
    tgt_dec => tgt_dec,
    tgt_dec_addr => tgt_dec_addr
  );

END ARCHITECTURE RTL;
