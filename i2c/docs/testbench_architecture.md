# I2C IP Core Testbench Architecture

## Document Information
- **Version**: 1.0
- **Date**: September 4, 2025
- **Author**: OpenCode Assistant
- **Purpose**: Comprehensive testbench architecture for I2C IP core verification

## 1. Introduction

### 1.1 Purpose
This document provides a detailed architecture for implementing a SystemVerilog-based testbench for the I2C IP core. The testbench is designed to enable comprehensive verification of all features specified in the verification plan, ensuring the IP is production-ready.

### 1.2 Scope
The testbench architecture covers:
- Complete testbench component design
- Scoreboard implementation for result checking
- Coverage collection and analysis
- Test case development framework
- Integration with simulation tools
- Debug and analysis capabilities

### 1.3 Target Audience
- Novice verification engineers
- System architects
- IP designers
- Quality assurance teams

## 2. Testbench Architecture Overview

### 2.1 High-Level Architecture

```
+-------------------+     +-------------------+     +-------------------+
|     Test Case     | --> |   Testbench Top   | --> |     DUT (I2C)     |
+-------------------+     +-------------------+     +-------------------+
          |                       |                       |
          |                       |                       |
          v                       v                       v
+-------------------+     +-------------------+     +-------------------+
|   Test Library    |     |   Verification    |     |   I2C Protocol    |
|   (TC_001-TC_025) |     |   Components      |     |   Engine          |
+-------------------+     +-------------------+     +-------------------+
          ^                       ^                       ^
          |                       |                       |
          v                       v                       v
+-------------------+     +-------------------+     +-------------------+
|   Scoreboard &    | <-- |   Monitors &      | <-- |   Bus Interfaces  |
|   Coverage        |     |   Checkers        |     |   (APB/AHB/I2C)   |
+-------------------+     +-------------------+     +-------------------+
```

### 2.2 Testbench Components

#### 2.2.1 Testbench Top Module
The top-level testbench module that instantiates all components and coordinates the verification flow.

```verilog
module i2c_tb_top;

// Clock and reset generation
logic clk, rst_n;
logic i2c_scl, i2c_sda;

// DUT instantiation
i2c_core dut (
    .pclk(clk),
    .presetn(rst_n),
    .psel(psel),
    .penable(penable),
    .pwrite(pwrite),
    .paddr(paddr),
    .pwdata(pwdata),
    .prdata(prdata),
    .pready(pready),
    .pslverr(pslverr),
    .irq(irq),
    .dma_req(dma_req),
    .dma_ack(dma_ack),
    .scl(i2c_scl),
    .sda(i2c_sda)
);

// Verification components
apb_master_bfm apb_bfm (.*);
i2c_monitor i2c_mon (.*);
scoreboard sb (.*);
coverage_collector cov (.*);

// Test execution
initial begin
    // Test case execution
    run_test();
end

endmodule
```

## 3. Verification Components

### 3.1 APB Master BFM (Bus Functional Model)

#### 3.1.1 Purpose
The APB Master BFM handles all APB bus transactions for register access and configuration.

#### 3.1.2 Interface
```verilog
interface apb_if;
    logic        pclk;
    logic        presetn;
    logic        psel;
    logic        penable;
    logic        pwrite;
    logic [31:0] paddr;
    logic [31:0] pwdata;
    logic [31:0] prdata;
    logic        pready;
    logic        pslverr;
endinterface

class apb_master_bfm;
    virtual apb_if vif;

    // Constructor
    function new(virtual apb_if vif);
        this.vif = vif;
    endfunction

    // APB write task
    task write_reg(bit [31:0] addr, bit [31:0] data);
        @(posedge vif.pclk);
        vif.psel <= 1'b1;
        vif.penable <= 1'b0;
        vif.pwrite <= 1'b1;
        vif.paddr <= addr;
        vif.pwdata <= data;

        @(posedge vif.pclk);
        vif.penable <= 1'b1;

        wait(vif.pready);
        vif.psel <= 1'b0;
        vif.penable <= 1'b0;
    endtask

    // APB read task
    task read_reg(bit [31:0] addr, output bit [31:0] data);
        @(posedge vif.pclk);
        vif.psel <= 1'b1;
        vif.penable <= 1'b0;
        vif.pwrite <= 1'b0;
        vif.paddr <= addr;

        @(posedge vif.pclk);
        vif.penable <= 1'b1;

        wait(vif.pready);
        data = vif.prdata;
        vif.psel <= 1'b0;
        vif.penable <= 1'b0;
    endtask
endclass
```

