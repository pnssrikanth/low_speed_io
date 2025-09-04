# 9. Testing and Verification

## 9.1 Verification Methodology

### 9.1.1 Verification Strategy

The I2C IP core uses a comprehensive verification approach combining:

- **Simulation-Based Verification**: RTL and gate-level simulation
- **Formal Verification**: Property checking and equivalence checking
- **Emulation**: FPGA-based prototyping
- **Static Analysis**: Lint, CDC, and RDC checks

### 9.1.2 Verification Environment

```verilog
module i2c_testbench;

// Clock and reset generation
reg clk = 0;
reg rst_n = 0;

// I2C interface
wire scl, sda;

// APB interface
reg [31:0] paddr;
reg psel;
reg penable;
reg pwrite;
reg [31:0] pwdata;
wire [31:0] prdata;
wire pready;

// DUT instantiation
i2c_ip_core dut (
    .clk(clk),
    .rst_n(rst_n),
    .paddr(paddr),
    .psel(psel),
    .penable(penable),
    .pwrite(pwrite),
    .pwdata(pwdata),
    .prdata(prdata),
    .pready(pready),
    .scl(scl),
    .sda(sda)
);

// Test stimulus
initial begin
    // Reset sequence
    rst_n = 0;
    #100 rst_n = 1;

    // Test sequences
    test_basic_write();
    test_basic_read();
    test_error_conditions();
end

endmodule
```

## 9.2 Test Plan

### 9.2.1 Functional Tests

#### 9.2.1.1 Basic I2C Operations

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC_001 | Master write single byte | Data written successfully |
| TC_002 | Master read single byte | Data read successfully |
| TC_003 | Master write multiple bytes | All data written |
| TC_004 | Master read multiple bytes | All data read |
| TC_005 | Slave address recognition | Correct ACK/NACK |

#### 9.2.1.2 Mode Tests

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC_101 | Master-only mode | Slave functions disabled |
| TC_102 | Slave-only mode | Master functions disabled |
| TC_103 | Dual mode switching | Seamless mode transition |
| TC_104 | 10-bit addressing | Extended address support |

#### 9.2.1.3 Speed Mode Tests

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC_201 | Standard mode (100 kbps) | Correct timing |
| TC_202 | Fast mode (400 kbps) | Correct timing |
| TC_203 | Fast mode plus (1 Mbps) | Correct timing |
| TC_204 | High-speed mode (3.4 Mbps) | Correct timing |

### 9.2.2 Error Handling Tests

#### 9.2.2.1 Bus Error Tests

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC_301 | No acknowledge | NACK error reported |
| TC_302 | Arbitration lost | Arbitration error |
| TC_303 | Bus timeout | Timeout error |
| TC_304 | SCL stuck low | Stuck error |
| TC_305 | SDA stuck low | Stuck error |

#### 9.2.2.2 Recovery Tests

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC_401 | Retry after NACK | Successful retry |
| TC_402 | Bus reset after stuck | Bus freed |
| TC_403 | Timeout recovery | Graceful recovery |

### 9.2.3 Performance Tests

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC_501 | Maximum throughput | Meet speed specifications |
| TC_502 | FIFO stress test | No overflow/underflow |
| TC_503 | Interrupt latency | < 10 clock cycles |
| TC_504 | Power consumption | Within specifications |

### 9.2.4 Safety Tests

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC_601 | Fault injection | Fault detected |
| TC_602 | Safety mechanism test | Safe state entered |
| TC_603 | Diagnostic coverage | > 90% coverage |
| TC_604 | ASIL compliance | Meet requirements |

## 9.3 Testbench Architecture

### 9.3.1 I2C Slave Model

```verilog
module i2c_slave_model (
    input scl,
    inout sda
);

// Slave model for verification
reg [6:0] slave_addr = 7'h50;
reg [7:0] memory [0:255];

// I2C protocol implementation
endmodule
```

### 9.3.2 Scoreboard

```verilog
class i2c_scoreboard;
    mailbox expected_mb;
    mailbox actual_mb;

    task run();
        forever begin
            i2c_transaction expected, actual;
            expected_mb.get(expected);
            actual_mb.get(actual);
            compare(expected, actual);
        end
    endtask

    task compare(i2c_transaction exp, i2c_transaction act);
        if (exp.data != act.data) begin
            $error("Data mismatch: expected %h, got %h", exp.data, act.data);
        end
    endtask
endclass
```

### 9.3.3 Coverage Model

```systemverilog
covergroup i2c_coverage @(posedge clk);
    cp_mode: coverpoint mode {
        bins master = {MASTER};
        bins slave = {SLAVE};
        bins dual = {DUAL};
    }

    cp_speed: coverpoint speed {
        bins standard = {STANDARD};
        bins fast = {FAST};
        bins fast_plus = {FAST_PLUS};
        bins high_speed = {HIGH_SPEED};
    }

    cp_error: coverpoint error_type {
        bins nack = {NACK};
        bins arb_lost = {ARB_LOST};
        bins timeout = {TIMEOUT};
        bins bus_stuck = {BUS_STUCK};
    }

    cross_mode_speed: cross cp_mode, cp_speed;
    cross_mode_error: cross cp_mode, cp_error;
endgroup
```

