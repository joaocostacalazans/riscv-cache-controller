# Compiler and Simulator setup
# Default tool: Icarus Verilog (iverilog) / vvp
# Can be changed to Questasim (vlog/vsim) or Verilator as needed.

SIM_TOOL = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Source files
SRC_DIR = ../src
TB_DIR  = ../tb

SRC_FILES = $(SRC_DIR)/cache_tag.sv \
            $(SRC_DIR)/cache_data.sv \
            $(SRC_DIR)/cache_controller.sv

TB_FILES  = $(TB_DIR)/mem_main_model.sv \
            $(TB_DIR)/cache_controller_tb.sv

ALL_FILES = $(SRC_FILES) $(TB_FILES)

# Output files
SIM_OUT = sim.out
VCD_OUT = dump.vcd

.PHONY: all compile run view clean

all: run

compile: $(SIM_OUT)

$(SIM_OUT): $(ALL_FILES)
	$(SIM_TOOL) -g2012 -o $(SIM_OUT) $(ALL_FILES)

run: compile
	$(VVP) $(SIM_OUT)

view: $(VCD_OUT)
	$(GTKWAVE) $(VCD_OUT) &

clean:
	rm -rf $(SIM_OUT) $(VCD_OUT) work transcript vsim.wlf