#### 3.1.3 Usage Example
```verilog
// Configure I2C for master mode
apb_bfm.write_reg(CTRL_ADDR, 32'h0000_0001);  // Enable core
apb_bfm.write_reg(TIMING_ADDR, 32'h00FA_00FA); // Set timing
```

### 3.2 I2C Monitor

#### 3.2.1 Purpose
The I2C Monitor passively observes I2C bus activity and decodes protocol transactions.

#### 3.2.2 Implementation
```verilog
class i2c_monitor;
    virtual i2c_if vif;
    mailbox mon2sb;

    // I2C transaction structure
    typedef struct {
        bit [6:0] addr;
        bit rw;
        bit [7:0] data[];
        bit ack[];
        int num_bytes;
    } i2c_transaction;

    // Constructor
    function new(virtual i2c_if vif, mailbox mon2sb);
        this.vif = vif;
        this.mon2sb = mon2sb;
    endfunction

    // Monitor task
    task run();
        i2c_transaction txn;
        forever begin
            // Wait for START condition
            wait_for_start();

            // Capture address
            txn.addr = capture_address();
            txn.rw = vif.sda;  // Read/write bit

            // Capture data bytes
            capture_data(txn);

            // Send to scoreboard
            mon2sb.put(txn);
        end
    endtask

    // Helper tasks
    task wait_for_start();
        @(negedge vif.sda);
        if (vif.scl) begin
            $display("START condition detected");
        end
    endtask

    task automatic capture_address();
        bit [6:0] addr = 0;
        for (int i = 6; i >= 0; i--) begin
            @(posedge vif.scl);
            addr[i] = vif.sda;
        end
        return addr;
    endtask
endclass
```

### 3.3 Scoreboard

#### 3.3.1 Purpose
The Scoreboard compares expected vs. actual transactions and maintains verification statistics.

#### 3.3.2 Implementation
```verilog
class scoreboard;
    mailbox mon2sb, drv2sb;
    int total_txns, passed_txns, failed_txns;

    // Transaction queues
    i2c_transaction expected_queue[$];
    i2c_transaction actual_queue[$];

    // Constructor
    function new(mailbox mon2sb, mailbox drv2sb);
        this.mon2sb = mon2sb;
        this.drv2sb = drv2sb;
        total_txns = 0;
        passed_txns = 0;
        failed_txns = 0;
    endfunction

    // Main comparison task
    task run();
        i2c_transaction exp_txn, act_txn;

        forever begin
            // Get expected transaction from driver
            drv2sb.get(exp_txn);
            expected_queue.push_back(exp_txn);

            // Get actual transaction from monitor
            mon2sb.get(act_txn);
            actual_queue.push_back(act_txn);

            // Compare transactions
            compare_transactions(exp_txn, act_txn);
        end
    endtask

    // Transaction comparison
    task compare_transactions(i2c_transaction exp, i2c_transaction act);
        total_txns++;

        if (exp.addr == act.addr &&
            exp.rw == act.rw &&
            exp.data == act.data) begin
            passed_txns++;
            $display("PASS: Transaction matched");
        end else begin
            failed_txns++;
            $display("FAIL: Transaction mismatch");
            $display("  Expected: addr=%h, rw=%b, data=%p",
                    exp.addr, exp.rw, exp.data);
            $display("  Actual:   addr=%h, rw=%b, data=%p",
                    act.addr, act.rw, act.data);
        end

        // Update coverage
        update_coverage(exp, act);
    endtask

    // Coverage update
    task update_coverage(i2c_transaction exp, i2c_transaction act);
        // Address coverage
        addr_cov.sample(exp.addr);

        // Data coverage
        foreach (exp.data[i]) begin
            data_cov.sample(exp.data[i]);
        end

        // Transaction type coverage
        if (exp.rw) rw_cov.sample("READ");
        else rw_cov.sample("WRITE");
    endtask

    // Report generation
    function void report();
        $display("\n=== SCOREBOARD REPORT ===");
        $display("Total Transactions: %0d", total_txns);
        $display("Passed: %0d", passed_txns);
        $display("Failed: %0d", failed_txns);
        $display("Pass Rate: %0.2f%%", (passed_txns * 100.0) / total_txns);
    endfunction
endclass
```

