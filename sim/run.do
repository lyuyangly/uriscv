vsim -voptargs=+acc work.tb_top
add wave -depth 100 sim:/tb_top/u_dut/*

#vcd file wave.vcd
#vcd add sim:/tb_top/u_dut/*

run  -all

quit -f

