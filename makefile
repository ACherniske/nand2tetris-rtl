# Nand2Tetris-FPGA Build System
# Enhanced with UART uploading and improved automation

BOARD      ?= icebreaker
TOP        := Computer
DEVICE     := up5k
PCF        := constraints/icebreaker.pcf

# Toolchain Path Setup
OSS_CAD_SUITE_PATH ?= $(HOME)/oss-cad-suite
ifneq ($(wildcard $(OSS_CAD_SUITE_PATH)/bin/yosys),)
    export PATH := $(OSS_CAD_SUITE_PATH)/bin:$(PATH)
endif

# Files - Recursively find all .v files in rtl/
SOURCES    := $(shell find rtl -name "*.v" 2>/dev/null)
TB_SOURCES := $(wildcard tb/*.v)

# Default program for UART upload (can override: make upload PROG=programs/test.hack)
PROG ?= programs/test_program.hack

# UART port - auto-detect or override
UART_PORT ?= /dev/ttyUSB1
BAUD_RATE ?= 115200

# Tools
YOSYS      := yosys
NEXTPNR    := nextpnr-ice40
ICEPACK    := icepack
ICEPROG    := iceprog
PYTHON     := python3
IVERILOG   := iverilog
VVP        := vvp
UPLOAD_PY  := tools/upload.py

# Color output (if terminal supports it)
NO_COLOR   := \033[0m
GREEN      := \033[0;32m
YELLOW     := \033[0;33m
CYAN       := \033[0;36m

.PHONY: all clean flash upload prog tb sim help stats deps check

# Default target
all: build/$(TOP).bin

# === Synthesis & PnR ===

build/$(TOP).json: $(SOURCES)
	@echo "$(CYAN)  SYN    $(NO_COLOR)$@"
	@mkdir -p build
	$(YOSYS) -p "read_verilog -I rtl/core -I rtl/memory -I rtl/io -I rtl/top $(SOURCES); \
	                synth_ice40 -top $(TOP) -json $@"

build/$(TOP).asc: build/$(TOP).json $(PCF)
	@echo "$(CYAN)  PNR    $(NO_COLOR)$@"
	$(NEXTPNR) --$(DEVICE) --package sg48 --pcf $(PCF) --json $< --asc $@ \
	           --freq 12

build/$(TOP).bin: build/$(TOP).asc
	@echo "$(CYAN)  PACK   $(NO_COLOR)$@"
	$(ICEPACK) $< $@
	@echo "$(GREEN)Build complete: $@$(NO_COLOR)"

# === Hardware Programming ===

# Flash bitstream to FPGA (permanent until power cycle)
flash: build/$(TOP).bin
	@echo "$(YELLOW)  PROG   $(NO_COLOR)$<"
	$(ICEPROG) $<
	@echo "$(GREEN)FPGA programmed successfully$(NO_COLOR)"

# Program FPGA + Upload program via UART (convenience target)
prog: flash upload

# Upload .hack program via UART (hold reset button first!)
upload: $(PROG)
	@echo "$(YELLOW)  UART   $(NO_COLOR)$(PROG) -> $(UART_PORT)"
	@if [ ! -f "$(UPLOAD_PY)" ]; then \
		echo "$(YELLOW)Warning: $(UPLOAD_PY) not found, using local upload.py$(NO_COLOR)"; \
		UPLOAD_SCRIPT=./upload.py; \
	else \
		UPLOAD_SCRIPT=$(UPLOAD_PY); \
	fi; \
	if [ ! -f "$$UPLOAD_SCRIPT" ]; then \
		echo "Error: Upload script not found"; \
		exit 1; \
	fi; \
	$(PYTHON) $$UPLOAD_SCRIPT $(UART_PORT) $(PROG) -b $(BAUD_RATE)

# Upload with verbose output
upload-verbose: $(PROG)
	@echo "$(YELLOW)  UART   $(NO_COLOR)$(PROG) -> $(UART_PORT) (verbose)"
	$(PYTHON) $(UPLOAD_PY) $(UART_PORT) $(PROG) -b $(BAUD_RATE) -v

# === Simulation ===

# Run testbench: make tb FILE=CPU
tb:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make tb FILE=<module_name>"; \
		echo "Example: make tb FILE=CPU"; \
		exit 1; \
	else \
		mkdir -p build; \
		echo "$(CYAN)  SIM    $(NO_COLOR)tb/$(FILE)_tb.v"; \
		$(IVERILOG) -g2012 -I rtl/core -I rtl/memory -I rtl/io -I rtl/top \
		            -o build/sim_$(FILE).out tb/$(FILE)_tb.v $(SOURCES); \
		if [ $$? -eq 0 ]; then \
			$(VVP) build/sim_$(FILE).out; \
			if [ -f test.vcd ]; then \
				mv test.vcd build/$(FILE).vcd; \
				echo "$(GREEN)  VCD    $(NO_COLOR)build/$(FILE).vcd"; \
			fi; \
		else \
			echo "$(YELLOW)Compilation failed$(NO_COLOR)"; \
			exit 1; \
		fi \
	fi

# Run simulation and open waveform viewer
sim: tb
	@if [ -f "build/$(FILE).vcd" ]; then \
		echo "$(CYAN)  GTK    $(NO_COLOR)Launching gtkwave..."; \
		gtkwave build/$(FILE).vcd & \
	else \
		echo "$(YELLOW)No waveform file found$(NO_COLOR)"; \
	fi

# Run verbose simulation: make sim-verbose FILE=CPU
sim-verbose:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make sim-verbose FILE=<module_name>"; \
		exit 1; \
	else \
		mkdir -p build; \
		echo "$(CYAN)  SIM    $(NO_COLOR)tb/$(FILE)_tb.v (VERBOSE)"; \
		$(IVERILOG) -g2012 -DVERBOSE -I rtl/core -I rtl/memory -I rtl/io -I rtl/top \
		            -o build/sim_$(FILE).out tb/$(FILE)_tb.v $(SOURCES); \
		if [ $$? -eq 0 ]; then \
			$(VVP) build/sim_$(FILE).out; \
			if [ -f test.vcd ]; then \
				mv test.vcd build/$(FILE).vcd; \
				echo "$(CYAN)  GTK    $(NO_COLOR)Launching gtkwave..."; \
				gtkwave build/$(FILE).vcd & \
			fi; \
		fi \
	fi

# === Analysis & Reports ===

# Show resource utilization
stats: build/$(TOP).json
	@echo "$(CYAN)Resource Utilization:$(NO_COLOR)"
	@$(YOSYS) -p "read_json $<; stat"

# Show timing report
timing: build/$(TOP).asc
	@echo "$(CYAN)Timing Report:$(NO_COLOR)"
	@icetime -d $(DEVICE) -mtr build/timing.rpt $<
	@cat build/timing.rpt

# Generate synthesis report
report: build/$(TOP).json
	@echo "$(CYAN)Generating detailed report...$(NO_COLOR)"
	@mkdir -p build/reports
	@$(YOSYS) -p "read_json $<; stat -tech ice40 > build/reports/stats.txt"
	@$(YOSYS) -p "read_json $<; show -format dot -prefix build/reports/$(TOP)" 2>/dev/null || true
	@echo "$(GREEN)Reports generated in build/reports/$(NO_COLOR)"

# === Utilities ===

# Check for required tools
check:
	@echo "$(CYAN)Checking toolchain...$(NO_COLOR)"
	@command -v $(YOSYS) >/dev/null 2>&1 || { echo "$(YELLOW)yosys not found$(NO_COLOR)"; exit 1; }
	@command -v $(NEXTPNR) >/dev/null 2>&1 || { echo "$(YELLOW)nextpnr-ice40 not found$(NO_COLOR)"; exit 1; }
	@command -v $(ICEPACK) >/dev/null 2>&1 || { echo "$(YELLOW)icepack not found$(NO_COLOR)"; exit 1; }
	@command -v $(ICEPROG) >/dev/null 2>&1 || { echo "$(YELLOW)iceprog not found$(NO_COLOR)"; exit 1; }
	@command -v $(IVERILOG) >/dev/null 2>&1 || { echo "$(YELLOW)iverilog not found$(NO_COLOR)"; exit 1; }
	@command -v $(PYTHON) >/dev/null 2>&1 || { echo "$(YELLOW)python3 not found$(NO_COLOR)"; exit 1; }
	@echo "$(GREEN)All tools found$(NO_COLOR)"

# List available testbenches
list-tb:
	@echo "$(CYAN)Available testbenches:$(NO_COLOR)"
	@for tb in $(TB_SOURCES); do \
		basename $$tb .v | sed 's/_tb$$//' | sed 's/^/  - /'; \
	done

# List source files
list-src:
	@echo "$(CYAN)Source files:$(NO_COLOR)"
	@echo "$(SOURCES)" | tr ' ' '\n' | sed 's/^/  - /'

# Show dependencies
deps:
	@echo "$(CYAN)Build dependencies:$(NO_COLOR)"
	@echo "  Synthesis:  $(SOURCES)"
	@echo "  Constraints: $(PCF)"
	@echo "  Program:    $(PROG)"

# Quick rebuild (clean + build)
rebuild: clean all

# Clean build artifacts
clean:
	@echo "$(YELLOW)Cleaning build artifacts...$(NO_COLOR)"
	@rm -rf build/ *.vcd test.vcd
	@echo "$(GREEN)Clean complete$(NO_COLOR)"

# Deep clean (including tools cache)
distclean: clean
	@echo "$(YELLOW)Deep cleaning...$(NO_COLOR)"
	@rm -rf .nextpnr_*

# === Help ===

help:
	@echo "$(CYAN)Hack Computer Build System$(NO_COLOR)"
	@echo ""
	@echo "$(GREEN)Build Targets:$(NO_COLOR)"
	@echo "  make              - Build FPGA bitstream"
	@echo "  make flash        - Program FPGA with bitstream"
	@echo "  make upload       - Upload .hack program via UART (PROG=file.hack)"
	@echo "  make prog         - Flash bitstream + upload program"
	@echo ""
	@echo "$(GREEN)Simulation Targets:$(NO_COLOR)"
	@echo "  make tb FILE=CPU          - Run testbench"
	@echo "  make sim FILE=CPU         - Run testbench + open waveform"
	@echo "  make sim-verbose FILE=CPU - Run with verbose output"
	@echo ""
	@echo "$(GREEN)Analysis Targets:$(NO_COLOR)"
	@echo "  make stats        - Show resource utilization"
	@echo "  make timing       - Show timing report"
	@echo "  make report       - Generate detailed synthesis report"
	@echo ""
	@echo "$(GREEN)Utility Targets:$(NO_COLOR)"
	@echo "  make check        - Verify toolchain installation"
	@echo "  make list-tb      - List available testbenches"
	@echo "  make list-src     - List source files"
	@echo "  make deps         - Show build dependencies"
	@echo "  make clean        - Remove build artifacts"
	@echo "  make help         - Show this help"
	@echo ""
	@echo "$(GREEN)Variables:$(NO_COLOR)"
	@echo "  PROG=<file>       - Program file to upload (default: $(PROG))"
	@echo "  UART_PORT=<port>  - Serial port (default: $(UART_PORT))"
	@echo "  BAUD_RATE=<rate>  - Baud rate (default: $(BAUD_RATE))"
	@echo "  FILE=<module>     - Module name for simulation"
	@echo ""
	@echo "$(GREEN)Examples:$(NO_COLOR)"
	@echo "  make prog PROG=programs/fibonacci.hack"
	@echo "  make upload UART_PORT=/dev/ttyUSB0"
	@echo "  make sim FILE=ALU"
	@echo "  make sim-verbose FILE=CPU"