### 3.4 Coverage Collector

#### 3.4.1 Purpose
The Coverage Collector measures functional and code coverage metrics.

#### 3.4.2 Implementation
```verilog
class coverage_collector;
    // Functional coverage groups
    covergroup i2c_protocol_cov;
        addr_cp: coverpoint addr {
            bins addr_range[16] = {[0:127]};
        }

        rw_cp: coverpoint rw {
            bins read = {1};
            bins write = {0};
        }

        data_cp: coverpoint data {
            bins zero = {0};
            bins all_ones = {255};
            bins others = default;
        }

        speed_cp: coverpoint speed_mode {
            bins standard = {0};
            bins fast = {1};
            bins fast_plus = {2};
            bins high_speed = {3};
        }

        addr_x_rw: cross addr_cp, rw_cp;
        data_x_speed: cross data_cp, speed_cp;
    endgroup

    // Code coverage
    covergroup fsm_cov;
        state_cp: coverpoint current_state {
            bins idle = {IDLE};
            bins start = {START};
            bins addr = {ADDR};
            bins tx_data = {TX_DATA};
            bins rx_data = {RX_DATA};
            bins ack = {ACK};
            bins stop = {STOP};
        }

        state_trans: coverpoint current_state {
            bins idle_to_start = (IDLE => START);
            bins start_to_addr = (START => ADDR);
            bins addr_to_tx = (ADDR => TX_DATA);
            bins addr_to_rx = (ADDR => RX_DATA);
            bins tx_to_ack = (TX_DATA => ACK);
            bins rx_to_ack = (RX_DATA => ACK);
            bins ack_to_tx = (ACK => TX_DATA);
            bins ack_to_rx = (ACK => RX_DATA);
            bins ack_to_stop = (ACK => STOP);
            bins stop_to_idle = (STOP => IDLE);
        }
    endgroup

    // Constructor
    function new();
        i2c_protocol_cov = new();
        fsm_cov = new();
    endfunction

    // Sampling task
    task sample_transaction(i2c_transaction txn, int speed_mode);
        i2c_protocol_cov.addr_cp = txn.addr;
        i2c_protocol_cov.rw_cp = txn.rw;
        foreach (txn.data[i]) begin
            i2c_protocol_cov.data_cp = txn.data[i];
        end
        i2c_protocol_cov.speed_cp = speed_mode;
        i2c_protocol_cov.sample();
    endtask

    // Report coverage
    function void report_coverage();
        $display("\n=== COVERAGE REPORT ===");
        $display("Protocol Coverage: %0.2f%%", i2c_protocol_cov.get_coverage());
        $display("FSM Coverage: %0.2f%%", fsm_cov.get_coverage());
        $display("Overall Coverage: %0.2f%%",
                (i2c_protocol_cov.get_coverage() + fsm_cov.get_coverage()) / 2);
    endfunction
endclass
```

## 4. Test Case Framework

### 4.1 Base Test Class

#### 4.1.1 Purpose
The base test class provides common functionality for all test cases.

