# Makefile for ModelSim

all:
	@echo "Verification based on ModelSim"

lint:
	vlib work
	vmap work work
	vlog -mfcu -lint -sv -timescale 1ns/1ps -f filelist.f tb_top.sv

cmp:
	vlib work
	vmap work work
	vlog -mfcu -sv -timescale 1ns/1ps -f filelist.f tb_top.sv

run:
	vsim -c -do run.do

clean:
	@rm -rf work wave.vcd vsim.wlf transcript modelsim.ini

