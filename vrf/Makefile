# Makefile for SystemC

export PRJ_PATH	= $(shell pwd)/..
export DESIGN	= top

all:
	@echo "Verification based on verilator and SystemC"

lint:
	verilator --lint-only -f filelist.f --top-module $(DESIGN)

cmp:
	verilator -Wno-fatal -f filelist.f --top-module $(DESIGN) --sc --trace --assert --coverage --exe sc_main.cpp
	make -C obj_dir -f V$(DESIGN).mk V$(DESIGN)

run:
	./obj_dir/V$(DESIGN) +trace

wave:
	gtkwave ./logs/wave.vcd &

clean:
	@rm -rf obj_dir logs

