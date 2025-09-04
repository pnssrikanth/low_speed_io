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
- **System Clock (PCLK)**: Primary clock domain for all internal logic (10-200 MHz)
- **I2C Clock (SCL)**: Derived from system clock, asynchronous to system clock
- **Clock Frequency Range**: 10 MHz to 200 MHz (APB system clock)
- **Clock Jitter Tolerance**: ±5% of clock period
- **SCL Frequency Range**: 1 kHz to 3.4 MHz (depending on system clock and divider)

### Clock Divider Architecture

#### Divider Operation
The I2C clock is generated using a programmable divider that creates a 50% duty cycle SCL signal:

```
SCL Frequency = System Clock Frequency / (2 × Divider Value)
```

#### Divider Value Sources
1. **Automatic Mode**: Pre-calculated values based on CONFIG register speed mode
2. **Manual Mode**: Custom divider value from TIMING register (overrides automatic)

#### Automatic Divider Values (for 10 MHz system clock)
| Speed Mode | Target SCL | Divider | Actual SCL | Notes |
|------------|------------|---------|------------|-------|
| Standard | 100 kHz | 50 | 100 kHz | Exact match |
| Fast | 400 kHz | 12.5 | 400 kHz | Rounded to 12/13 |
| Fast+ | 1 MHz | 5 | 1 MHz | Exact match |
| High Speed | 3.4 MHz | 1.47 | ~3.4 MHz | Rounded |

#### Manual Divider Calculation
```
Divider = (System Clock Frequency) / (2 × Desired SCL Frequency)
```

**Examples:**
- 50 MHz system clock, 100 kHz SCL: Divider = 50,000,000 / (2 × 100,000) = 250
- 100 MHz system clock, 400 kHz SCL: Divider = 100,000,000 / (2 × 400,000) = 125
- 25 MHz system clock, 1 MHz SCL: Divider = 25,000,000 / (2 × 1,000,000) = 12.5 → 12 or 13

### Programming the Clock Divider

#### Method 1: Automatic Speed Mode (Recommended)
```c
// Set speed mode in CONFIG register (bits 1:0)
#define I2C_SPEED_STANDARD  0x00  // 100 kHz
#define I2C_SPEED_FAST      0x01  // 400 kHz
#define I2C_SPEED_FAST_PLUS 0x02  // 1 MHz
#define I2C_SPEED_HIGH      0x03  // 3.4 MHz

// Example: Configure for Fast Mode (400 kHz)
I2C->CONFIG = I2C_SPEED_FAST;  // Uses automatic divider
```

#### Method 2: Manual Divider Value
```c
// Override with custom divider in TIMING register
// Example: 50 MHz system clock, target 200 kHz SCL
uint32_t divider = 50000000 / (2 * 200000);  // = 125
I2C->TIMING = divider;

// For 100 MHz system clock, target 1 MHz SCL
uint32_t divider = 100000000 / (2 * 1000000);  // = 50
I2C->TIMING = divider;
```

#### Method 3: Dynamic Frequency Changes
```c
// Change frequency during operation
void i2c_set_frequency(uint32_t hz) {
    uint32_t sys_freq = get_system_clock_freq();
    uint32_t divider = sys_freq / (2 * hz);
    I2C->TIMING = divider;
}

// Usage
i2c_set_frequency(100000);   // 100 kHz
i2c_set_frequency(400000);   // 400 kHz
i2c_set_frequency(1000000);  // 1 MHz
```

### Clock Divider Constraints

#### Minimum/Maximum Values
- **Minimum Divider**: 2 (maximum SCL frequency = System Clock / 4)
- **Maximum Divider**: 65535 (16-bit counter)
- **Recommended Range**: 3 to 50000 (for practical SCL frequencies)

#### Precision Considerations
- Divider values are rounded down (truncated)
- Actual SCL frequency = System Clock / (2 × floor(Divider))
- Frequency error < 0.5% for most practical values