#### 4.1.2 Implementation
```verilog
class base_test;
    string test_name;
    apb_master_bfm apb_bfm;
    scoreboard sb;
    coverage_collector cov;

    // Constructor
    function new(string name);
        test_name = name;
        apb_bfm = new(apb_vif);
        sb = new(mon2sb, drv2sb);
        cov = new();
    endfunction

    // Setup task
    virtual task setup();
        // Reset DUT
        reset_dut();

        // Configure basic settings
        configure_basic();

        // Start verification components
        fork
            sb.run();
            cov.run();
        join_none
    endtask

    // Teardown task
    virtual task teardown();
        // Generate reports
        sb.report();
        cov.report_coverage();

        // Clean up
        $finish;
    endtask

    // Reset DUT
    task reset_dut();
        rst_n = 0;
        #100;
        rst_n = 1;
        #100;
    endtask

    // Basic configuration
    task configure_basic();
        // Enable I2C core
        apb_bfm.write_reg(CTRL_ADDR, 32'h0000_0001);

        // Set standard timing
        apb_bfm.write_reg(TIMING_ADDR, 32'h00FA_00FA);
    endtask

    // Main test execution
    virtual task run();
        setup();
        // Test-specific code here
        teardown();
    endtask
endclass
```

### 4.2 Test Case Example (TC_001)

#### 4.2.1 Implementation
```verilog
class test_reset extends base_test;
    function new();
        super.new("TC_001_Reset_Functionality");
    endfunction

    task run();
        setup();

        // Test reset functionality
        $display("Testing reset functionality...");

        // Configure some registers
        apb_bfm.write_reg(TIMING_ADDR, 32'h1234_5678);
        apb_bfm.write_reg(ADDR_ADDR, 32'h0000_00AA);

        // Assert reset
        rst_n = 0;
        #100;

        // Check registers are cleared
        bit [31:0] timing_val, addr_val;
        apb_bfm.read_reg(TIMING_ADDR, timing_val);
        apb_bfm.read_reg(ADDR_ADDR, addr_val);

        if (timing_val == 0 && addr_val == 0) begin
            $display("PASS: Registers cleared on reset");
            sb.passed_txns++;
        end else begin
            $display("FAIL: Registers not cleared on reset");
            sb.failed_txns++;
        end

        // De-assert reset
        rst_n = 1;
        #100;

        teardown();
    endtask
endclass
```

## 5. Test Execution Framework

### 5.1 Test Runner

#### 5.1.1 Purpose
The test runner manages execution of all test cases.

#### 5.1.2 Implementation
```verilog
module test_runner;
    string test_name;
    base_test test;

    initial begin
        // Get test name from command line
        if ($value$plusargs("TEST_NAME=%s", test_name)) begin
            $display("Running test: %s", test_name);
        end else begin
            test_name = "test_reset";  // Default test
        end

        // Create and run test
        case (test_name)
            "test_reset": test = new test_reset();
            "test_basic_master_tx": test = new test_basic_master_tx();
            "test_basic_master_rx": test = new test_basic_master_rx();
            // Add more test cases here
            default: begin
                $display("Unknown test: %s", test_name);
                $finish;
            end
        endcase

        // Run the test
        test.run();
    end
endmodule
```

### 5.2 Command Line Execution

#### 5.2.1 Running Individual Tests
```bash
# Run specific test
iverilog -o testbench i2c_tb_top.v test_lib.v
vvp testbench +TEST_NAME=test_reset

# Run with waveform
vvp testbench +TEST_NAME=test_basic_master_tx
gtkwave testbench.vcd
```

#### 5.2.2 Running Regression Suite
```bash
#!/bin/bash
# regression.sh

TESTS=(
    "test_reset"
    "test_basic_master_tx"
    "test_basic_master_rx"
    "test_slave_mode"
    "test_10bit_addressing"
    "test_speed_modes"
    "test_multi_master"
    "test_clock_stretching"
    "test_interrupts"
    "test_dma"
    "test_error_conditions"
    "test_power_management"
    "test_safety_features"
    "test_security"
    "test_ahb_interface"
    "test_jtag_debug"
    "test_environmental"
)

for test in "${TESTS[@]}"; do
    echo "Running $test..."
    vvp testbench +TEST_NAME=$test
    if [ $? -ne 0 ]; then
        echo "Test $test FAILED"
        exit 1
    fi
done

echo "All tests passed!"
```

## 6. Coverage and Reporting

### 6.1 Coverage Metrics

