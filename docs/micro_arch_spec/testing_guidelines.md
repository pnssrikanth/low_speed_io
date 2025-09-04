# Testing Guidelines

## Overview
This document outlines the verification strategy for the I2C IP core, including simulation, formal verification, and hardware testing methodologies. The goal is to achieve comprehensive coverage and ensure production readiness.

## Verification Strategy

### Verification Plan Objectives
- **Functional Coverage**: > 95% code coverage
- **Bug Detection**: Identify all design flaws before tape-out
- **Regression Testing**: Ensure no regressions in future updates
- **Performance Validation**: Verify timing and power specifications
- **Safety Verification**: Confirm fault tolerance mechanisms

### Verification Methodology
- **Simulation-Based**: RTL simulation with testbenches
- **Formal Verification**: Property checking and equivalence checking
- **Emulation**: Hardware-assisted verification for complex scenarios
- **FPGA Prototyping**: Real-world validation

## Testbench Architecture

### Top-Level Testbench Structure
```verilog
module i2c_tb;

    // DUT instantiation
    i2c_master dut (
        .clk(tb_clk),
        .rst_n(tb_rst_n),
        .scl(tb_scl),
        .sda(tb_sda),
        // ... other signals
    );

    // Clock generation
    initial begin
        tb_clk = 1'b0;
        forever #5 tb_clk = ~tb_clk; // 100 MHz
    end

    // Reset generation
    initial begin
        tb_rst_n = 1'b0;
        #100 tb_rst_n = 1'b1;
    end

    // Test stimulus
    initial begin
        // Test scenarios here
    end

    // Monitors and checkers
    i2c_monitor monitor (.scl(tb_scl), .sda(tb_sda));
    i2c_checker checker (.tx_data(dut.data_in), .rx_data(dut.data_out));

endmodule
```

### I2C Bus Model
```verilog
module i2c_bus_model (
    inout wire scl,
    inout wire sda
);

    reg scl_drive, sda_drive;
    reg scl_oe, sda_oe;

    // Bus pull-up resistors
    assign scl = scl_oe ? scl_drive : 1'bz;
    assign sda = sda_oe ? sda_drive : 1'bz;

    // Bus capacitance model
    wire bus_capacitance;
    assign bus_capacitance = scl & sda; // Simplified model

    // Arbitration logic
    always @(*) begin
        if (scl === 1'b0 && sda === 1'b0) begin
            // Bus contention detected
        end
    end

endmodule
```

## Test Scenarios

### 1. Basic Functionality Tests
- **START/STOP Generation**: Verify correct timing and levels
- **Address Transmission**: Test 7-bit and 10-bit addressing
- **Data Transfer**: Single byte and multi-byte transfers
- **ACK/NACK Handling**: Proper acknowledgment responses

### 2. Protocol Compliance Tests
```verilog
task test_i2c_protocol;
    begin
        // Test START condition
        start_condition();
        assert(sda_fell_while_scl_high) $display("START condition OK");
        else $error("START condition failed");

        // Test address transmission
        send_address(7'h55, 1'b0); // Write operation
        assert(ack_received) $display("Address ACK OK");
        else $error("Address NACK");

        // Test data transmission
        send_data(8'hA5);
        assert(ack_received) $display("Data ACK OK");

        // Test STOP condition
        stop_condition();
        assert(sda_rose_while_scl_high) $display("STOP condition OK");
    end
endtask
```

### 3. Error Condition Tests
- **Bus Contention**: Multiple masters transmitting simultaneously
- **Clock Stretching**: Slave holding SCL low
- **Arbitration Loss**: Master losing arbitration
- **Bus Timeout**: No activity on bus for extended period
- **Invalid Conditions**: SDA changing while SCL low

### 4. Speed Mode Tests
- **Standard Mode**: 100 kHz operation
- **Fast Mode**: 400 kHz operation
- **Fast Mode Plus**: 1 MHz operation
- **High Speed Mode**: 3.4 MHz operation (if supported)

### 5. Multi-Master Tests
```verilog
task test_multi_master;
    begin
        // Start two masters simultaneously
        fork
            master1_transmit();
            master2_transmit();
        join

        // Check arbitration winner
        if (master1_won) begin
            $display("Master 1 won arbitration");
        end else begin
            $display("Master 2 won arbitration");
        end

        // Verify loser backed off
        assert(loser_stopped_transmitting) $display("Arbitration OK");
    end
endtask
```

## Coverage Metrics

### Code Coverage Goals
- **Line Coverage**: > 95%
- **Branch Coverage**: > 90%
- **Condition Coverage**: > 85%
- **Toggle Coverage**: > 90%
- **FSM State Coverage**: 100%

### Functional Coverage Points
```systemverilog
covergroup i2c_functional_cg @(posedge clk);
    cp_speed_mode: coverpoint speed_mode {
        bins standard = {2'b00};
        bins fast = {2'b01};
        bins fast_plus = {2'b10};
        bins high_speed = {2'b11};
    }

    cp_operation: coverpoint operation {
        bins write = {1'b0};
        bins read = {1'b1};
    }

    cp_addressing: coverpoint addr_mode {
        bins bit7 = {1'b0};
        bins bit10 = {1'b1};
    }

    cp_error_conditions: coverpoint error_type {
        bins arbitration_loss = {ERROR_ARB_LOST};
        bins nack = {ERROR_NACK};
        bins bus_error = {ERROR_BUS};
        bins timeout = {ERROR_TIMEOUT};
    }

    cross_speed_operation: cross cp_speed_mode, cp_operation;
    cross_speed_addressing: cross cp_speed_mode, cp_addressing;
endgroup
```

