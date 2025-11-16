# vhdl files

PKG_FILES = src/types.vhd
SRC_FILES = src/accumulator.vhd \
			src/neuron.vhd
FILES = $(PKG_FILES) $(SRC_FILES)

# testbench
TESTBENCHFILE = ${TESTBENCH}_tb
TESTBENCHPATH = src/${TESTBENCHFILE}.vhd
WORKDIR = work

#GHDL CONFIG
GHDL_CMD = ghdl
GHDL_FLAGS  = --std=08 --workdir=$(WORKDIR)

STOP_TIME = 150ns
# Simulation break condition
#GHDL_SIM_OPT = --assert-level=error
GHDL_SIM_OPT = --stop-time=$(STOP_TIME)

# WAVEFORM_VIEWER = flatpak run io.github.gtkwave.GTKWave
WAVEFORM_VIEWER = gtkwave

.PHONY: clean

all: clean make run view

make:
ifeq ($(strip $(TESTBENCH)),)
	@echo "TESTBENCH not set. Use TESTBENCH=<value> to set it."
	@exit 1
endif

	@mkdir -p $(WORKDIR)
	@$(GHDL_CMD) -a $(GHDL_FLAGS) $(FILES)
	@$(GHDL_CMD) -a $(GHDL_FLAGS) $(TESTBENCHPATH)
	@$(GHDL_CMD) -e $(GHDL_FLAGS) $(TESTBENCHFILE)

run:
	@$(GHDL_CMD) -r $(GHDL_FLAGS) --workdir=$(WORKDIR) $(TESTBENCHFILE) --wave=$(TESTBENCHFILE).ghw $(GHDL_SIM_OPT)
	@mv $(TESTBENCHFILE).ghw $(WORKDIR)/

view:
	@$(WAVEFORM_VIEWER) --dump=$(WORKDIR)/$(TESTBENCHFILE).ghw

clean:
	@rm -rf $(WORKDIR)