## 9.4 Formal Verification

### 9.4.1 Properties

```systemverilog
// Protocol properties
property p_start_condition;
    @(posedge scl) disable iff (!rst_n)
    $fell(sda) && scl |-> ##1 !sda;
endproperty

// Safety properties
property p_no_glitch;
    @(posedge clk) disable iff (!rst_n)
    $stable(scl) |=> $stable(scl);
endproperty

// Liveness properties
property p_eventual_response;
    @(posedge clk) disable iff (!rst_n)
    start_transaction |-> ##[1:1000] transaction_complete;
endproperty

// Multi-master properties
property p_arbitration_fairness;
    @(posedge scl) disable iff (!rst_n)
    arbitration_start |-> ##[1:100] arbitration_complete or arbitration_lost;
endproperty

// Clock stretching properties
property p_clock_stretching;
    @(posedge scl) disable iff (!rst_n)
    sda_low_during_clock |-> ##1 scl_stretch;
endproperty

// Security properties
property p_secure_access;
    @(posedge clk) disable iff (!rst_n)
    secure_mode && unauthorized_access |-> ##1 access_denied;
endproperty
```

### 9.4.2 Assertions

```systemverilog
// Register access assertions
assert property (@(posedge clk) psel && !pwrite |-> ##1 pready)
    else $error("Read transaction not completed");

// FIFO assertions
assert property (@(posedge clk) !fifo_full |-> wr_en |=> !fifo_full)
    else $error("FIFO overflow");

// I2C protocol assertions
assert property (@(posedge scl) start_condition |-> ##[8:18] stop_condition)
    else $error("Invalid I2C frame length");
```

## 9.5 Emulation and Prototyping

### 9.5.1 FPGA Prototyping

```tcl
# FPGA synthesis script
create_project i2c_proto -part xc7a35ticsg324-1L -force

add_files i2c_ip_core.v
add_files testbench.v

launch_runs synth_1
wait_on_run synth_1

launch_runs impl_1
wait_on_run impl_1

launch_runs impl_1 -to_step write_bitstream
```

### 9.5.2 Hardware Verification

- **Logic Analyzer**: Capture I2C bus signals
- **Protocol Analyzer**: Decode I2C transactions
- **Oscilloscope**: Verify timing parameters
- **Power Analyzer**: Measure power consumption

## 9.6 Regression Testing

### 9.6.1 Test Suite Organization

```
test_suite/
├── functional/
│   ├── basic_operations/
│   ├── mode_tests/
│   └── speed_tests/
├── error_handling/
│   ├── bus_errors/
│   └── recovery/
├── performance/
│   ├── throughput/
│   └── latency/
└── safety/
    ├── fault_injection/
    └── diagnostic/
```

### 9.6.2 Automated Regression

```bash
#!/bin/bash
# Regression script

TESTS="basic_operations mode_tests speed_tests error_handling performance safety"
RESULTS_DIR="regression_results_$(date +%Y%m%d_%H%M%S)"

mkdir -p $RESULTS_DIR

for test in $TESTS; do
    echo "Running $test..."
    make test TEST=$test > $RESULTS_DIR/${test}.log 2>&1
    if [ $? -eq 0 ]; then
        echo "PASS: $test" >> $RESULTS_DIR/summary.txt
    else
        echo "FAIL: $test" >> $RESULTS_DIR/summary.txt
    fi
done

echo "Regression complete. Results in $RESULTS_DIR"
```

## 9.7 Coverage Metrics

### 9.7.1 Code Coverage

- **Line Coverage**: > 95%
- **Branch Coverage**: > 90%
- **Condition Coverage**: > 85%
- **Toggle Coverage**: > 90%
- **FSM State Coverage**: > 98%
- **Path Coverage**: > 80%

### 9.7.2 Functional Coverage

- **Feature Coverage**: 100% of specified features
- **Error Coverage**: All error conditions tested
- **Corner Case Coverage**: Boundary conditions covered

### 9.7.3 Safety Coverage

- **SPFM**: > 99% single-point fault metric
- **LFM**: > 90% latent fault metric
- **DC**: > 90% diagnostic coverage

## 9.8 Test Documentation

### 9.8.1 Test Case Specification

Each test case includes:
- **Objective**: What is being tested
- **Preconditions**: Required setup
- **Test Steps**: Detailed procedure
- **Expected Results**: Pass/fail criteria
- **Post-conditions**: Cleanup requirements

### 9.8.2 Test Results Reporting

```xml
<test_results>
    <test_suite name="i2c_core">
        <test_case name="TC_001" result="PASS" time="0.5">
            <description>Master write single byte</description>
        </test_case>
        <test_case name="TC_002" result="PASS" time="0.3">
            <description>Master read single byte</description>
        </test_case>
    </test_suite>
    <summary>
        <total_tests>50</total_tests>
        <passed>48</passed>
        <failed>2</failed>
        <coverage>96.5%</coverage>
    </summary>
</test_results>
```

---

[Previous: Software Interface](./software_interface.md) | [Next: Appendices](./appendices.md)