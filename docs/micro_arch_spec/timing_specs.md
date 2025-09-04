# Timing Specifications

## Overview
This document defines the timing requirements and constraints for the I2C IP core implementation. It covers I2C bus timing, internal clock domains, and synthesis constraints.

## I2C Bus Timing Parameters

### Standard Mode (100 kHz)
| Parameter | Symbol | Min | Typ | Max | Unit | Description |
|-----------|--------|-----|-----|-----|------|-------------|
| SCL Clock Frequency | f_SCL | - | 100 | 100 | kHz | Serial clock frequency |
| SCL Low Period | t_LOW | 4.7 | - | - | μs | SCL low time |
| SCL High Period | t_HIGH | 4.0 | - | - | μs | SCL high time |
| SDA Setup Time | t_SU;DAT | 250 | - | - | ns | Data setup time |
| SDA Hold Time | t_HD;DAT | 0 | - | 3.45 | μs | Data hold time |
| START Setup Time | t_SU;STA | 4.7 | - | - | μs | Repeated START setup time |
| START Hold Time | t_HD;STA | 4.0 | - | - | μs | START hold time |
| STOP Setup Time | t_SU;STO | 4.0 | - | - | μs | STOP setup time |
| Bus Free Time | t_BUF | 4.7 | - | - | μs | Bus free time between transactions |
| Clock/Data Fall Time | t_f | - | - | 300 | ns | Fall time |
| Clock/Data Rise Time | t_r | - | - | 1000 | ns | Rise time |

### Fast Mode (400 kHz)
| Parameter | Symbol | Min | Typ | Max | Unit | Description |
|-----------|--------|-----|-----|-----|------|-------------|
| SCL Clock Frequency | f_SCL | - | 400 | 400 | kHz | Serial clock frequency |
| SCL Low Period | t_LOW | 1.3 | - | - | μs | SCL low time |
| SCL High Period | t_HIGH | 0.6 | - | - | μs | SCL high time |
| SDA Setup Time | t_SU;DAT | 100 | - | - | ns | Data setup time |
| SDA Hold Time | t_HD;DAT | 0 | - | 0.9 | μs | Data hold time |
| START Setup Time | t_SU;STA | 0.6 | - | - | μs | Repeated START setup time |
| START Hold Time | t_HD;STA | 0.6 | - | - | μs | START hold time |
| STOP Setup Time | t_SU;STO | 0.6 | - | - | μs | STOP setup time |
| Bus Free Time | t_BUF | 1.3 | - | - | μs | Bus free time |
| Clock/Data Fall Time | t_f | - | - | 300 | ns | Fall time |
| Clock/Data Rise Time | t_r | - | - | 300 | ns | Rise time |

### Fast Mode Plus (1 MHz)
| Parameter | Symbol | Min | Typ | Max | Unit | Description |
|-----------|--------|-----|-----|-----|------|-------------|
| SCL Clock Frequency | f_SCL | - | 1000 | 1000 | kHz | Serial clock frequency |
| SCL Low Period | t_LOW | 0.5 | - | - | μs | SCL low time |
| SCL High Period | t_HIGH | 0.26 | - | - | μs | SCL high time |
| SDA Setup Time | t_SU;DAT | 50 | - | - | ns | Data setup time |
| SDA Hold Time | t_HD;DAT | 0 | - | 0.45 | μs | Data hold time |
| START Setup Time | t_SU;STA | 0.26 | - | - | μs | Repeated START setup time |
| START Hold Time | t_HD;STA | 0.26 | - | - | μs | START hold time |
| STOP Setup Time | t_SU;STO | 0.26 | - | - | μs | STOP setup time |
| Bus Free Time | t_BUF | 0.5 | - | - | μs | Bus free time |
| Clock/Data Fall Time | t_f | - | - | 120 | ns | Fall time |
| Clock/Data Rise Time | t_r | - | - | 120 | ns | Rise time |

## Internal Timing Constraints

### Clock Domain Specifications
- **System Clock**: Primary clock domain for all internal logic
- **I2C Clock**: Derived from system clock, asynchronous to system clock
- **Clock Frequency Range**: 10 MHz to 200 MHz (system clock)
- **Clock Jitter Tolerance**: ±5% of clock period

### Setup and Hold Times
| Signal | Setup Time (ns) | Hold Time (ns) | Clock Edge |
|--------|-----------------|---------------|------------|
| data_in | 2.0 | 1.0 | Rising |
| addr | 2.0 | 1.0 | Rising |
| start_tx | 2.0 | 1.0 | Rising |
| config_reg | 2.0 | 1.0 | Rising |
| scl (async) | - | 5.0 | - |
| sda (async) | - | 5.0 | - |

