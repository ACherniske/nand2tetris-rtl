# Nand2Tetris-FPGA Build System (Hierarchical)
BOARD      ?= icebreaker
TOP        := Computer
DEVICE     := up5k
PCF        := constraints/icebreaker.pcf

# Toolchain Path Setup
OSS_CAD_SUITE_PATH ?= $(HOME)/oss-cad-suite
ifneq ($(wildcard $(OSS_CAD_SUITE_PATH)/bin/yosys),)
    export PATH := $(OSS_CAD_SUITE_PATH)/bin:$(PATH)
endif

# Files - Updated to find files in subdirectories
# Use shell find to grab all .v files in rtl/ recursively
SOURCES    := $(shell find rtl -name "*.v")
TB_SOURCES := $(wildcard tb/*.v)

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
	# Include the rtl directory in the search path for modules
	$(YOSYS) -q -p "read_verilog -I rtl/core -I rtl/memory -I rtl/io -I rtl/top $(SOURCES); synth_ice40 -top $(TOP) -json $@"

build/$(TOP).asc: build/$(TOP).json $(PCF)
	@echo "  PNR    $@"
	$(NEXTPNR) -q --$(DEVICE) --package sg48 --pcf $(PCF) --json $< --asc $@

build/$(TOP).bin: build/$(TOP).asc
	@echo "  PACK   $@"
	$(ICEPACK) $< $@

# --- Simulation ---
# Usage: make tb FILE=Computer_tb
tb:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make tb FILE=<filename_without_tb_suffix>"; \
	else \
		mkdir -p build; \
		$(IVERILOG) -I rtl/core -I rtl/memory -I rtl/io -I rtl/top -o build/sim.out tb/$(FILE)_tb.v $(SOURCES); \
		if [ $$? -eq 0 ]; then \
			$(VVP) build/sim.out; \
			if [ -f *.vcd ]; then \
				mv *.vcd build/$(FILE).vcd; \
				echo "  GTK    Launching gtkwave..."; \
				gtkwave build/$(FILE).vcd & \
			fi \
		fi \
	fi

# --- Hardware Programming ---
flash: build/$(TOP).bin
	@echo "  PROG   $<"
	$(ICEPROG) $<

# Upload program via UART
prog:
	@echo "  UART   $(PROGRAM)"
	$(PYTHON) tools/flasher.py $(PROGRAM)

clean:
	rm -rf build/ *.vcd
