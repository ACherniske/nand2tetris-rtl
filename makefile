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
# Add all your RTL files here
SOURCES := $(wildcard rtl/*.v)
# The ROM content is now decoupled from the bitstream build
# We use a placeholder .mem file just to satisfy Yosys if needed
ROM_MEM := rom_init.mem

# Tools
YOSYS    := yosys
NEXTPNR  := nextpnr-ice40
ICEPACK  := icepack
ICEPROG  := iceprog
PYTHON   := python3

.PHONY: all clean flash prog

all: build/$(TOP).bin

# 1. Synthesis (Using generic ROM initialization if needed)
build/$(TOP).json: $(SOURCES)
	@echo "  SYN    $@"
	@mkdir -p build
	$(YOSYS) -q -p "synth_ice40 -top $(TOP) -json $@" $(SOURCES)

# 2. Place and Route
build/$(TOP).asc: build/$(TOP).json $(PCF)
	@echo "  PNR    $@"
	$(NEXTPNR) -q --$(DEVICE) --pcf $(PCF) --json $< --asc $@

# 3. Pack Bitstream
build/$(TOP).bin: build/$(TOP).asc
	@echo "  PACK   $@"
	$(ICEPACK) $< $@

# 4. Flash Bitstream (Standard FPGA programming)
flash: build/$(TOP).bin
	@echo "  PROG   $<"
	$(ICEPROG) $<

# 5. Program ROM via UART Bootloader
# Usage: make prog PROGRAM=programs/asm/Add.hack
prog:
	@echo "  UART   $(PROGRAM)"
	$(PYTHON) tools/flasher.py $(PROGRAM)

clean:
	rm -rf build/