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
- Synchronization with APB clock (PCLK)
- Duty cycle control

**Parameters**:
- `CLK_DIV`: Clock divider ratio (default: 100 for 100kHz at 10MHz sys clk)
- `STRETCH_EN`: Enable clock stretching (default: 1)

**Interface**:
- Input: `i_sys_clk` (PCLK), `i_rst_n` (PRESETn), `i_enable`, `i_stretch_req`
- Output: `o_scl_out`, `o_scl_oe`, `o_timing_valid`

### 2. Register Bank
**Purpose**: Stores configuration, status, and data registers with APB interface.

**APB Interface Features**:
- AMBA APB slave implementation
- 32-bit address and data buses
- Single-cycle register access
- Address validation and error reporting
- Register map spanning 0x00-0x14 address range

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

**Interface**:
- Input: `i_sys_clk` (PCLK), `i_rst_n` (PRESETn), control signals from register bank
- Output: Control signals to shift register, clock manager, and I2C bus

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

**Interface**:
- Input: `i_sys_clk` (PCLK), `i_rst_n` (PRESETn), control signals from FSM
- Output: Serial data to I2C bus, parallel data to register bank

### 5. I/O Buffer Interface (External)
**Purpose**: Provides control signals for external I2C bus IO buffers managed by SoC integration.

**Features** (Required from External IO Buffer):
- Open-drain output drivers for SDA and SCL
- Input synchronization and metastability protection
- Glitch filtering on inputs
- Bus contention detection
- Programmable drive strength
- ESD protection

**Control Signals Provided by IP**:
- `sda_out`: Data output to buffer
- `sda_oe`: Output enable for SDA
- `scl_out`: Clock output to buffer
- `scl_oe`: Output enable for SCL
- `sda_in`: Data input from buffer
- `scl_in`: Clock input from buffer

**Expected IO Buffer Parameters**:
- `DRIVE_STRENGTH`: Output drive strength (default: 4mA)
- `FILTER_EN`: Input filtering enable (default: 1)
- `FILTER_LEN`: Filter length in clock cycles (default: 3)
- `PULLUP_EN`: Internal pull-up enable (default: 1)

### 6. SMBus PEC (Packet Error Checking) Module
**Purpose**: Implements SMBus Packet Error Checking for data integrity in SMBus transactions.

**Key Features**:
- CRC-8 calculation using polynomial x^8 + x^2 + x + 1
- Automatic PEC byte insertion/removal
- PEC validation on received data
- Error reporting for PEC mismatches

**Parameters**:
- `PEC_EN`: Enable PEC functionality (default: 0 for I2C, 1 for SMBus)
- `PEC_POLY`: CRC polynomial (default: 8'h07)

**Interface**:
- Input: `pec_data_in`, `pec_valid`, `pec_start`
- Output: `pec_byte`, `pec_error`, `pec_done`

**Operation**:
1. PEC calculation starts with slave address
2. All transmitted/received data bytes included in CRC
3. PEC byte automatically appended to transmit data
4. Received PEC byte validated against calculated CRC
5. Error flag set on PEC mismatch

**Integration**:
- PEC module interfaces with Shift Register for data streaming
- Control FSM manages PEC enable/disable per transaction
- Status register includes PEC error bit

### 7. Power Management Module
**Purpose**: Manages low-power states and clock gating to reduce power consumption.

**Power States**:
- **ACTIVE**: Full operation, all clocks running
- **IDLE**: Core idle, clocks gated, registers retain state
- **SLEEP**: Deep sleep, minimal power, state preserved
- **OFF**: Power off, state lost (requires re-initialization)

**State Transitions**:
```
ACTIVE → IDLE: Auto-transition after inactivity timeout
IDLE → ACTIVE: On bus activity or register access
ACTIVE/IDLE → SLEEP: Software command or external signal
SLEEP → ACTIVE: Wake-up interrupt or bus activity
SLEEP/OFF → OFF: Power control signal
OFF → ACTIVE: Power-on reset sequence
```

**Clock Gating**:
- Individual module clock gating based on activity
- Clock Manager gates SCL generation when idle
- Register Bank clocks gated during sleep
- Control FSM clock gated when not processing

**Wake-up Sources**:
- Bus activity detection (START condition)
- External wake-up interrupt
- Software register access
- Timer-based wake-up

**Power Control Interface**:
- Input: `power_state_req`, `wake_up_en`
- Output: `power_state_ack`, `wake_up_event`

**Parameters**:
- `IDLE_TIMEOUT`: Inactivity timeout for auto-idle (default: 1000 cycles)
- `SLEEP_EN`: Enable sleep mode (default: 1)
- `WAKE_ON_BUS`: Wake on bus activity (default: 1)

### 8. Debug and Test Interface Module
**Purpose**: Provides debug access and test capabilities for development and production testing.

**JTAG Interface**:
- IEEE 1149.1 compliant TAP controller
- Boundary scan chain for IO pins
- Internal scan chains for registers and FSM
- Debug register access through JTAG

**JTAG Signals**:
- `TCK`: Test clock
- `TMS`: Test mode select
- `TDI`: Test data in
- `TDO`: Test data out
- `TRST`: Test reset (optional)

**Debug Features**:
- **Register Override**: Force register values for testing
- **Signal Probing**: Access internal signals through debug registers
- **Breakpoint on Events**: Halt on specific bus conditions
- **Transaction Logging**: Capture bus transactions to debug memory
- **Error Injection**: Force errors for fault testing

**Debug Registers** (Address range 0x100-0x1FF):
| Address | Name | Access | Description |
|---------|------|--------|-------------|
| 0x100 | DBG_CTRL | RW | Debug control register |
| 0x104 | DBG_STATUS | RO | Debug status |
| 0x108 | DBG_DATA | RW | Debug data access |
| 0x10C | DBG_BREAK | RW | Breakpoint configuration |
| 0x110 | DBG_LOG | RO | Transaction log |

**Test Modes**:
- **Scan Test**: Full scan chain testing
- **BIST**: Built-in self-test for memories and logic
- **Loopback Test**: Internal loopback for IO testing
- **Speed Test**: Automated speed verification

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
1. External data → Register Bank → Shift Register → IP outputs (sda_out, sda_oe) → External IO Buffer → SDA
2. SDA → External IO Buffer → IP inputs (sda_in, scl_in) → Shift Register → Register Bank → External data

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