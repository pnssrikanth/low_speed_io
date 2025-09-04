#!/bin/bash

# I2C Testbench Compilation Script
# This script compiles the I2C testbench for Icarus Verilog

echo "================================================================="
echo "            I2C Testbench Compilation Script"
echo "================================================================="

# Set project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Project Root: $PROJECT_ROOT"

# Create output directory
OUTPUT_DIR="$PROJECT_ROOT/sim"
mkdir -p "$OUTPUT_DIR"

# Compilation flags
IVERILOG_FLAGS="-g2012 -Wall -Winfloop"

# Source files
RTL_FILES=(
    "$PROJECT_ROOT/src/rtl/i2c_core.sv"
)

TB_FILES=(
    "$PROJECT_ROOT/src/tb/interfaces/apb_if.sv"
    "$PROJECT_ROOT/src/tb/interfaces/i2c_if.sv"
    "$PROJECT_ROOT/src/tb/components/apb_bfm.sv"
    "$PROJECT_ROOT/src/tb/components/i2c_monitor.sv"
    "$PROJECT_ROOT/src/tb/components/scoreboard.sv"
    "$PROJECT_ROOT/src/tb/components/coverage.sv"
    "$PROJECT_ROOT/src/tb/tests/base_test.sv"
    "$PROJECT_ROOT/src/tb/tests/test_reset.sv"
    "$PROJECT_ROOT/src/tb/i2c_tb_top.sv"
)

echo "Compiling RTL files..."
for file in "${RTL_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  Found: $(basename "$file")"
    else
        echo "  ERROR: Missing file: $(basename "$file")"
        exit 1
    fi
done

echo "Compiling testbench files..."
for file in "${TB_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  Found: $(basename "$file")"
    else
        echo "  ERROR: Missing file: $(basename "$file")"
        exit 1
    fi
done

# Compile all files
echo "Running Icarus Verilog compilation..."
iverilog $IVERILOG_FLAGS -o "$OUTPUT_DIR/i2c_tb_top" "${RTL_FILES[@]}" "${TB_FILES[@]}"

if [ $? -eq 0 ]; then
    echo "✓ Compilation successful!"
    echo "  Output file: $OUTPUT_DIR/i2c_tb_top"
    echo ""
    echo "To run the testbench:"
    echo "  cd $OUTPUT_DIR"
    echo "  vvp i2c_tb_top +TEST_NAME=test_reset"
    echo ""
    echo "To view waveforms:"
    echo "  gtkwave i2c_tb_top.vcd"
else
    echo "✗ Compilation failed!"
    exit 1
fi

echo "================================================================="
echo "            Compilation Complete"
echo "================================================================="