#### 6.1.1 Functional Coverage
```verilog
// Coverage definitions
covergroup functional_cov;
    // I2C Protocol Coverage
    address_mode: coverpoint addr_mode {
        bins bit7 = {0};
        bins bit10 = {1};
    }

    speed_mode: coverpoint speed {
        bins standard = {100};
        bins fast = {400};
        bins fast_plus = {1000};
        bins high_speed = {3400};
    }

    transaction_type: coverpoint txn_type {
        bins write = {0};
        bins read = {1};
    }

    // Register Coverage
    register_access: coverpoint reg_addr {
        bins ctrl_reg = {CTRL_ADDR};
        bins status_reg = {STATUS_ADDR};
        bins timing_reg = {TIMING_ADDR};
        bins addr_reg = {ADDR_ADDR};
        bins data_reg = {TX_DATA_ADDR, RX_DATA_ADDR};
        bins fifo_reg = {FIFO_STATUS_ADDR, FIFO_THRESH_ADDR};
        bins int_reg = {INT_EN_ADDR, INT_STATUS_ADDR};
        bins error_reg = {ERROR_ADDR};
        bins diag_reg = {DIAG_ADDR};
        bins safety_reg = {SAFETY_ADDR};
    }

    // Safety Coverage
    safety_feature: coverpoint safety_en {
        bins disabled = {0};
        bins parity = {1};
        bins crc = {2};
        bins ecc = {4};
        bins watchdog = {8};
        bins lockstep = {16};
    }

    // Cross Coverage
    addr_x_speed: cross address_mode, speed_mode;
    reg_x_type: cross register_access, transaction_type;
endgroup
```

#### 6.1.2 Code Coverage
```verilog
// Code coverage directives
// These are typically handled by the simulator
// Example for Questa/ModelSim:
coverage save -onexit coverage.ucdb
coverage report -file coverage.rpt -byfile -detail
```

### 6.2 Scoreboard Implementation Details

#### 6.2.1 Transaction Tracking
```verilog
typedef struct {
    int id;
    time start_time;
    time end_time;
    bit success;
    string description;
    bit [31:0] expected_data;
    bit [31:0] actual_data;
} test_result;

class detailed_scoreboard extends scoreboard;
    test_result results[$];

    function void log_result(int id, bit success, string desc,
                           bit [31:0] exp, bit [31:0] act);
        test_result result;
        result.id = id;
        result.start_time = $time;
        result.success = success;
        result.description = desc;
        result.expected_data = exp;
        result.actual_data = act;
        results.push_back(result);
    endfunction

    function void generate_report();
        $display("\n=== DETAILED TEST REPORT ===");
        foreach (results[i]) begin
            $display("Test %0d: %s - %s",
                    results[i].id,
                    results[i].success ? "PASS" : "FAIL",
                    results[i].description);
            if (!results[i].success) begin
                $display("  Expected: %h, Actual: %h",
                        results[i].expected_data,
                        results[i].actual_data);
            end
        end

        int pass_count = 0;
        foreach (results[i]) begin
            if (results[i].success) pass_count++;
        end

        $display("\nSummary: %0d/%0d tests passed (%.2f%%)",
                pass_count, results.size(),
                (pass_count * 100.0) / results.size());
    endfunction
endclass
```

## 7. Debug and Analysis

### 7.1 Waveform Analysis

#### 7.1.1 Key Signals to Probe
```verilog
// In testbench
initial begin
    $dumpfile("testbench.vcd");
    $dumpvars(0, i2c_tb_top);

    // Key signals for debugging
    $dumpvars(1, dut.pclk);
    $dumpvars(1, dut.presetn);
    $dumpvars(1, dut.psel);
    $dumpvars(1, dut.penable);
    $dumpvars(1, dut.pwrite);
    $dumpvars(1, dut.paddr);
    $dumpvars(1, dut.pwdata);
    $dumpvars(1, dut.prdata);
    $dumpvars(1, dut.scl);
    $dumpvars(1, dut.sda);
    $dumpvars(1, dut.irq);
end
```

#### 7.1.2 GTKWave Setup
```tcl
# .gtkwaverc configuration
# Save this as .gtkwaverc in project directory

# Signal groups
group "APB Interface" {
    pclk presetn psel penable pwrite paddr pwdata prdata pready pslverr
}

group "I2C Interface" {
    scl sda
}

group "Interrupts" {
    irq irq_tx irq_rx irq_error
}

group "Internal State" {
    dut.current_state dut.fsm_state
}
```

