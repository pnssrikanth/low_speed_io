# Makefile for I2C IP Core Compilation

# Directories
SRC_DIR = ../src/rtl
BUILD_DIR = ../build
LOG_DIR = ../logs

# Source files
SOURCES = $(wildcard $(SRC_DIR)/*.v)

# Target
TARGET = $(BUILD_DIR)/i2c_top

# Compiler
IVERILOG = iverilog
IVERILOG_FLAGS = -Wall

# Check if sources exist
ifeq ($(SOURCES),)
$(error No Verilog source files found in $(SRC_DIR))
endif

# Default target
all: check_tools $(TARGET)

# Check if iverilog is available
check_tools:
	@command -v $(IVERILOG) >/dev/null 2>&1 || { echo "Error: $(IVERILOG) is not installed."; exit 1; }

# Create build and log directories
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(LOG_DIR):
	@mkdir -p $(LOG_DIR)

# Compilation rule
$(TARGET): $(SOURCES) | $(BUILD_DIR) $(LOG_DIR)
	@echo "Compiling Verilog files..."
	$(IVERILOG) $(IVERILOG_FLAGS) -o $@ $^ > $(LOG_DIR)/compile.log 2>&1 || { echo "Compilation failed. Check $(LOG_DIR)/compile.log"; exit 1; }
	@echo "Compilation completed successfully."
	@echo "Target: $@"
	@echo "Log: $(LOG_DIR)/compile.log"

# Clean target
clean:
	@rm -rf $(BUILD_DIR) $(LOG_DIR)
	@echo "Cleaned build and log directories."

# Phony targets
.PHONY: all clean check_tools