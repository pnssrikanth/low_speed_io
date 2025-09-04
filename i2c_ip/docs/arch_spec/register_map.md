# 4. Register Map

## 4.1 Register Overview

The I2C IP core uses a memory-mapped register interface for configuration and control. All registers are 32-bit wide and aligned to 4-byte boundaries. The base address is configurable at instantiation.

### Register Map Summary

| Offset | Register Name | Access | Description |
|--------|---------------|--------|-------------|
| 0x00 | `CTRL` | R/W | Control Register |
| 0x04 | `STATUS` | R | Status Register |
| 0x08 | `INT_EN` | R/W | Interrupt Enable Register |
| 0x0C | `INT_STATUS` | R/W1C | Interrupt Status Register |
| 0x10 | `TIMING` | R/W | Timing Configuration Register |
| 0x14 | `ADDR` | R/W | Slave Address Register |
| 0x18 | `TX_DATA` | W | Transmit Data Register |
| 0x1C | `RX_DATA` | R | Receive Data Register |
| 0x20 | `FIFO_STATUS` | R | FIFO Status Register |
| 0x24 | `FIFO_THRESH` | R/W | FIFO Threshold Register |
| 0x28 | `ERROR` | R | Error Register |
| 0x2C | `DIAG` | R/W | Diagnostic Register |
| 0x30 | `SAFETY` | R/W | Safety Configuration Register |
| 0x34 | `VERSION` | R | Version Register |

## 4.2 Detailed Register Descriptions

### 4.2.1 Control Register (CTRL) - 0x00

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| 31:8 | Reserved | - | 0 | Reserved for future use |
| 7 | SAFETY_EN | R/W | 0 | Enable safety features |
| 6 | DMA_EN | R/W | 0 | Enable DMA interface |
| 5 | HS_MODE | R/W | 0 | High-speed mode enable |
| 4 | FAST_MODE | R/W | 0 | Fast mode enable |
| 3 | SLAVE_EN | R/W | 1 | Enable slave mode |
| 2 | MASTER_EN | R/W | 1 | Enable master mode |
| 1 | SOFT_RST | W | 0 | Software reset (self-clearing) |
| 0 | EN | R/W | 0 | Enable I2C core |

**Usage Example:**
```c
// Enable master mode with fast speed
i2c_write(CTRL, (1 << MASTER_EN) | (1 << FAST_MODE) | (1 << EN));
```

### 4.2.2 Status Register (STATUS) - 0x04

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| 31:10 | Reserved | - | 0 | Reserved |
| 9 | BUS_BUSY | R | 0 | I2C bus busy |
| 8 | ARB_LOST | R | 0 | Arbitration lost |
| 7 | TX_EMPTY | R | 1 | Transmit FIFO empty |
| 6 | TX_FULL | R | 0 | Transmit FIFO full |
| 5 | RX_EMPTY | R | 1 | Receive FIFO empty |
| 4 | RX_FULL | R | 0 | Receive FIFO full |
| 3 | SLAVE_ADDR_MATCH | R | 0 | Slave address matched |
| 2 | TX_DONE | R | 0 | Transmission complete |
| 1 | RX_DONE | R | 0 | Reception complete |
| 0 | READY | R | 1 | Core ready |

### 4.2.3 Interrupt Enable Register (INT_EN) - 0x08

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| 31:8 | Reserved | - | 0 | Reserved |
| 7 | ARB_LOST_EN | R/W | 0 | Arbitration lost interrupt enable |
| 6 | TX_THRESH_EN | R/W | 0 | TX FIFO threshold interrupt enable |
| 5 | RX_THRESH_EN | R/W | 0 | RX FIFO threshold interrupt enable |
| 4 | TX_EMPTY_EN | R/W | 0 | TX FIFO empty interrupt enable |
| 3 | RX_FULL_EN | R/W | 0 | RX FIFO full interrupt enable |
| 2 | SLAVE_ADDR_EN | R/W | 0 | Slave address match interrupt enable |
| 1 | TX_DONE_EN | R/W | 0 | TX done interrupt enable |
| 0 | RX_DONE_EN | R/W | 0 | RX done interrupt enable |

### 4.2.4 Interrupt Status Register (INT_STATUS) - 0x0C

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| 31:8 | Reserved | - | 0 | Reserved |
| 7 | ARB_LOST | R/W1C | 0 | Arbitration lost interrupt |
| 6 | TX_THRESH | R/W1C | 0 | TX FIFO threshold interrupt |
| 5 | RX_THRESH | R/W1C | 0 | RX FIFO threshold interrupt |
| 4 | TX_EMPTY | R/W1C | 0 | TX FIFO empty interrupt |
| 3 | RX_FULL | R/W1C | 0 | RX FIFO full interrupt |
| 2 | SLAVE_ADDR | R/W1C | 0 | Slave address match interrupt |
| 1 | TX_DONE | R/W1C | 0 | TX done interrupt |
| 0 | RX_DONE | R/W1C | 0 | RX done interrupt |

**Note:** Writing 1 to a bit clears the corresponding interrupt.

### 4.2.5 Timing Configuration Register (TIMING) - 0x10

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| 31:16 | SCL_HIGH | R/W | 0x0F | SCL high period (in system clock cycles) |
| 15:0 | SCL_LOW | R/W | 0x0F | SCL low period (in system clock cycles) |

