# I2C IP Core Verification Plan

## Document Information

| **Document Title** | I2C IP Core Verification Plan |
|--------------------|-------------------------------|
| **Version** | 1.0 |
| **Date** | October 2025 |
| **Author** | Open-Source I2C IP Development Team |
| **Reviewers** | [To be assigned] |
| **Approval** | [To be assigned] |

## Revision History

| Version | Date | Description | Author |
|---------|------|-------------|--------|
| 1.0 | October 2025 | Initial release | AI Assistant |

## Table of Contents

1. [Introduction](#1-introduction)
2. [Verification Methodology](#2-verification-methodology)
3. [Testbench Architecture](#3-testbench-architecture)
4. [Test Case Specification](#4-test-case-specification)
5. [Coverage Metrics](#5-coverage-metrics)
6. [Environment Setup](#6-environment-setup)
7. [Execution and Reporting](#7-execution-and-reporting)
8. [Sign-off Criteria](#8-sign-off-criteria)
9. [Appendices](#9-appendices)

## 1. Introduction

### 1.1 Purpose

This document provides a comprehensive verification plan for the I2C IP core, ensuring it meets all functional, performance, and safety requirements before production release. The plan is designed to be executable by verification engineers of varying experience levels, with detailed step-by-step instructions and clear objectives.

### 1.2 Scope

The verification plan covers:
- Functional verification of all I2C protocols (Standard, Fast, Fast Plus, High Speed)
- AMBA APB interface compliance
- Safety mechanisms (for automotive mode)
- Performance validation
- Error handling and recovery
- Integration testing

### 1.3 Assumptions

- Icarus Verilog simulator is available
- Basic knowledge of Verilog and SystemVerilog
- Access to I2C protocol specifications
- Linux/Windows development environment

### 1.4 References

- [I2C-bus specification (UM10204)](https://www.nxp.com/docs/en/user-guide/UM10204.pdf)
- [AMBA APB Protocol Specification](https://developer.arm.com/documentation/ihi0024/latest/)
- I2C IP Architecture Specification (`docs/arch_spec/`)
- I2C IP Micro-Architecture Specification (`docs/micro_arch_spec/`)

## 2. Verification Methodology

### 2.1 Overall Strategy

The verification follows a **layered approach** combining:
- **Directed Testing**: Specific test cases for known scenarios
- **Constrained Random Testing**: Randomized stimuli within valid ranges
- **Coverage-Driven Verification**: Metrics to ensure completeness

### 2.2 Verification Levels

1. **Unit Level**: Individual module verification
2. **Integration Level**: Module interaction verification
3. **System Level**: Full IP verification with APB interface
4. **Regression Level**: Automated test suite execution

### 2.3 Tools and Languages

- **HDL**: Verilog (RTL), SystemVerilog (testbench)
- **Simulator**: Icarus Verilog (iverilog + vvp)
- **Waveform Viewer**: GTKWave
- **Coverage Tools**: Built-in Verilog coverage (if available)

## 3. Testbench Architecture

### 3.1 Top-Level Structure

```
i2c_top_tb
├── Clock Generator
├── Reset Generator
├── APB Master BFM (Bus Functional Model)
├── I2C Monitor
├── Scoreboard
├── Coverage Collector
└── DUT (i2c_top)
```

### 3.2 Component Descriptions

#### 3.2.1 Clock Generator
```verilog
module clk_gen;
    parameter CLK_PERIOD = 10; // 10ns for 100MHz
    reg clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;
endmodule
```

#### 3.2.2 APB Master BFM
- Generates APB transactions
- Supports read/write operations
- Handles protocol timing

#### 3.2.3 I2C Monitor
- Captures I2C bus activity
- Decodes START/STOP conditions
- Validates data integrity

#### 3.2.4 Scoreboard
- Compares expected vs. actual results
- Maintains transaction history
- Reports mismatches

### 3.3 Interface Connections

```
APB Master BFM <-> DUT (APB Interface)
I2C Monitor <-> DUT (I2C Bus)
Scoreboard <-> APB BFM & I2C Monitor
Coverage Collector <-> All components
```

## 4. Test Case Specification

### 4.1 Test Case Categories

#### 4.1.1 Basic Functionality Tests

**TC_001: Reset Functionality**
- **Objective**: Verify proper reset behavior
- **Stimulus**: Assert reset signal
- **Expected**: All registers cleared, outputs in default state
- **Coverage**: Reset conditions

**TC_002: Register Access**
- **Objective**: Test APB register read/write
- **Stimulus**: Write to all registers, read back
- **Expected**: Data integrity, correct register mapping
- **Coverage**: Register access patterns

#### 4.1.2 I2C Protocol Tests

**TC_003: START/STOP Generation**
- **Objective**: Verify START and STOP condition generation
- **Stimulus**: Set mode to Master TX, trigger start
- **Expected**: Correct SDA/SCL timing for START/STOP
- **Coverage**: START/STOP detection

**TC_004: Data Transmission (7-bit addressing)**
- **Objective**: Test basic data transfer
- **Stimulus**: Configure master mode, send data byte
- **Expected**: Correct data on I2C bus, ACK received
- **Coverage**: Data transmission paths

**TC_005: Data Reception (7-bit addressing)**
- **Objective**: Test data receive functionality
- **Stimulus**: Configure master RX mode, receive data
- **Expected**: Data correctly received and stored
- **Coverage**: Data reception paths

#### 4.1.3 Advanced Features

**TC_006: 10-bit Addressing**
- **Objective**: Verify 10-bit address support
- **Stimulus**: Enable 10-bit mode, send 10-bit address
- **Expected**: Correct 2-byte address transmission
- **Coverage**: 10-bit address handling

**TC_007: Clock Stretching**
- **Objective**: Test clock stretching mechanism
- **Stimulus**: Enable stretching, trigger slow slave response
- **Expected**: SCL held low until ready
- **Coverage**: Clock stretching scenarios

**TC_008: Multi-Master Arbitration**
- **Objective**: Verify arbitration logic
- **Stimulus**: Simulate bus contention
- **Expected**: Proper arbitration winner selection
- **Coverage**: Arbitration states

#### 4.1.4 Error Handling Tests

**TC_009: NACK Handling**
- **Objective**: Test NACK response
- **Stimulus**: Slave sends NACK
- **Expected**: Transmission aborted, error flag set
- **Coverage**: Error conditions

**TC_010: Bus Error Detection**
- **Objective**: Verify bus error handling
- **Stimulus**: Corrupt I2C signals
- **Expected**: Error detection and recovery
- **Coverage**: Bus error scenarios

#### 4.1.5 Performance Tests

**TC_011: Speed Mode Validation**
- **Objective**: Test all I2C speed modes
- **Stimulus**: Configure different speed modes
- **Expected**: Correct timing for each mode
- **Coverage**: Speed mode configurations

**TC_012: Throughput Measurement**
- **Objective**: Measure maximum data rate
- **Stimulus**: Continuous data transfer
- **Expected**: Meet specified throughput requirements
- **Coverage**: Performance metrics

#### 4.1.6 Micro-Architecture Specific Tests

**TC_013: SMBus PEC Functionality**
- **Objective**: Test Packet Error Checking for SMBus mode
- **Stimulus**: Enable PEC, transmit data with PEC byte
- **Expected**: Correct CRC-8 calculation, PEC validation
- **Coverage**: PEC module, error detection

**TC_014: Power Management States**
- **Objective**: Verify power state transitions
- **Stimulus**: Transition through ACTIVE/IDLE/SLEEP/OFF states
- **Expected**: Correct state changes, data preservation, wake-up
- **Coverage**: Power management module, clock gating

**TC_015: Debug and Test Interface**
- **Objective**: Test debug registers and JTAG functionality
- **Stimulus**: Access debug registers, test breakpoints
- **Expected**: Debug register functionality, BIST results
- **Coverage**: Debug interface, test modes

**TC_016: Clock Domain Crossing**
- **Objective**: Verify CDC handling between system and I2C clocks
- **Stimulus**: Vary clock frequencies, test data transfer
- **Expected**: No data corruption, proper synchronization
- **Coverage**: CDC synchronizers, metastability

**TC_017: FSM State Coverage**
- **Objective**: Test all FSM states and transitions
- **Stimulus**: Exercise all master/slave FSM states
- **Expected**: 100% state coverage, correct transitions
- **Coverage**: Control FSM, state machines

**TC_018: Timing Compliance**
- **Objective**: Verify I2C bus timing for all modes
- **Stimulus**: Configure speed modes, measure timing
- **Expected**: Timing within I2C specification limits
- **Coverage**: Clock manager, timing parameters

**TC_019: Safety Mechanism Validation**
- **Objective**: Test safety features for fault detection
- **Stimulus**: Enable safety features, inject faults
- **Expected**: Fault detection, safe recovery
- **Coverage**: Safety mechanisms, error handling

**TC_020: Register Bank Verification**
- **Objective**: Test all registers and APB interface
- **Stimulus**: Read/write all registers, test APB protocol
- **Expected**: Register functionality, APB compliance
- **Coverage**: Register bank, APB interface

#### 4.1.7 Architecture-Specific Tests

**TC_021: Automotive Safety Features**
- **Objective**: Test ISO 26262 safety mechanisms
- **Stimulus**: Enable safety features, inject faults
- **Expected**: Fault detection, safe recovery, ASIL compliance
- **Coverage**: Safety shell, ECC, lockstep, watchdog

**TC_022: Security Features**
- **Objective**: Test security mechanisms
- **Stimulus**: Enable encryption, test access control
- **Expected**: Data protection, secure communication
- **Coverage**: Encryption, secure boot, tamper detection

**TC_023: AHB Interface Verification**
- **Objective**: Test AHB-Lite interface compliance
- **Stimulus**: AHB transfers, burst operations
- **Expected**: Protocol compliance, data integrity
- **Coverage**: AHB interface, high-performance mode

**TC_024: JTAG and Debug Interface**
- **Objective**: Test debug and test interfaces
- **Stimulus**: JTAG operations, boundary scan
- **Expected**: Debug register access, test mode functionality
- **Coverage**: JTAG interface, debug features

**TC_025: Environmental Stress Testing**
- **Objective**: Test under automotive conditions
- **Stimulus**: Temperature/voltage variations, EMI
- **Expected**: Reliable operation, fault detection
- **Coverage**: AEC-Q100 compliance, environmental robustness

### 4.2 Test Case Implementation Template

```verilog
class test_case_template extends base_test;

    task run();
        // 1. Setup DUT configuration
        // 2. Apply stimulus
        // 3. Monitor responses
        // 4. Check results
        // 5. Report pass/fail
    endtask

endclass
```

## 5. Coverage Metrics

### 5.1 Functional Coverage

#### 5.1.1 I2C Protocol Coverage
- **START/STOP Conditions**: 100% (detected, generated)
- **Address Types**: 7-bit (100%), 10-bit (100%)
- **Data Transfer**: TX (100%), RX (100%)
- **ACK/NACK**: Generation (100%), Reception (100%)
- **Speed Modes**: Standard (100%), Fast (100%), Fast+ (100%), HS (100%)

#### 5.1.2 APB Interface Coverage
- **Transfer Types**: Read (100%), Write (100%)
- **Address Range**: All registers (100%)
- **Error Conditions**: PSLVERR (100%), PREADY (100%)

#### 5.1.3 Error Scenarios
- **Bus Errors**: 100%
- **Arbitration Loss**: 100%
- **Timeout Conditions**: 100%
- **Invalid States**: 100%

#### 5.1.4 Architecture Coverage
- **Automotive Safety**: 100% (ISO 26262 ASIL B/C, fault detection/mitigation)
- **Security Features**: 100% (encryption, secure boot, access control)
- **AHB Interface**: 100% (protocol compliance, burst operations)
- **JTAG/Debug Interface**: 100% (boundary scan, debug registers)
- **Environmental Stress**: 100% (AEC-Q100, EMI, temperature)
- **Micro-Architecture**: 100% (PEC, power states, debug, CDC, FSM, timing, safety, registers)

### 5.2 Code Coverage Goals

- **Statement Coverage**: ≥ 95%
- **Branch Coverage**: ≥ 90%
- **Toggle Coverage**: ≥ 95%
- **FSM State Coverage**: 100% (all master/slave states)
- **Module Coverage**: 100% (clock manager, shift register, PEC, power mgmt, debug)

### 5.3 Assertion Coverage

- **Protocol Assertions**: 100%
- **Timing Assertions**: 100%
- **Safety Assertions**: 100% (automotive mode)

## 6. Environment Setup

### 6.1 Prerequisites

1. **Install Icarus Verilog**:
   ```bash
   sudo apt-get install iverilog  # Ubuntu/Debian
   # or
   brew install icarus-verilog    # macOS
   ```

2. **Install GTKWave** (optional, for waveform viewing):
   ```bash
   sudo apt-get install gtkwave
   ```

### 6.2 Directory Structure

```
i2c/
├── src/
│   ├── rtl/          # RTL source files
│   └── tb/           # Test bench files
├── scripts/          # Build scripts
├── docs/             # Documentation
└── verification/     # Verification environment (to be created)
    ├── tests/        # Individual test cases
    ├── lib/          # Verification library
    └── results/      # Test results
```

### 6.3 Running Tests

1. **Compile RTL**:
   ```bash
   cd i2c/scripts
   ./compile.sh
   ```

2. **Run Test**:
   ```bash
   cd i2c/src/tb
   iverilog -o testbench i2c_top_tb.v ../rtl/*.v
   vvp testbench
   ```

3. **View Results**:
   ```bash
   gtkwave testbench.vcd
   ```

## 7. Execution and Reporting

### 7.1 Test Execution Flow

1. **Setup**: Initialize testbench components
2. **Configuration**: Set DUT parameters
3. **Stimulation**: Apply test vectors
4. **Monitoring**: Capture responses
5. **Checking**: Compare expected vs. actual
6. **Reporting**: Generate test report

### 7.2 Report Format

```
Test Report
===========
Test Name: TC_001_Reset_Functionality
Status: PASS/FAIL
Execution Time: 1.2ms
Coverage: 85%
Details:
- Sub-test 1: PASS
- Sub-test 2: PASS
```

### 7.3 Regression Testing

- **Daily Regression**: Run all tests nightly
- **Gate Regression**: Run before code commits
- **Full Regression**: Run before releases

## 8. Sign-off Criteria

### 8.1 Functional Sign-off

- ✅ All test cases pass (100%)
- ✅ Functional coverage ≥ 95% (including arch and micro-arch features)
- ✅ Code coverage ≥ 90% (statement, branch, toggle, FSM)
- ✅ Module coverage 100% (all internal modules verified)
- ✅ Safety coverage 100% (ISO 26262, ASIL compliance)
- ✅ Security coverage 100% (encryption, access control)
- ✅ Interface coverage 100% (APB, AHB, JTAG, DMA)
- ✅ No critical bugs open

### 8.2 Performance Sign-off

- ✅ Timing requirements met
- ✅ Throughput specifications achieved
- ✅ Power consumption within limits

### 8.3 Documentation Sign-off

- ✅ Verification plan reviewed and approved
- ✅ Test cases documented
- ✅ Results archived

## 9. Appendices

### 9.1 Glossary

- **BFM**: Bus Functional Model
- **DUT**: Device Under Test
- **RTL**: Register Transfer Level
- **UVM**: Universal Verification Methodology

### 9.2 Test Case Priority Matrix

| Priority | Description | Test Cases |
|----------|-------------|------------|
| High | Critical functionality | TC_001-TC_005 |
| Medium | Advanced features | TC_006-TC_010 |
| Low | Performance/edge cases | TC_011-TC_012 |

### 9.3 Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Timing violations | Medium | High | Add timing assertions |
| Protocol compliance | Low | High | Reference I2C specification |
| Coverage holes | Medium | Medium | Regular coverage reviews |
| Safety mechanism bugs | High | Critical | Extensive fault injection testing |
| Security vulnerabilities | Medium | High | Security-focused verification |
| Automotive compliance | High | Critical | ISO 26262 validation |
| Multi-interface complexity | Medium | High | Interface-specific test suites |

---

**End of Document**

This verification plan ensures the I2C IP core is thoroughly tested and production-ready, covering all features from both the architecture and micro-architecture specifications including dual-mode operation, all speed modes, automotive safety (ISO 26262 ASIL B/C), security features, multiple bus interfaces (APB/AHB), debug capabilities, and comprehensive fault detection/recovery mechanisms. Follow the step-by-step instructions for implementation.