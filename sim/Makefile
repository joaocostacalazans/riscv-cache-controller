# Compiler and Simulator setup

SIM_TOOL = verilator
FLAGS = --binary --trace --top-module cache_controller_tb
GTKWAVE = gtkwave

IVERILOG = iverilog
VVP = vvp
IV_FLAGS = -g2012

SRC_DIR = ../src
TB_DIR  = ../tb

# Arquivos de input
SRC_FILES = $(SRC_DIR)/cache_tag.sv \
            $(SRC_DIR)/cache_data.sv \
            $(SRC_DIR)/cache_controller.sv \
			$(SRC_DIR)/cache_top.sv 

TB_FILES  = $(TB_DIR)/cache_controller_tb.sv \
            $(TB_DIR)/mem_main_model.sv

ALL_FILES = $(TB_FILES) $(SRC_FILES)

# Output files
SIM_NAME = sim.out
SIM_FILE = obj_dir/$(SIM_NAME)
VCD_OUT = dump.vcd

.PHONY: all compile run view clean

all: run

compile: $(SIM_FILE)

$(SIM_FILE): $(ALL_FILES)
	$(SIM_TOOL) $(FLAGS) -o $(SIM_NAME) $(ALL_FILES)

run: compile
	./$(SIM_FILE)

view: $(VCD_OUT)
	$(GTKWAVE) $(VCD_OUT) &

clean:
	rm -rf obj_dir $(VCD_OUT) work transcript vsim.wlf

# --- New Targets ---
test_tag:
	$(IVERILOG) $(IV_FLAGS) -o tag_test.out $(SRC_DIR)/cache_tag.sv $(TB_DIR)/cache_tag_tb.sv
	$(VVP) tag_test.out

test_data:
	$(IVERILOG) $(IV_FLAGS) -o data_test.out $(SRC_DIR)/cache_data.sv $(TB_DIR)/cache_data_tb.sv
	$(VVP) data_test.out

test_all: test_tag test_data run