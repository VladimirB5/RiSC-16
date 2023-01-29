#!/bin/sh

rm -f work-obj08.cf
echo "basic test"
#compile
ghdl -a --std=08 rtl/risc16_pkg.vhdl
ghdl -a --std=08 rtl/fetch_st.vhdl
ghdl -a --std=08 rtl/decode_st.vhdl
ghdl -a --std=08 rtl/execute_st.vhdl
ghdl -a --std=08 rtl/memory_st.vhdl
ghdl -a --std=08 rtl/writeback_st.vhdl
ghdl -a --std=08 rtl/risc16_top.vhdl

# compile bench
ghdl -a --std=08 tb/data_ram.vhdl
ghdl -a --std=08 tb/testcases/basic/rom.vhdl
ghdl -a --std=08 tb/testcases/basic/test.vhdl
ghdl -a --std=08 tb/tb_top.vhdl

ghdl -e --std=08 -fpsl tb_top
ghdl -r --std=08 -fpsl tb_top --wave=basic_risc16.ghw

rm -f work-obj08.cf
echo "beq test"

#compile
ghdl -a --std=08 rtl/risc16_pkg.vhdl
ghdl -a --std=08 rtl/fetch_st.vhdl
ghdl -a --std=08 rtl/decode_st.vhdl
ghdl -a --std=08 rtl/execute_st.vhdl
ghdl -a --std=08 rtl/memory_st.vhdl
ghdl -a --std=08 rtl/writeback_st.vhdl
ghdl -a --std=08 rtl/risc16_top.vhdl

# compile bench
ghdl -a --std=08 tb/data_ram.vhdl
ghdl -a --std=08 tb/testcases/beq/rom.vhdl
ghdl -a --std=08 tb/testcases/beq/test.vhdl
ghdl -a --std=08 tb/tb_top.vhdl

ghdl -e --std=08 -fpsl tb_top
ghdl -r --std=08 -fpsl tb_top --wave=beq_risc16.ghw
