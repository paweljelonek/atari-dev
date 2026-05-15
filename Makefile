# =============================================================================
# Makefile for Atari 8-bit - MADS Assembler + cc65 C Compiler
# Usage:
#   make PROJECT=name          - build project from ATARI_PROJECTS dir
#   make DIR=path              - build project in given directory
#   make run PROJECT=name      - build and launch in Atari800
#   make run DIR=path          - build directory and launch in Atari800
#   make debug PROJECT=name    - build and launch with Atari800 monitor
#   make debug DIR=path        - build and launch with Atari800 monitor
#   make clean PROJECT=name    - remove build artifacts
#   make clean DIR=path        - remove build artifacts from directory
#   make list                  - show available projects and examples
#
# Source detection (auto):
#   main.c   → compiled with cc65 (cl65 -t atarixl)
#   main.asm → assembled with MADS
# =============================================================================

MADS     = mads
CC65     = cl65
ATARI800 = atari800

-include .env

# cc65 needs CC65_HOME to find platform headers and libraries.
# Defaults to the path used by 'make install PREFIX=~/.local' from source.
CC65_HOME ?= $(HOME)/.local/share/cc65
export CC65_HOME

ifdef DIR
  PROJ_DIR = $(DIR)
else ifdef PROJECT
  PROJ_DIR = $(ATARI_PROJECTS)/$(PROJECT)
endif

XEX = $(PROJ_DIR)/main.xex
SYM = $(PROJ_DIR)/main.sym

.PHONY: all run debug clean list help _require_dir
.DEFAULT_GOAL := help

help:
	@echo "Atari 8-bit dev environment - MADS / cc65 + Atari800"
	@echo ""
	@echo "Usage:"
	@echo "  make PROJECT=name        - build project from ATARI_PROJECTS dir"
	@echo "  make DIR=path            - build project in given directory"
	@echo "  make run PROJECT=name    - build and launch in Atari800"
	@echo "  make run DIR=path        - build and launch in Atari800"
	@echo "  make debug PROJECT=name  - build and launch with Atari800 monitor"
	@echo "  make debug DIR=path      - build and launch with Atari800 monitor"
	@echo "  make clean PROJECT=name  - remove build artifacts"
	@echo "  make clean DIR=path      - remove build artifacts from directory"
	@echo "  make list                - show available projects and examples"
	@echo ""
	@echo "Source detection (auto): main.c → cc65, main.asm → MADS"

_require_dir:
	@test -n "$(PROJ_DIR)" || (echo "ERROR: Specify PROJECT=name or DIR=path" && exit 1)

all: _require_dir
	@if [ -f "$(PROJ_DIR)/main.c" ]; then \
		echo ">>> Compiling C: $(PROJ_DIR)/main.c"; \
		$(CC65) -t atarixl -O -o $(XEX) $(PROJ_DIR)/main.c; \
	elif [ -f "$(PROJ_DIR)/main.asm" ]; then \
		echo ">>> Assembling: $(PROJ_DIR)/main.asm"; \
		$(MADS) $(PROJ_DIR)/main.asm -o:$(XEX) -t:$(SYM); \
	else \
		echo "ERROR: No source found in $(PROJ_DIR) (expected main.c or main.asm)" && exit 1; \
	fi
	@echo ">>> Built: $(XEX) ($$(wc -c < $(XEX)) bytes)"

run: _require_dir all
	$(ATARI800) -xl -run $(XEX) &

debug: _require_dir all
	$(ATARI800) -xl -monitor -run $(XEX) &

clean: _require_dir
	rm -f $(PROJ_DIR)/*.xex $(PROJ_DIR)/*.sym $(PROJ_DIR)/*.lst \
	      $(PROJ_DIR)/*.o $(PROJ_DIR)/*.s

list:
	@echo "=== Projects ($(ATARI_PROJECTS)) ==="
	@ls -1d $(ATARI_PROJECTS)/*/ 2>/dev/null | xargs -I{} basename {} || echo "  (directory not found)"
	@echo ""
	@echo "=== Examples (./examples/) ==="
	@for d in examples/*/; do \
		name=$$(basename "$$d"); \
		src=""; \
		[ -f "$$d/main.asm" ] && src="asm"; \
		[ -f "$$d/main.c"   ] && src="c";   \
		echo "  $$name  [$$src]  →  make run DIR=$$d"; \
	done
