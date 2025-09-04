# State Machines

## Overview
This document describes the Finite State Machines (FSMs) used in the I2C IP core for both master and slave operations. The FSMs handle protocol timing, error conditions, and data flow control.

## Master Mode FSM

### State Diagram
```
          +-------+
          | IDLE  |
          +-------+
             |
             | start_tx && !busy
             v
          +-------+
          | START |
          +-------+
             |
             | start_done
             v
          +-------+
          | ADDR  |
          +-------+
             |
             | addr_done
             v
    +-------+       +-------+
    | TX    |<------| RX    |
    | DATA  |       | DATA  |
    +-------+       +-------+
       |                |
       | data_done       | data_done
       v                v
    +-------+       +-------+
    | ACK   |       | ACK   |
    | TX    |       | RX    |
    +-------+       +-------+
       |                |
       | ack_done        | ack_done
       v                v
          +-------+
          | STOP  |
          +-------+
             |
             | stop_done
             v
          +-------+
          | IDLE  |
          +-------+
```

### State Descriptions

#### IDLE State
- **Purpose**: Default state, waiting for transmission start
- **Entry Conditions**: Reset or completion of previous transaction
- **Actions**:
  - Monitor `start_tx` signal
  - Clear status flags
  - Prepare internal registers
- **Exit Conditions**: `start_tx` asserted and IP not busy
- **Next State**: START

#### START State
- **Purpose**: Generate START condition on I2C bus
- **Entry Conditions**: Transaction initiated
- **Actions**:
  - Drive SDA low while SCL is high
  - Set timing counters
  - Enable I/O buffers
- **Exit Conditions**: START timing requirements met
- **Next State**: ADDR

#### ADDR State
- **Purpose**: Transmit slave address and R/W bit
- **Entry Conditions**: START condition generated
- **Actions**:
  - Load address from register
  - Shift out address bits
  - Handle ACK from slave
- **Exit Conditions**: Address transmission complete
- **Next State**: TX_DATA or RX_DATA based on R/W bit

#### TX_DATA State
- **Purpose**: Transmit data bytes to slave
- **Entry Conditions**: Address acknowledged
- **Actions**:
  - Load data from register
  - Shift out data bits
  - Receive ACK/NACK
- **Exit Conditions**: Data transmission complete or NACK received
- **Next State**: ACK_TX or STOP

#### RX_DATA State
- **Purpose**: Receive data bytes from slave
- **Entry Conditions**: Address acknowledged
- **Actions**:
  - Shift in data bits
  - Send ACK/NACK
  - Store received data
- **Exit Conditions**: Data reception complete
- **Next State**: ACK_RX or STOP

#### ACK_TX State
- **Purpose**: Handle ACK after transmission
- **Entry Conditions**: Data byte transmitted
- **Actions**:
  - Monitor SDA for ACK
  - Set NACK flag if no ACK
- **Exit Conditions**: ACK timing complete
- **Next State**: TX_DATA (for multi-byte) or STOP

#### ACK_RX State
- **Purpose**: Send ACK after reception
- **Entry Conditions**: Data byte received
- **Actions**:
  - Drive SDA low for ACK
  - Or release SDA for NACK
- **Exit Conditions**: ACK timing complete
- **Next State**: RX_DATA (for multi-byte) or STOP

#### STOP State
- **Purpose**: Generate STOP condition
- **Entry Conditions**: Transaction complete
- **Actions**:
  - Drive SDA high while SCL is high
  - Disable I/O buffers
  - Set completion flags
- **Exit Conditions**: STOP timing requirements met
- **Next State**: IDLE

## Slave Mode FSM

### State Diagram
```
          +-------+
          | IDLE  |
          +-------+
             |
             | start_det && addr_match
             v
          +-------+
          | ACK   |
          | ADDR  |
          +-------+
             |
             | ack_sent
             v
    +-------+       +-------+
    | TX    |<------| RX    |
    | DATA  |       | DATA  |
    +-------+       +-------+
       |                |
       | data_sent       | data_rcvd
       v                v
    +-------+       +-------+
    | WAIT  |       | SEND  |
    | ACK   |       | ACK   |
    +-------+       +-------+
       |                |
       | ack_rcvd        | ack_sent
       v                v
          +-------+
          | IDLE  |
          +-------+
             ^
             |
             | stop_det
```

### State Descriptions

#### IDLE State
- **Purpose**: Monitor bus for address match
- **Entry Conditions**: Reset or STOP condition
- **Actions**:
  - Monitor SDA and SCL for START
  - Compare received address with device address
- **Exit Conditions**: START detected and address matches
- **Next State**: ACK_ADDR

#### ACK_ADDR State
- **Purpose**: Acknowledge received address
- **Entry Conditions**: Address match detected
- **Actions**:
  - Drive SDA low during ACK bit
  - Set address match flag
- **Exit Conditions**: ACK bit complete
- **Next State**: TX_DATA or RX_DATA based on R/W bit

#### TX_DATA State
- **Purpose**: Transmit data to master
- **Entry Conditions**: Address acknowledged, R/W = 1
- **Actions**:
  - Load data from register
  - Shift out data bits
  - Wait for ACK from master
- **Exit Conditions**: Data byte transmitted
- **Next State**: WAIT_ACK

#### RX_DATA State
- **Purpose**: Receive data from master
- **Entry Conditions**: Address acknowledged, R/W = 0
- **Actions**:
  - Shift in data bits
  - Send ACK after each byte
  - Store received data
- **Exit Conditions**: Data byte received
- **Next State**: SEND_ACK

#### WAIT_ACK State
- **Purpose**: Wait for ACK after transmission
- **Entry Conditions**: Data byte transmitted
- **Actions**:
  - Release SDA (high impedance)
  - Monitor SDA for ACK
- **Exit Conditions**: ACK bit complete
- **Next State**: TX_DATA (continue) or IDLE (stop)

#### SEND_ACK State
- **Purpose**: Send ACK after reception
- **Entry Conditions**: Data byte received
- **Actions**:
  - Drive SDA low for ACK
  - Or release for NACK
- **Exit Conditions**: ACK bit complete
- **Next State**: RX_DATA (continue) or IDLE (stop)

## Error Handling States

### Arbitration Lost State
- **Purpose**: Handle multi-master arbitration loss
- **Entry Conditions**: SDA differs from transmitted bit
- **Actions**:
  - Stop transmission
  - Set arbitration lost flag
  - Switch to slave mode
- **Exit Conditions**: Bus free
- **Next State**: IDLE

### Bus Error State
- **Purpose**: Handle illegal bus conditions
- **Entry Conditions**: Invalid START/STOP or SDA change during SCL high
- **Actions**:
  - Set bus error flag
  - Abort current transaction
  - Reset internal state
- **Exit Conditions**: Error cleared
- **Next State**: IDLE

## FSM Implementation Considerations

### State Encoding
- One-hot encoding for speed and debuggability
- Gray code for low power applications
- Binary encoding for area optimization

### Timing Constraints
- State transitions synchronized to system clock
- Minimum state hold times for metastability
- Asynchronous reset for immediate recovery

### Debug Features
- Current state visible in status register
- State transition logging (optional)
- Watchdog timer for stuck state detection

---

[Back to Index](index.md) | [Previous: Module Specifications](module_specs.md) | [Next: Implementation Examples](implementation_examples.md)