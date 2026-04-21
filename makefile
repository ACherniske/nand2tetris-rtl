# Nand2Tetris-FPGA Build System
BOARD      ?= icebreaker
TOP        := top
DEVICE     := up5k
PCF        := constraints/icebreaker.pcf

# Toolchain Path Setup
OSS_CAD_SUITE_PATH ?= $(HOME)/oss-cad-suite
ifneq ($(wildcard $(OSS_CAD_SUITE_PATH)/bin/yosys),)
    export PATH := $(OSS_CAD_SUITE_PATH)/bin:$(PATH)
endif

# Files
SOURCES    := $(wildcard rtl/*.v)
TB_SOURCES := $(wildcard tb/*.v)
ROM_MEM    := rom_init.mem

# Tools
YOSYS    := yosys
NEXTPNR  := nextpnr-ice40
ICEPACK  := icepack
ICEPROG  := iceprog
PYTHON   := python3
IVERILOG := iverilog
VVP      := vvp

.PHONY: all clean flash prog tb

all: build/$(TOP).bin

# --- Synthesis & PNR ---
build/$(TOP).json: $(SOURCES)
	@echo "  SYN    $@"
	@mkdir -p build
	$(YOSYS) -q -p "synth_ice40 -top $(TOP) -json $@" $(SOURCES)

build/$(TOP).asc: build/$(TOP).json $(PCF)
	@echo "  PNR    $@"
	$(NEXTPNR) -q --$(DEVICE) --pcf $(PCF) --json $< --asc $@

build/$(TOP).bin: build/$(TOP).asc
	@echo "  PACK   $@"
	$(ICEPACK) $< $@

# --- Simulation ---
# Usage: make tb FILE=ALU
tb:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make tb FILE=<name>"; \
	else \
		mkdir -p build; \
		$(IVERILOG) -DVERBOSE -o build/sim.out tb/$(FILE)_tb.v $(SOURCES); \
		if [ $$? -eq 0 ]; then \
			$(VVP) build/sim.out; \
			if [ -f test.vcd ]; then \
				mv test.vcd build/$(FILE).vcd; \
				echo "  GTK    Launching gtkwave..."; \
				gtkwave build/$(FILE).vcd & \
			else \
				echo "  ERROR  VCD file not generated."; \
			fi \
		fi \
	fi

# --- Hardware Programming ---
flash: build/$(TOP).bin
	@echo "  PROG   $<"
	$(ICEPROG) $<

prog:
	@echo "  UART   $(PROGRAM)"
	$(PYTHON) tools/flasher.py $(PROGRAM)

clean:
	rm -rf build/ *.vcd
