# Interface Details

## Overview
This document describes the external interfaces of the I2C IP core, including AMBA APB bus interface, I2C bus signals, and timing diagrams. The IP core implements a fully compliant AMBA APB (Advanced Peripheral Bus) slave interface for register access and supports both master and slave I2C modes with configurable I/O standards. I2C bus IO buffers are external to the IP core and handled by SoC integration, with the IP providing control signals for buffer management.

## AMBA APB Interface

### APB Slave Signals
The IP core implements a standard AMBA APB slave interface for register access and configuration.

| Signal | Direction | Description | Width |
|--------|-----------|-------------|-------|
| `PCLK` | Input | APB Clock | 1 |
| `PRESETn` | Input | APB Reset (active low) | 1 |
| `PADDR[31:0]` | Input | APB Address Bus | 32 |
| `PSEL` | Input | APB Select | 1 |
| `PENABLE` | Input | APB Enable | 1 |
| `PWRITE` | Input | APB Write Enable | 1 |
| `PWDATA[31:0]` | Input | APB Write Data | 32 |
| `PRDATA[31:0]` | Output | APB Read Data | 32 |
| `PREADY` | Output | APB Ready | 1 |
| `PSLVERR` | Output | APB Slave Error | 1 |

### APB Protocol Implementation
- **Transfer Types**: Supports both read and write transfers
- **Address Space**: 32-bit address space with register mapping in lower 8 bits
- **Timing**: Single-cycle register access (PREADY always asserted for immediate response)
- **Error Handling**: PSLVERR asserted for invalid register addresses
- **Byte Enable**: Not implemented (32-bit word transfers only)

### APB Transfer Sequence
```
1. SETUP Phase: PSEL=1, PENABLE=0, PADDR/PWRITE/PWDATA valid
2. ACCESS Phase: PSEL=1, PENABLE=1, transfer completes
3. PREADY=1 indicates transfer completion
4. PSLVERR=1 indicates address error
```

## I2C Bus Interface

### I2C Bus Signals (External IO Buffer Interface)
| Signal | Direction | Description | Width |
|--------|-----------|-------------|-------|
| `scl_out` | Output | Serial Clock Output to IO Buffer | 1 |
| `scl_oe` | Output | Serial Clock Output Enable | 1 |
| `scl_in` | Input | Serial Clock Input from IO Buffer | 1 |
| `sda_out` | Output | Serial Data Output to IO Buffer | 1 |
| `sda_oe` | Output | Serial Data Output Enable | 1 |
| `sda_in` | Input | Serial Data Input from IO Buffer | 1 |

### Interrupt Interface
| Signal | Direction | Description | Width |
|--------|-----------|-------------|-------|
| `o_irq` | Output | Interrupt Request | 1 |

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
- All internal logic operates in the `PCLK` domain
- I2C bus signals are asynchronous to the APB clock
- Synchronization modules required for crossing clock domains
- Metastability protection for all asynchronous inputs

## Reset Behavior
- Active low reset (`PRESETn`) initializes all internal states
- I2C bus lines released to high-impedance during reset
- Configuration registers reset to default values
- Ongoing transactions aborted on reset
- APB interface responds with PREADY=1 and PSLVERR=0 during reset

## Register Map and APB Address Space

### Register Address Mapping
All registers are accessible through the APB interface using 32-bit addressing. The register map uses the lower 8 bits of the address space.

| APB Address | Register | Access | Description |
|-------------|----------|--------|-------------|
| 0x00000000 | CTRL | RW | Control Register |
| 0x00000004 | STATUS | RO | Status Register |
| 0x00000008 | DATA | RW | Data Register |
| 0x0000000C | ADDR | RW | Address Register |
| 0x00000010 | CONFIG | RW | Configuration Register |
| 0x00000014 | TIMING | RW | Timing Register |

### Register Access Rules
- **Read Access**: PWRITE=0, valid data returned on PRDATA
- **Write Access**: PWRITE=1, data from PWDATA written to register
- **Invalid Addresses**: PSLVERR=1 for addresses outside 0x00-0x14 range
- **Access Time**: Single-cycle (PREADY=1 always for immediate response)

## Interrupt Generation
The `o_irq` signal is asserted for the following events:
- Transmission complete
- Reception complete
- Arbitration loss
- Bus error detection
- Slave address match (in slave mode)

### Interrupt Configuration
Interrupt behavior is controlled through the CTRL register:
- **Interrupt Enable**: Bit 6 of CTRL register enables/disables interrupts
- **Status Flags**: STATUS register contains individual interrupt flags
- **Clear on Read**: Status flags are cleared when STATUS register is read

### Interrupt Sources
| Interrupt Source | Status Bit | Description |
|------------------|------------|-------------|
| Transmission Complete | STATUS[0] | TX operation finished |
| Reception Complete | STATUS[1] | RX operation finished |
| Arbitration Lost | STATUS[2] | Multi-master arbitration failure |
| NACK Received | STATUS[3] | Slave sent NACK |
| Bus Error | STATUS[4] | I2C bus error detected |
| Start Detected | STATUS[5] | START condition detected |
| Stop Detected | STATUS[6] | STOP condition detected |

## Power Management
- Low power modes controlled through CTRL register (bit 0: ENABLE)
- Clock gating for unused modules when ENABLE=0
- Retention of configuration during power down
- APB interface remains accessible in all power states
- I2C bus lines released to high-impedance when disabled

## APB Integration Guidelines

### SoC Integration
- Connect PCLK to system APB clock
- Connect PRESETn to system reset (active low)
- PADDR[31:0] supports full 32-bit address decoding
- PREADY always asserted (single-cycle access)
- PSLVERR indicates invalid register access

### APB Master Requirements
- Support for 32-bit address and data buses
- Handle PREADY and PSLVERR signals
- Single transfer per access (no burst support)

### Timing Considerations
- APB transfers complete in single clock cycle
- No wait states required (PREADY=1)
- Setup time: PSEL/PENABLE before data valid
- Hold time: Signals stable until PREADY asserted

---

[Back to Index](index.md) | [Next: Module Specifications](module_specs.md)