#!/bin/bash

# I2C Testbench Run Script
# This script runs I2C testbench tests with Icarus Verilog

echo "================================================================="
echo "              I2C Testbench Run Script"
echo "================================================================="

# Set project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIM_DIR="$PROJECT_ROOT/sim"

# Default test name
TEST_NAME="test_reset"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --test=*)
            TEST_NAME="${1#*=}"
            shift
            ;;
        --compile)
            COMPILE_ONLY=1
            shift
            ;;
        --waveform)
            GENERATE_WAVEFORM=1
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --test=TEST_NAME    Run specific test (default: test_reset)"
            echo "  --compile          Only compile, don't run"
            echo "  --waveform         Generate waveform file"
            echo "  --help             Show this help"
            echo ""
            echo "Available tests:"
            echo "  test_reset         - Reset functionality test"
            echo "  (Add more tests as they are implemented)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "Test to run: $TEST_NAME"
echo "Simulation directory: $SIM_DIR"

# Check if compiled testbench exists
if [ ! -f "$SIM_DIR/i2c_tb_top" ]; then
    echo "Compiled testbench not found. Running compilation..."
    if ! "$PROJECT_ROOT/scripts/compile_tb.sh"; then
        echo "✗ Compilation failed!"
        exit 1
    fi
fi

# Run compilation if requested
if [ "$COMPILE_ONLY" = "1" ]; then
    echo "Compilation completed. Exiting (--compile flag used)."
    exit 0
fi

# Change to simulation directory
cd "$SIM_DIR" || exit 1

# Set up waveform generation
if [ "$GENERATE_WAVEFORM" = "1" ]; then
    VVP_FLAGS=""
else
    VVP_FLAGS="-none"
fi

# Run the test
echo "Starting test execution..."
echo "Command: vvp i2c_tb_top +TEST_NAME=$TEST_NAME $VVP_FLAGS"

vvp i2c_tb_top +TEST_NAME="$TEST_NAME" $VVP_FLAGS

# Check test result
if [ $? -eq 0 ]; then
    echo "✓ Test completed successfully"
else
    echo "✗ Test failed or encountered errors"
fi

# Check for waveform file
if [ "$GENERATE_WAVEFORM" = "1" ] && [ -f "i2c_tb_top.vcd" ]; then
    echo "Waveform file generated: i2c_tb_top.vcd"
    echo "To view waveforms: gtkwave i2c_tb_top.vcd"
fi

# Display test summary
echo ""
echo "================================================================="
echo "              Test Execution Summary"
echo "================================================================="
echo "Test Name: $TEST_NAME"
echo "Simulation Directory: $SIM_DIR"
echo "Waveform Generated: $([ "$GENERATE_WAVEFORM" = "1" ] && echo "Yes" || echo "No")"

if [ -f "i2c_tb_top.vcd" ]; then
    echo "Waveform File: i2c_tb_top.vcd"
fi

echo "================================================================="