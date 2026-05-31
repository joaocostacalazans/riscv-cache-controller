# Compiler and Simulator setup

SIM_TOOL = verilator
FLAGS = --binary --trace

SRC_DIR = ../src
TB_DIR  = ../tb

# Arquivos compartilhados por todos test benches
SRC_FILES = $(SRC_DIR)/cache_tag.sv \
            $(SRC_DIR)/cache_data.sv \
            $(SRC_DIR)/cache_controller.sv \
            $(SRC_DIR)/cache_top.sv \
            $(TB_DIR)/mem_main_model.sv

OBJ_DIR = obj_dir

# Para cada "tb/modulo_tb.sv" crie um "test_modulo" aqui
TESTS = test_cache_controller test_cache_data

all: run

# Rode "make run -j1" para não rodar os tests em paralelo
run: $(TESTS)

# É bom compilar tudo antes de rodar todos os testes para não poluir o output
compile: $(TESTS:test_%=$(OBJ_DIR)/V%_tb)

# Regra para os executaveis
$(OBJ_DIR)/V%: $(TB_DIR)/%.sv $(SRC_FILES)
	$(SIM_TOOL) $(FLAGS) --top-module $* $^

# Regra para rodar os testes
test_%: $(OBJ_DIR)/V%_tb FORCE
	./$<

clean:
	rm -rf $(OBJ_DIR) *.vcd work transcript vsim.wlf

# Adicionar $(TESTS) no .PHONY não ta funcionando, o FORCE é uma solução
FORCE:

.PHONY: all compile run clean FORCE