**Timing Calculation:**
- For 100 kHz SCL with 50 MHz system clock:
  - SCL_HIGH = 250 (5 μs)
  - SCL_LOW = 250 (5 μs)

### 4.2.6 Slave Address Register (ADDR) - 0x14

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| 31:11 | Reserved | - | 0 | Reserved |
| 10 | TEN_BIT_EN | R/W | 0 | 10-bit addressing enable |
| 9:0 | SLAVE_ADDR | R/W | 0 | Slave address (7-bit or 10-bit) |

### 4.2.7 Transmit Data Register (TX_DATA) - 0x18

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| 31:8 | Reserved | - | 0 | Reserved |
| 7:0 | TX_DATA | W | 0 | Data byte to transmit |

### 4.2.8 Receive Data Register (RX_DATA) - 0x1C

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| 31:8 | Reserved | - | 0 | Reserved |
| 7:0 | RX_DATA | R | 0 | Received data byte |

### 4.2.9 FIFO Status Register (FIFO_STATUS) - 0x20

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| 31:16 | Reserved | - | 0 | Reserved |
| 15:8 | TX_LEVEL | R | 0 | TX FIFO fill level |
| 7:0 | RX_LEVEL | R | 0 | RX FIFO fill level |

### 4.2.10 FIFO Threshold Register (FIFO_THRESH) - 0x24

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| 31:16 | Reserved | - | 0 | Reserved |
| 15:8 | TX_THRESH | R/W | 8 | TX FIFO threshold |
| 7:0 | RX_THRESH | R/W | 8 | RX FIFO threshold |

### 4.2.11 Error Register (ERROR) - 0x28

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| 31:8 | Reserved | - | 0 | Reserved |
| 7 | ARB_TIMEOUT | R | 0 | Arbitration timeout |
| 6 | SCL_STUCK | R | 0 | SCL stuck at low |
| 5 | SDA_STUCK | R | 0 | SDA stuck at low |
| 4 | ACK_ERROR | R | 0 | No acknowledge received |
| 3 | BUS_ERROR | R | 0 | Bus error detected |
| 2 | CRC_ERROR | R | 0 | CRC error (HS mode) |
| 1 | PARITY_ERROR | R | 0 | Parity error |
| 0 | OVERRUN | R | 0 | FIFO overrun |

### 4.2.12 Diagnostic Register (DIAG) - 0x2C

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| 31:8 | Reserved | - | 0 | Reserved |
| 7 | BIST_EN | R/W | 0 | Built-in self-test enable |
| 6 | BIST_DONE | R | 0 | BIST complete |
| 5 | BIST_PASS | R | 0 | BIST result |
| 4 | LOOPBACK_EN | R/W | 0 | Loopback test enable |
| 3 | SCL_MON | R | 0 | SCL monitor |
| 2 | SDA_MON | R | 0 | SDA monitor |
| 1 | CLK_MON | R | 0 | Clock monitor |
| 0 | PWR_MON | R | 0 | Power monitor |

### 4.2.13 Safety Configuration Register (SAFETY) - 0x30

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| 31:8 | Reserved | - | 0 | Reserved |
| 7 | REDUNDANCY_EN | R/W | 0 | Enable redundant channels |
| 6 | WATCHDOG_EN | R/W | 0 | Enable watchdog timer |
| 5 | CRC_EN | R/W | 0 | Enable CRC checking |
| 4 | PARITY_EN | R/W | 0 | Enable parity checking |
| 3 | LOCKSTEP_EN | R/W | 0 | Enable lockstep operation |
| 2 | ECC_EN | R/W | 0 | Enable error correction |
| 1 | FSM_CHECK_EN | R/W | 0 | Enable FSM checking |
| 0 | SAFETY_MODE | R/W | 0 | Safety mode enable |

### 4.2.14 Version Register (VERSION) - 0x34

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| 31:24 | MAJOR | R | 1 | Major version number |
| 23:16 | MINOR | R | 0 | Minor version number |
| 15:8 | PATCH | R | 0 | Patch version number |
| 7:0 | REV | R | 0 | Revision number |

## 4.3 Register Access Patterns

### 4.3.1 Initialization Sequence

```c
// 1. Reset the core
i2c_write(CTRL, (1 << SOFT_RST));

// 2. Configure timing
i2c_write(TIMING, (SCL_HIGH << 16) | SCL_LOW);

// 3. Set slave address (if slave mode)
i2c_write(ADDR, SLAVE_ADDRESS);

// 4. Configure interrupts
i2c_write(INT_EN, INTERRUPT_MASK);

// 5. Enable the core
i2c_write(CTRL, (1 << EN) | MODE_CONFIG);
```

### 4.3.2 Data Transmission

```c
// Check if TX FIFO has space
if (!(i2c_read(FIFO_STATUS) & TX_FULL)) {
    i2c_write(TX_DATA, data_byte);
}
```

### 4.3.3 Data Reception

```c
// Check if RX FIFO has data
if (!(i2c_read(FIFO_STATUS) & RX_EMPTY)) {
    data_byte = i2c_read(RX_DATA);
}
```

---

[Previous: Interfaces](./interfaces.md) | [Next: Micro-Architecture](./micro_architecture.md)