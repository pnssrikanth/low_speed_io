# Interface Details

## Overview
This document describes the external interfaces of the I2C IP core, including pin definitions, signal protocols, and timing diagrams. The IP core supports both master and slave modes with configurable I/O standards.

## Pin Interface

### I2C Bus Signals
| Signal | Direction | Description | Width |
|--------|-----------|-------------|-------|
| `scl` | Bidirectional | Serial Clock Line | 1 |
| `sda` | Bidirectional | Serial Data Line | 1 |

### Control and Status Signals
| Signal | Direction | Description | Width |
|--------|-----------|-------------|-------|
| `clk` | Input | System Clock | 1 |
| `rst_n` | Input | Active Low Reset | 1 |
| `enable` | Input | IP Core Enable | 1 |
| `mode` | Input | Operation Mode (0: Slave, 1: Master) | 1 |
| `speed_mode` | Input | I2C Speed Mode (00: Standard, 01: Fast, 10: Fast Plus, 11: High Speed) | 2 |
| `irq` | Output | Interrupt Request | 1 |
| `busy` | Output | IP Core Busy Status | 1 |

### Data Interface
| Signal | Direction | Description | Width |
|--------|-----------|-------------|-------|
| `data_in` | Input | Data to Transmit | 8 |
| `data_out` | Output | Received Data | 8 |
| `addr` | Input | Slave Address (for Master mode) or Device Address (for Slave mode) | 7 |
| `rw` | Input | Read/Write Operation (0: Write, 1: Read) | 1 |
| `start_tx` | Input | Start Transmission | 1 |
| `tx_done` | Output | Transmission Complete | 1 |
| `rx_done` | Output | Reception Complete | 1 |

### Configuration Signals
| Signal | Direction | Description | Width |
|--------|-----------|-------------|-------|
| `config_reg` | Input | Configuration Register | 32 |
| `status_reg` | Output | Status Register | 32 |

## Signal Protocols

### I2C Bus Protocol
The IP core implements the I2C bus protocol as defined in the I2C specification. Key protocol elements:

- **START Condition**: SDA transitions from high to low while SCL is high
- **STOP Condition**: SDA transitions from low to high while SCL is high
- **Data Transfer**: 8-bit data followed by ACK/NACK bit
- **Addressing**: 7-bit or 10-bit addressing modes supported

### Clock Stretching
The IP core supports clock stretching in both master and slave modes:
- Slave can hold SCL low to slow down the master
- Master can detect and handle clock stretching from slaves

### Arbitration
In multi-master configurations:
- IP monitors SDA during transmission
- Arbitration loss detected if transmitted bit differs from SDA
- Automatic recovery and retry mechanisms

## Timing Diagrams

### Standard Mode Timing (100 kHz)
```
SCL:  ____/‾‾‾‾\____/‾‾‾‾\____/‾‾‾‾\____
SDA:  XXXXXXXX|START| A6-A0 |R/W|ACK| D7-D0 |ACK|STOP|XXXXXXXX

     |<-- t_HD;STA -->|<-- t_LOW -->|<-- t_HIGH -->|<-- t_SU;STA -->|
```

### Fast Mode Timing (400 kHz)
```
SCL:  ____/‾‾\____/‾‾\____/‾‾\____
SDA:  XXXXXXXX|START| A6-A0 |R/W|ACK| D7-D0 |ACK|STOP|XXXXXXXX

     |<-- t_HD;STA -->|<-- t_LOW -->|<-- t_HIGH -->|<-- t_SU;STA -->|
```

### Timing Parameters
| Parameter | Standard Mode | Fast Mode | Fast Mode Plus | High Speed Mode |
|-----------|---------------|-----------|----------------|-----------------|
| f_SCL | 100 kHz | 400 kHz | 1 MHz | 3.4 MHz |
| t_HD;STA | 4.0 μs | 0.6 μs | 0.26 μs | 0.16 μs |
| t_LOW | 4.7 μs | 1.3 μs | 0.5 μs | 0.16 μs |
| t_HIGH | 4.0 μs | 0.6 μs | 0.26 μs | 0.09 μs |
| t_SU;STA | 4.7 μs | 0.6 μs | 0.26 μs | 0.16 μs |
| t_HD;DAT | 0 μs | 0 μs | 0 μs | 0 μs |
| t_SU;DAT | 250 ns | 100 ns | 50 ns | 10 ns |
| t_SU;STO | 4.0 μs | 0.6 μs | 0.26 μs | 0.16 μs |
| t_BUF | 4.7 μs | 1.3 μs | 0.5 μs | 0.16 μs |

## Clock Domain Considerations
- All internal logic operates in the `clk` domain
- I2C bus signals are asynchronous to the system clock
- Synchronization modules required for crossing clock domains
- Metastability protection for all asynchronous inputs

## Reset Behavior
- Active low reset (`rst_n`) initializes all internal states
- I2C bus lines released to high-impedance during reset
- Configuration registers reset to default values
- Ongoing transactions aborted on reset

## Interrupt Generation
The `irq` signal is asserted for the following events:
- Transmission complete
- Reception complete
- Arbitration loss
- Bus error detection
- Slave address match (in slave mode)

## Power Management
- Low power modes supported through `enable` signal
- Clock gating for unused modules
- Retention of configuration during power down

---

[Back to Index](index.md) | [Next: Module Specifications](module_specs.md)