### 7.2 Error Analysis

#### 7.2.1 Common Issues and Debugging
```verilog
// Error detection and reporting
class error_analyzer;
    static int error_count = 0;

    static function void report_error(string msg, bit [31:0] expected, bit [31:0] actual);
        error_count++;
        $display("ERROR #%0d: %s", error_count, msg);
        $display("  Expected: %h", expected);
        $display("  Actual:   %h", actual);
        $display("  Time: %t", $time);
    endfunction

    static function void check_timeout(int timeout_cycles);
        fork begin
            #(timeout_cycles * 10);  // Assuming 10ns clock period
            report_error("Test timeout", 0, 0);
            $finish;
        end join_none
    endfunction
endclass
```

## 8. Implementation Guide

### 8.1 Step-by-Step Setup

#### 8.1.1 Directory Structure
```
i2c/
├── src/
│   ├── rtl/          # DUT source files
│   └── tb/           # Testbench files
│       ├── i2c_tb_top.v
│       ├── apb_bfm.sv
│       ├── i2c_monitor.sv
│       ├── scoreboard.sv
│       ├── coverage.sv
│       └── test_lib.sv
├── scripts/
│   ├── compile.sh
│   └── run_test.sh
├── docs/
│   ├── verification_plan.md
│   └── testbench_architecture.md
└── sim/
    └── results/
```

#### 8.1.2 Compilation Script
```bash
#!/bin/bash
# compile.sh

# Compile DUT
iverilog -c dut_files.txt -o dut.o

# Compile testbench
iverilog -c tb_files.txt -o testbench

echo "Compilation complete"
```

#### 8.1.3 File Lists
```text
# dut_files.txt
src/rtl/i2c_top.v
src/rtl/clock_manager.v
src/rtl/control_fsm.v
src/rtl/register_bank.v
src/rtl/shift_register.v
src/rtl/power_mgmt.v
src/rtl/safety_shell.v

# tb_files.txt
src/tb/i2c_tb_top.v
src/tb/apb_bfm.sv
src/tb/i2c_monitor.sv
src/tb/scoreboard.sv
src/tb/coverage.sv
src/tb/test_lib.sv
```

### 8.2 Running Tests

#### 8.2.1 Basic Test Execution
```bash
# Compile
./scripts/compile.sh

# Run specific test
vvp testbench +TEST_NAME=test_reset

# Run with coverage
vvp testbench +TEST_NAME=test_basic_master_tx -coverage

# View results
gtkwave testbench.vcd
```

#### 8.2.2 Advanced Options
```bash
# Run with debug output
vvp testbench +TEST_NAME=test_reset +DEBUG=1

# Run multiple tests
for test in test_reset test_basic_master_tx test_basic_master_rx; do
    echo "Running $test..."
    vvp testbench +TEST_NAME=$test
done
```

## 9. Best Practices

### 9.1 Testbench Development
1. **Modular Design**: Keep components loosely coupled
2. **Reusability**: Design components for reuse across tests
3. **Maintainability**: Use clear naming and documentation
4. **Debugging**: Include comprehensive logging and assertions

### 9.2 Verification Methodology
1. **Coverage-Driven**: Focus on achieving coverage goals
2. **Random Testing**: Use constrained random for corner cases
3. **Regression**: Run full suite before releases
4. **Documentation**: Keep test cases well-documented

### 9.3 Performance Optimization
1. **Simulation Speed**: Use efficient data structures
2. **Memory Usage**: Avoid large arrays when possible
3. **Parallel Execution**: Run independent tests in parallel
4. **Incremental Build**: Only recompile changed files

## 10. Conclusion

This testbench architecture provides a comprehensive framework for verifying the I2C IP core. The modular design enables novice engineers to quickly implement and extend test cases while ensuring thorough coverage of all specified features. The scoreboard and coverage collection ensure measurable verification progress and quality metrics.

The architecture supports all test cases from TC_001 to TC_025, providing a solid foundation for production-ready IP verification.