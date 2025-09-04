#!/bin/bash

# Compile script for I2C IP Core

set -e  # Exit on any error

echo "Starting compilation of I2C IP Core..."

# Check if iverilog is installed
if ! command -v iverilog &> /dev/null; then
    echo "Error: iverilog is not installed. Please install Icarus Verilog."
    exit 1
fi

# Check if source directory exists
if [ ! -d "../src/rtl" ]; then
    echo "Error: Source directory ../src/rtl does not exist."
    exit 1
fi

# Check if there are Verilog files
if ! ls ../src/rtl/*.v 1> /dev/null 2>&1; then
    echo "Error: No Verilog (.v) files found in ../src/rtl/"
    exit 1
fi

# Run make
if ! make; then
    echo "Error: Make failed. Check ../logs/compile.log for details."
    exit 1
fi

# Check if target file was generated
if [ ! -f "../build/i2c_top" ]; then
    echo "Error: Compilation failed - target file ../build/i2c_top not found."
    exit 1
fi

# Check log for errors
if grep -qi "error" ../logs/compile.log; then
    echo "Warning: Errors found in compilation log. Check ../logs/compile.log"
fi

echo "Compilation finished successfully."
echo "Executable: ../build/i2c_top"
echo "Logs: ../logs/compile.log"