### Propagation Delays
| Path | Max Delay (ns) | Description |
|------|----------------|-------------|
| clk to sda_out | 10.0 | Control to output |
| clk to scl_out | 10.0 | Control to output |
| sda_in to status | 15.0 | Input to status |
| scl_in to status | 15.0 | Input to status |
| data_in to tx_done | 50.0 | Data processing |
| start_tx to busy | 5.0 | Command response |

## Synthesis Constraints

### Timing Constraints (SDC Format)
```tcl
# Create clocks
create_clock -name sys_clk -period 10.0 [get_ports clk]
create_clock -name i2c_clk -period 10.0 [get_ports scl] -add

# Clock uncertainty
set_clock_uncertainty 0.5 [get_clocks sys_clk]
set_clock_uncertainty 0.2 [get_clocks i2c_clk]

# Input delays
set_input_delay -clock sys_clk -max 2.0 [get_ports {data_in[*] addr[*] start_tx}]
set_input_delay -clock sys_clk -min 1.0 [get_ports {data_in[*] addr[*] start_tx}]

# Output delays
set_output_delay -clock sys_clk -max 5.0 [get_ports {data_out[*] tx_done rx_done busy}]
set_output_delay -clock sys_clk -min 1.0 [get_ports {data_out[*] tx_done rx_done busy}]

# Asynchronous clock domain crossings
set_false_path -from [get_clocks sys_clk] -to [get_clocks i2c_clk]
set_false_path -from [get_clocks i2c_clk] -to [get_clocks sys_clk]

# Multi-cycle paths
set_multicycle_path -from [get_ports data_in] -to [get_ports data_out] 2
```

### Area Constraints
- **Maximum Area**: 5000 gate equivalents
- **Power Budget**: 10 mW at 100 MHz
- **Cell Utilization**: < 80% for routing optimization

### Power Constraints
```tcl
# Power analysis setup
set_operating_conditions -library typical -max typical -min typical
set_power_analysis_mode -method dynamic

# Power domains
create_power_domain PD_CORE -default
create_power_domain PD_IO -elements {sda_buffer scl_buffer}

# Power constraints
set_max_dynamic_power 10.0
set_max_leakage_power 1.0
```

## Clock Domain Crossing (CDC) Considerations

### Synchronizer Implementation
```verilog
module cdc_synchronizer (
    input wire clk_src,
    input wire clk_dst,
    input wire data_in,
    output wire data_out
);

    reg [2:0] sync_reg;

    always @(posedge clk_dst) begin
        sync_reg <= {sync_reg[1:0], data_in};
    end

    assign data_out = sync_reg[2];

endmodule
```

### CDC Paths Identification
| Source Domain | Destination Domain | Signals | Synchronizer Type |
|---------------|---------------------|---------|-------------------|
| System | I2C | start_tx, data_in | 2-FF synchronizer |
| I2C | System | sda_in, scl_in | 2-FF synchronizer |
| System | System | Internal signals | None required |

### Metastability Analysis
- **MTBF Calculation**: > 10^9 years for 2-FF synchronizers
- **Resolution Time**: 2 clock cycles
- **Data Validity**: Stable for 1 clock cycle after synchronization

## Timing Closure Strategies

### 1. Pipeline Insertion
```verilog
module timing_pipeline (
    input wire clk,
    input wire data_in,
    output wire data_out
);

    reg pipe1, pipe2;

    always @(posedge clk) begin
        pipe1 <= data_in;
        pipe2 <= pipe1;
    end

    assign data_out = pipe2;

endmodule
```

### 2. Clock Skew Management
- Use balanced clock trees
- Minimize clock buffer delays
- Apply clock uncertainty constraints

### 3. False Path Constraints
```tcl
# False paths for asynchronous resets
set_false_path -from [get_ports rst_n] -to [all_registers]

# False paths for debug signals
set_false_path -from [get_ports debug_*] -to [all_registers]
```

## Verification Timing Checks

### Static Timing Analysis (STA)
- Setup time violations: 0 allowed
- Hold time violations: 0 allowed
- Maximum frequency: 200 MHz
- Minimum frequency: 10 MHz

### Dynamic Timing Simulation
- Use SDF back-annotation
- Include interconnect delays
- Verify timing at PVT corners

---

[Back to Index](index.md) | [Previous: Implementation Examples](implementation_examples.md) | [Next: Safety Mechanisms](safety_mechanisms.md)