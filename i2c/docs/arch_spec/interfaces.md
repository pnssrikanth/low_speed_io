# 3. Interfaces

## 3.1 External Interfaces

### 3.1.1 I2C Bus Interface

The I2C bus interface consists of two signals: Serial Clock (SCL) and Serial Data (SDA). These are bidirectional signals that require external pull-up resistors.

| Signal | Direction | Description |
|--------|-----------|-------------|
| `scl` | Bidirectional | I2C serial clock line |
| `sda` | Bidirectional | I2C serial data line |

**Note**: I/O buffers are not part of the IP core and must be provided by the integrating system.

#### Signal Characteristics
- **Voltage Levels**: CMOS/TTL compatible
- **Drive Strength**: Configurable through external buffers
- **Pull-up Requirements**: 1kΩ to 10kΩ resistors to VDD

### 3.1.2 Timing Requirements

| Parameter | Min | Typ | Max | Unit |
|-----------|-----|-----|-----|------|
| SCL Frequency (Standard) | - | 100 | - | kHz |
| SCL Frequency (Fast) | - | 400 | - | kHz |
| SCL Frequency (Fast+) | - | 1000 | - | kHz |
| SCL Frequency (High Speed) | - | 3400 | - | kHz |
| Bus Free Time | 4.7 | - | - | μs |
| Start Hold Time | 4.0 | - | - | μs |
| Data Hold Time | 0 | - | 3.45 | μs |
| Data Setup Time | 250 | - | - | ns |

## 3.2 Internal Interfaces

### 3.2.1 APB Interface

The IP core supports the ARM AMBA 3 APB protocol for register access.

| Signal | Direction | Description |
|--------|-----------|-------------|
| `pclk` | Input | APB clock |
| `presetn` | Input | APB reset (active low) |
| `paddr[31:0]` | Input | APB address bus |
| `psel` | Input | APB select |
| `penable` | Input | APB enable |
| `pwrite` | Input | APB write enable |
| `pwdata[31:0]` | Input | APB write data |
| `prdata[31:0]` | Output | APB read data |
| `pready` | Output | APB ready |
| `pslverr` | Output | APB slave error |

### 3.2.2 AHB-Lite Interface

For high-performance applications, the IP supports AHB-Lite protocol.

| Signal | Direction | Description |
|--------|-----------|-------------|
| `hclk` | Input | AHB clock |
| `hresetn` | Input | AHB reset (active low) |
| `haddr[31:0]` | Input | AHB address bus |
| `hsel` | Input | AHB select |
| `hwrite` | Input | AHB write enable |
| `hsize[2:0]` | Input | AHB transfer size |
| `hburst[2:0]` | Input | AHB burst type |
| `hprot[3:0]` | Input | AHB protection |
| `htrans[1:0]` | Input | AHB transfer type |
| `hwdata[31:0]` | Input | AHB write data |
| `hrdata[31:0]` | Output | AHB read data |
| `hready` | Output | AHB ready |
| `hresp[1:0]` | Output | AHB response |

### 3.2.3 Interrupt Interface

| Signal | Direction | Description |
|--------|-----------|-------------|
| `irq` | Output | Combined interrupt signal |
| `irq_tx` | Output | Transmit interrupt |
| `irq_rx` | Output | Receive interrupt |
| `irq_error` | Output | Error interrupt |

### 3.2.4 DMA Interface (Optional)

For high-throughput applications, a DMA interface is available.

| Signal | Direction | Description |
|--------|-----------|-------------|
| `dma_req` | Output | DMA request |
| `dma_ack` | Input | DMA acknowledge |
| `dma_addr[31:0]` | Output | DMA address |
| `dma_data[31:0]` | Bidirectional | DMA data |
| `dma_we` | Output | DMA write enable |

## 3.3 Clock and Reset

### 3.3.1 Clock Signals

| Signal | Description |
|--------|-------------|
| `pclk` / `hclk` | System clock for bus interface |
| `i2c_clk` | Dedicated I2C clock (optional) |

### 3.3.2 Reset Signals

| Signal | Description |
|--------|-------------|
| `presetn` / `hresetn` | System reset (active low) |
| `i2c_rst` | I2C-specific reset (optional) |

## 3.4 Configuration Interface

### 3.4.1 Parameter Configuration

The IP core is configured through Verilog parameters at synthesis time.

```verilog
module i2c_ip_core #(
    parameter DATA_WIDTH = 32,      // Bus data width
    parameter FIFO_DEPTH = 16,      // TX/RX FIFO depth
    parameter MODE = "DUAL",        // "MASTER", "SLAVE", or "DUAL"
    parameter SAFETY_EN = 1,        // Enable safety features
    parameter INT_COUNT = 3         // Number of interrupt lines
)(
    // Port declarations
);
```

### 3.4.2 Runtime Configuration

Runtime configuration is performed through register writes.

| Register | Description |
|----------|-------------|
| `CTRL` | Control register for mode selection |
| `TIMING` | Timing configuration register |
| `ADDR` | Slave address register |
| `FIFO_THRESH` | FIFO threshold register |

## 3.5 Test and Debug Interface

### 3.5.1 JTAG Interface (Optional)

For debugging and testing, a JTAG interface is available.

| Signal | Description |
|--------|-------------|
| `tck` | Test clock |
| `tms` | Test mode select |
| `tdi` | Test data in |
| `tdo` | Test data out |
| `trst` | Test reset |

### 3.5.2 Built-in Self-Test (BIST)

The IP includes BIST circuitry for manufacturing test.

| Signal | Description |
|--------|-------------|
| `bist_en` | BIST enable |
| `bist_done` | BIST completion |
| `bist_pass` | BIST result |

---

[Previous: Architecture Overview](./architecture_overview.md) | [Next: Register Map](./register_map.md)