## Formal Verification

### Property Specification
```systemverilog
module i2c_properties (
    input wire clk, rst_n,
    input wire start_tx, busy, tx_done,
    input wire scl, sda
);

    // START condition property
    property start_condition_p;
        @(posedge clk) disable iff (!rst_n)
        $fell(sda) && scl;
    endproperty

    // Transaction completion property
    property transaction_complete_p;
        @(posedge clk) disable iff (!rst_n)
        start_tx |=> ##[1:$] tx_done;
    endproperty

    // Bus free time property
    property bus_free_time_p;
        @(posedge clk) disable iff (!rst_n)
        $rose(scl) && sda |=> ##[47:$] (!scl && !sda); // 4.7us at 100MHz
    endproperty

    // Assertions
    assert property (start_condition_p) else $error("START condition violation");
    assert property (transaction_complete_p) else $error("Transaction timeout");
    assert property (bus_free_time_p) else $error("Bus free time violation");

endmodule
```

### Formal Verification Commands
```tcl
# Read design
read_verilog i2c_master.v
read_verilog i2c_properties.sv

# Elaborate design
elaborate i2c_master

# Prove properties
prove -all

# Check coverage
report_coverage -detail
```

## Hardware Testing

### FPGA Validation
```verilog
module fpga_test_wrapper (
    // FPGA pins
    input wire fpga_clk,
    input wire [3:0] sw,      // Switches for test selection
    input wire [1:0] btn,     // Buttons for control
    output wire [3:0] led,    // Status LEDs
    inout wire scl,           // I2C SCL
    inout wire sda            // I2C SDA
);

    // I2C IP instantiation
    i2c_master dut (
        .clk(fpga_clk),
        .rst_n(!btn[0]),
        // ... connections
    );

    // Test controller
    always @(posedge fpga_clk) begin
        case (sw)
            4'b0001: test_basic_transfer();
            4'b0010: test_multi_byte();
            4'b0100: test_error_conditions();
            4'b1000: test_speed_modes();
        endcase
    end

    // LED status
    assign led[0] = dut.tx_done;
    assign led[1] = dut.rx_done;
    assign led[2] = dut.busy;
    assign led[3] = dut.bus_error;

endmodule
```

### Silicon Validation
- **ATE Testing**: Automated test equipment for production testing
- **Boundary Scan**: JTAG-based testing for interconnect verification
- **Built-in Self-Test**: On-chip test patterns for manufacturing defects
- **Characterization**: Timing and power measurement across PVT corners

## Regression Testing

### Test Suite Organization
```
test_suite/
├── basic_tests/
│   ├── test_start_stop.v
│   ├── test_single_byte.v
│   └── test_multi_byte.v
├── protocol_tests/
│   ├── test_7bit_addressing.v
│   ├── test_10bit_addressing.v
│   └── test_clock_stretching.v
├── error_tests/
│   ├── test_arbitration.v
│   ├── test_bus_contention.v
│   └── test_timeout.v
├── speed_tests/
│   ├── test_standard_mode.v
│   ├── test_fast_mode.v
│   └── test_fast_plus_mode.v
└── regression.py  # Automated regression script
```

### Automated Regression Script
```python
import os
import subprocess

def run_regression():
    test_files = [
        "basic_tests/test_start_stop.v",
        "basic_tests/test_single_byte.v",
        "protocol_tests/test_7bit_addressing.v",
        # ... more tests
    ]

    results = {}
    for test_file in test_files:
        print(f"Running {test_file}")
        result = subprocess.run([
            "vsim", "-c", "-do", f"run -all; quit",
            "-lib", "work", test_file
        ], capture_output=True, text=True)

        if result.returncode == 0:
            results[test_file] = "PASS"
        else:
            results[test_file] = "FAIL"
            print(f"Failed: {result.stderr}")

    # Generate report
    passed = sum(1 for r in results.values() if r == "PASS")
    total = len(results)
    print(f"Regression Results: {passed}/{total} tests passed")

    return results
```

## Performance Benchmarking

### Throughput Testing
```verilog
task measure_throughput;
    integer start_time, end_time;
    integer bytes_transferred;

    begin
        start_time = $time;
        bytes_transferred = 0;

        repeat (1000) begin
            transmit_byte(8'h55);
            bytes_transferred = bytes_transferred + 1;
        end

        end_time = $time;

        $display("Transferred %0d bytes in %0d ns", bytes_transferred, end_time - start_time);
        $display("Throughput: %0.2f MB/s", (bytes_transferred * 1e9) / (end_time - start_time) / 1e6);
    end
endtask
```

### Power Consumption Analysis
- **Dynamic Power**: Measured during active data transfer
- **Static Power**: Measured in idle state
- **Power Gating**: Effectiveness of power management features

---

[Back to Index](index.md) | [Previous: Safety Mechanisms](safety_mechanisms.md) | [Next: Integration Guide](integration_guide.md)