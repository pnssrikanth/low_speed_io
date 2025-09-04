# Module Specifications

## Overview
This document details the internal modules of the I2C IP core, their interconnections, and configuration options. The modular design allows for easy customization and scalability across different SoC implementations.

## Top-Level Architecture

```
+-------------------+
|   I2C Controller  |
+-------------------+
| +---------------+ |
| | Clock Manager | |
| +---------------+ |
| +---------------+ |
| |   Registers   | |
| +---------------+ |
| +---------------+ |
| | Control FSM   | |
| +---------------+ |
| +---------------+ |
| |  Shift Reg    | |
| +---------------+ |
| +---------------+ |
| |  I/O Buffer   | |
| +---------------+ |
+-------------------+
```

## Internal Modules

### 1. Clock Manager Module
**Purpose**: Generates I2C clock signals and manages timing constraints.

**Key Features**:
- Configurable SCL frequency generation
- Clock stretching support
- Synchronization with system clock
- Duty cycle control

**Parameters**:
- `CLK_DIV`: Clock divider ratio (default: 100 for 100kHz at 10MHz sys clk)
- `STRETCH_EN`: Enable clock stretching (default: 1)

**Interface**:
- Input: `sys_clk`, `enable`, `stretch_req`
- Output: `scl_out`, `scl_oe`, `timing_valid`

### 2. Register Bank
**Purpose**: Stores configuration, status, and data registers.

**Register Map**:
| Address | Name | Access | Description |
|---------|------|--------|-------------|
| 0x00 | CTRL | RW | Control Register |
| 0x04 | STATUS | RO | Status Register |
| 0x08 | DATA | RW | Data Register |
| 0x0C | ADDR | RW | Address Register |
| 0x10 | CONFIG | RW | Configuration Register |
| 0x14 | TIMING | RW | Timing Parameters |

**Control Register (CTRL)**:
- Bit 0: ENABLE - IP enable
- Bit 1: START - Start transmission
- Bit 2: STOP - Stop transmission
- Bit 3: ACK_EN - ACK enable
- Bit 4-5: MODE - Operation mode (00: Idle, 01: Master TX, 10: Master RX, 11: Slave)
- Bit 6: INT_EN - Interrupt enable
- Bit 7: RST - Software reset

**Status Register (STATUS)**:
- Bit 0: BUSY - IP busy
- Bit 1: TX_DONE - Transmission complete
- Bit 2: RX_DONE - Reception complete
- Bit 3: ARB_LOST - Arbitration lost
- Bit 4: NACK - NACK received
- Bit 5: BUS_ERR - Bus error
- Bit 6: START_DET - START condition detected
- Bit 7: STOP_DET - STOP condition detected

### 3. Control FSM Module
**Purpose**: Manages the overall operation flow and state transitions.

**States** (Master Mode)**:
- IDLE: Waiting for start command
- START: Generating START condition
- ADDR: Sending slave address
- TX_DATA: Transmitting data
- RX_DATA: Receiving data
- ACK: Handling ACK/NACK
- STOP: Generating STOP condition
- ARB_LOST: Arbitration lost recovery

**States** (Slave Mode)**:
- IDLE: Waiting for address match
- ADDR_MATCH: Address received and matched
- TX_DATA: Transmitting data to master
- RX_DATA: Receiving data from master
- ACK_TX: Sending ACK after receive
- ACK_RX: Receiving ACK after transmit

**Configurability**:
- Custom state additions for specific protocols
- Interrupt generation on state transitions

### 4. Shift Register Module
**Purpose**: Serial-to-parallel and parallel-to-serial data conversion.

**Features**:
- 8-bit data shifting
- LSB-first or MSB-first configuration
- Automatic ACK bit handling
- Data validation and error detection

**Parameters**:
- `DATA_WIDTH`: Data width (default: 8)
- `SHIFT_DIR`: Shift direction (0: LSB first, 1: MSB first)

### 5. I/O Buffer Module
**Purpose**: Manages bidirectional I2C bus signals with proper drive strength.

**Features**:
- Open-drain output drivers
- Input synchronization
- Glitch filtering
- Bus contention detection

**Parameters**:
- `DRIVE_STRENGTH`: Output drive strength (default: 4mA)
- `FILTER_EN`: Input filtering enable (default: 1)
- `FILTER_LEN`: Filter length in clock cycles (default: 3)

## Configurability Options

### Speed Mode Configuration
```verilog
parameter SPEED_MODE = 2'b00; // 00: Standard, 01: Fast, 10: Fast+, 11: HS
```

### Addressing Mode
```verilog
parameter ADDR_MODE = 1'b0; // 0: 7-bit, 1: 10-bit
```

### Multi-Master Support
```verilog
parameter MULTI_MASTER = 1'b1; // Enable multi-master arbitration
```

### Safety Features
```verilog
parameter SAFETY_EN = 1'b1; // Enable safety mechanisms
parameter WATCHDOG_EN = 1'b1; // Enable watchdog timer
```

### Power Management
```verilog
parameter LOW_POWER_EN = 1'b1; // Enable low power modes
parameter CLK_GATE_EN = 1'b1; // Enable clock gating
```

## Module Interconnections

### Data Flow
1. External data → Register Bank → Shift Register → I/O Buffer → SDA
2. SDA → I/O Buffer → Shift Register → Register Bank → External data

### Control Flow
1. Control signals → Register Bank → Control FSM
2. Control FSM → Clock Manager → SCL generation
3. Control FSM → Shift Register → Data shifting control
4. Status signals → Register Bank → External status

## Synthesis Considerations
- All modules designed for synthesis with standard cells
- Pipelining for high-speed modes
- Area vs. speed trade-offs configurable
- Clock domain crossing handled with synchronizers

## Testability Features
- Scan chain insertion points
- Built-in self-test (BIST) for key modules
- Debug registers for internal signal visibility

---

[Back to Index](index.md) | [Previous: Interface Details](interface_details.md) | [Next: State Machines](state_machines.md)