#### System Clock Frequency Detection
```c
// Auto-detect system clock for divider calculation
uint32_t get_optimal_divider(uint32_t target_scl_hz) {
    const uint32_t sys_freqs[] = {10000000, 25000000, 50000000, 100000000, 200000000};
    uint32_t best_divider = 100;  // Default
    uint32_t min_error = UINT32_MAX;

    for (int i = 0; i < sizeof(sys_freqs)/sizeof(sys_freqs[0]); i++) {
        uint32_t divider = sys_freqs[i] / (2 * target_scl_hz);
        if (divider >= 2 && divider <= 65535) {
            uint32_t actual_freq = sys_freqs[i] / (2 * divider);
            uint32_t error = abs((int32_t)actual_freq - (int32_t)target_scl_hz);
            if (error < min_error) {
                min_error = error;
                best_divider = divider;
            }
        }
    }
    return best_divider;
}
```

### APB Interface Timing
| APB Signal | Setup Time (ns) | Hold Time (ns) | Clock Edge |
|------------|-----------------|---------------|------------|
| PADDR | 2.0 | 1.0 | PCLK rising |
| PWDATA | 2.0 | 1.0 | PCLK rising |
| PWRITE | 2.0 | 1.0 | PCLK rising |
| PSEL | 2.0 | 1.0 | PCLK rising |
| PENABLE | 2.0 | 1.0 | PCLK rising |
| PRDATA | - | 2.0 | PCLK rising |
| PREADY | - | 2.0 | PCLK rising |
| PSLVERR | - | 2.0 | PCLK rising |

### Practical Programming Guide

#### 1. Basic I2C Setup with Automatic Speed Mode
```c
void i2c_init_basic(uint32_t speed_mode) {
    // Reset I2C core
    I2C->CTRL = 0;

    // Configure speed mode (uses automatic divider)
    I2C->CONFIG = speed_mode;

    // Enable interrupts
    I2C->CTRL |= (1 << 6);  // INT_EN bit

    // Enable I2C core
    I2C->CTRL |= (1 << 0);  // ENABLE bit
}
```

#### 2. Advanced Setup with Custom Timing
```c
void i2c_init_advanced(uint32_t sys_clock_hz, uint32_t target_scl_hz) {
    // Reset I2C core
    I2C->CTRL = 0;

    // Calculate and set custom divider
    uint32_t divider = sys_clock_hz / (2 * target_scl_hz);
    I2C->TIMING = divider;

    // Configure other settings
    I2C->CONFIG = 0;  // Use manual timing (TIMING register)

    // Enable I2C core
    I2C->CTRL |= (1 << 0);  // ENABLE bit
}
```

#### 3. Runtime Frequency Changes
```c
void i2c_change_frequency(uint32_t new_scl_hz) {
    // Calculate new divider
    uint32_t sys_freq = 50000000;  // Your system clock frequency
    uint32_t divider = sys_freq / (2 * new_scl_hz);

    // Update timing register
    I2C->TIMING = divider;

    // Wait for timing update (optional)
    // Small delay may be needed for clock manager to sync
}
```

#### 4. Frequency Verification
```c
uint32_t i2c_get_actual_frequency(void) {
    uint32_t sys_freq = 50000000;  // Your system clock frequency
    uint32_t divider = I2C->TIMING;

    if (divider == 0) {
        // Using automatic mode - check CONFIG register
        uint32_t speed_mode = I2C->CONFIG & 0x03;
        switch (speed_mode) {
            case 0: divider = 50; break;   // 100 kHz at 10 MHz
            case 1: divider = 12; break;   // 400 kHz at 10 MHz
            case 2: divider = 5; break;    // 1 MHz at 10 MHz
            case 3: divider = 1; break;    // 3.4 MHz at 10 MHz
        }
    }

    return sys_freq / (2 * divider);
}
```

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