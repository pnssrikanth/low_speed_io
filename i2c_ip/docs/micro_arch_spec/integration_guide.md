# Integration Guide

## Overview
This document provides guidance for integrating the I2C IP core into SoC designs, including software driver development, hardware integration, and board-level considerations.

## SoC Integration

### Top-Level Integration
```verilog
module soc_top (
    // System signals
    input wire sys_clk,
    input wire sys_rst_n,

    // I2C interface (external IO buffer)
    input wire i2c_scl_in,
    input wire i2c_sda_in,
    output wire i2c_scl_out,
    output wire i2c_scl_oe,
    output wire i2c_sda_out,
    output wire i2c_sda_oe,

    // APB interface (example)
    input wire apb_pclk,
    input wire apb_presetn,
    input wire [31:0] apb_paddr,
    input wire apb_pwrite,
    input wire [31:0] apb_pwdata,
    input wire apb_psel,
    input wire apb_penable,
    output wire [31:0] apb_prdata,
    output wire apb_pready,
    output wire apb_pslverr,

    // Interrupts
    output wire i2c_irq,

    // Other SoC signals...
);

    // I2C IP instantiation
    i2c_master i2c_inst (
        .clk(sys_clk),
        .rst_n(sys_rst_n),
        .scl_in(i2c_scl_in),
        .scl_out(i2c_scl_out),
        .scl_oe(i2c_scl_oe),
        .sda_in(i2c_sda_in),
        .sda_out(i2c_sda_out),
        .sda_oe(i2c_sda_oe),
        .irq(i2c_irq),
        // ... other connections
    );

    // APB bridge to I2C registers
    apb_to_i2c_bridge bridge_inst (
        .apb_pclk(apb_pclk),
        .apb_presetn(apb_presetn),
        .apb_paddr(apb_paddr[7:0]), // 256-byte address space
        .apb_pwrite(apb_pwrite),
        .apb_pwdata(apb_pwdata),
        .apb_psel(apb_psel),
        .apb_penable(apb_penable),
        .apb_prdata(apb_prdata),
        .apb_pready(apb_pready),
        .apb_pslverr(apb_pslverr),
        // I2C register interface
        .i2c_reg_addr(i2c_reg_addr),
        .i2c_reg_write(i2c_reg_write),
        .i2c_reg_wdata(i2c_reg_wdata),
        .i2c_reg_rdata(i2c_reg_rdata)
    );

endmodule
```

### Clock Domain Considerations
- **System Clock**: 50-200 MHz for control logic
- **I2C Clock**: Derived from system clock (100 kHz - 3.4 MHz)
- **APB Clock**: Same as system clock or asynchronous
- **CDC Handling**: Synchronizers for cross-domain signals

### Power Management Integration
```verilog
module power_control (
    input wire power_en,
    input wire i2c_active,
    output wire i2c_power_ok,
    output wire i2c_isolation_en
);

    reg power_state;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            power_state <= 1'b0;
        end else begin
            power_state <= power_en && i2c_active;
        end
    end

    assign i2c_power_ok = power_state;
    assign i2c_isolation_en = !power_state;

endmodule
```

### IO Buffer Integration
The I2C IP core requires external IO buffers for proper I2C bus operation. The SoC integration layer must provide these buffers with the following interface:

#### Required IO Buffer Signals
```verilog
module i2c_io_buffer (
    // From I2C IP
    input wire sda_out,      // Data output from IP
    input wire sda_oe,       // Output enable for SDA
    input wire scl_out,      // Clock output from IP
    input wire scl_oe,       // Output enable for SCL

    // To I2C IP
    output wire sda_in,      // Data input to IP
    output wire scl_in,      // Clock input to IP

    // External I2C bus
    inout wire sda_pad,      // Physical SDA pin
    inout wire scl_pad       // Physical SCL pin
);
```

#### IO Buffer Implementation Requirements
```verilog
module i2c_io_buffer_impl (
    input wire sda_out,
    input wire sda_oe,
    input wire scl_out,
    input wire scl_oe,
    output wire sda_in,
    output wire scl_in,
    inout wire sda_pad,
    inout wire scl_pad
);

    // SDA Buffer
    assign sda_pad = sda_oe ? sda_out : 1'bz;
    assign sda_in = sda_pad;

    // SCL Buffer
    assign scl_pad = scl_oe ? scl_out : 1'bz;
    assign scl_in = scl_pad;

endmodule
```

#### IO Buffer Features Required
- **Open-Drain Outputs**: Both SDA and SCL must use open-drain drivers
- **Input Synchronization**: Metastability protection for asynchronous inputs
- **Glitch Filtering**: Noise filtering on SDA and SCL inputs
- **Drive Strength Control**: Configurable output drive strength (4mA typical)
- **Pull-up Resistors**: Internal or external pull-ups to VDD
- **ESD Protection**: ±8kV HBM protection minimum
- **Bus Contention Detection**: Optional, for multi-master scenarios

#### IO Buffer Configuration Parameters
| Parameter | Typical Value | Description |
|-----------|---------------|-------------|
| Drive Strength | 4mA | Output current capability |
| Pull-up Resistance | 4.7kΩ | External pull-up value |
| Filter Time | 50ns | Input glitch filter time |
| ESD Rating | ±8kV | ESD protection level |

#### Signal Usage Guidelines
- **sda_oe/scl_oe**: Active high enables output drivers
- **sda_out/scl_out**: Data/clock values when output enabled
- **sda_in/scl_in**: Must be synchronized to system clock domain
- **High-Impedance**: When oe=0, outputs go to high-impedance
- **Pull-up Dependency**: External pull-ups required for proper I2C operation

## Register Interface

### APB Register Map
| Address Offset | Register Name | Access | Description |
|----------------|---------------|--------|-------------|
| 0x00 | CTRL | RW | Control Register |
| 0x04 | STATUS | RO | Status Register |
| 0x08 | DATA | RW | Data Register |
| 0x0C | ADDR | RW | Address Register |
| 0x10 | CONFIG | RW | Configuration Register |
| 0x14 | TIMING | RW | Timing Parameters |
| 0x18 | INT_EN | RW | Interrupt Enable |
| 0x1C | INT_STATUS | RO | Interrupt Status |
| 0x20 | FIFO_CTRL | RW | FIFO Control |
| 0x24 | FIFO_STATUS | RO | FIFO Status |
| 0x28 | ERROR_STATUS | RO | Error Status |
| 0x2C | DEBUG | RW | Debug Register |

### Register Descriptions

#### Control Register (CTRL) - 0x00
```c
typedef union {
    struct {
        uint32_t enable      : 1;  // Bit 0: IP enable
        uint32_t start       : 1;  // Bit 1: Start transmission
        uint32_t stop        : 1;  // Bit 2: Stop transmission
        uint32_t ack_en      : 1;  // Bit 3: ACK enable
        uint32_t mode        : 2;  // Bits 4-5: Operation mode
        uint32_t speed_mode  : 2;  // Bits 6-7: Speed mode
        uint32_t reserved    : 24; // Bits 8-31: Reserved
    } fields;
    uint32_t value;
} i2c_ctrl_reg_t;
```

#### Status Register (STATUS) - 0x04
```c
typedef union {
    struct {
        uint32_t busy        : 1;  // Bit 0: IP busy
        uint32_t tx_done     : 1;  // Bit 1: Transmission complete
        uint32_t rx_done     : 1;  // Bit 2: Reception complete
        uint32_t arb_lost    : 1;  // Bit 3: Arbitration lost
        uint32_t nack        : 1;  // Bit 4: NACK received
        uint32_t bus_error   : 1;  // Bit 5: Bus error
        uint32_t fifo_full   : 1;  // Bit 6: TX FIFO full
        uint32_t fifo_empty  : 1;  // Bit 7: RX FIFO empty
        uint32_t reserved    : 24; // Bits 8-31: Reserved
    } fields;
    uint32_t value;
} i2c_status_reg_t;
```

## Software Driver Development

### C Driver Structure
```c
#include <stdint.h>
#include <stdbool.h>

#define I2C_BASE_ADDR 0x40005000

typedef struct {
    volatile uint32_t CTRL;
    volatile uint32_t STATUS;
    volatile uint32_t DATA;
    volatile uint32_t ADDR;
    volatile uint32_t CONFIG;
    volatile uint32_t TIMING;
    volatile uint32_t INT_EN;
    volatile uint32_t INT_STATUS;
} i2c_regs_t;

#define I2C ((i2c_regs_t *)I2C_BASE_ADDR)

// Driver functions
void i2c_init(uint32_t speed_mode);
bool i2c_write(uint8_t slave_addr, uint8_t *data, uint32_t len);
bool i2c_read(uint8_t slave_addr, uint8_t *data, uint32_t len);
void i2c_set_speed(uint32_t speed_hz);
uint32_t i2c_get_status(void);
```

### Initialization Function
```c
void i2c_init(uint32_t speed_mode) {
    // Reset I2C IP
    I2C->CTRL = 0;

    // Configure speed mode
    I2C->CONFIG = speed_mode;

    // Set timing parameters based on speed
    switch (speed_mode) {
        case I2C_SPEED_STANDARD:
            I2C->TIMING = 0x00000064; // 100 kHz timing
            break;
        case I2C_SPEED_FAST:
            I2C->TIMING = 0x00000019; // 400 kHz timing
            break;
        case I2C_SPEED_FAST_PLUS:
            I2C->TIMING = 0x0000000A; // 1 MHz timing
            break;
    }

    // Enable interrupts
    I2C->INT_EN = I2C_INT_TX_DONE | I2C_INT_RX_DONE | I2C_INT_ERROR;

    // Enable I2C IP
    I2C->CTRL |= I2C_CTRL_ENABLE;
}
```

### Write Transaction
```c
bool i2c_write(uint8_t slave_addr, uint8_t *data, uint32_t len) {
    uint32_t timeout = I2C_TIMEOUT;

    // Set slave address
    I2C->ADDR = slave_addr & 0x7F;

    // Start transmission
    I2C->CTRL |= I2C_CTRL_START;

    for (uint32_t i = 0; i < len; i++) {
        // Wait for TX ready
        while ((I2C->STATUS & I2C_STATUS_TX_READY) == 0) {
            if (--timeout == 0) return false;
        }

        // Write data
        I2C->DATA = data[i];
    }

    // Wait for transmission complete
    timeout = I2C_TIMEOUT;
    while ((I2C->STATUS & I2C_STATUS_TX_DONE) == 0) {
        if (--timeout == 0) return false;
    }

    return true;
}
```

### Interrupt Handler
```c
void I2C_IRQHandler(void) {
    uint32_t int_status = I2C->INT_STATUS;

    if (int_status & I2C_INT_TX_DONE) {
        // Transmission complete
        tx_complete_callback();
    }

    if (int_status & I2C_INT_RX_DONE) {
        // Reception complete
        rx_complete_callback();
    }

    if (int_status & I2C_INT_ERROR) {
        // Error occurred
        error_callback();
    }

    // Clear interrupts
    I2C->INT_STATUS = int_status;
}
```

## Board Design Considerations

### I2C Bus Routing
- **Trace Length**: Keep SCL/SDA traces equal length (< 30 cm)
- **Impedance**: 50-100 ohm characteristic impedance
- **Coupling**: Minimize capacitive coupling between traces
- **Termination**: Pull-up resistors at bus master end

### Pull-up Resistor Selection
| Speed Mode | Pull-up Value | Bus Capacitance |
|------------|---------------|-----------------|
| Standard | 4.7 kΩ | < 400 pF |
| Fast | 1 kΩ - 4.7 kΩ | < 400 pF |
| Fast Plus | 470 Ω - 2 kΩ | < 200 pF |
| High Speed | 470 Ω - 2 kΩ | < 100 pF |

### Power Supply Filtering
```verilog
// Power supply decoupling
module power_filter (
    input wire vdd_in,
    output wire vdd_out
);

    // Decoupling capacitors (external)
    // 10uF bulk capacitor
    // 0.1uF ceramic capacitor per IC

endmodule
```

### ESD Protection
- **ESD Diodes**: Bidirectional TVS diodes on SCL/SDA lines
- **Protection Level**: ±8 kV contact, ±15 kV air discharge
- **Clamping Voltage**: < VDD + 0.5V

### Signal Integrity
- **Rise/Fall Times**: Meet I2C specification requirements
- **Crosstalk**: Maintain > 10:1 signal-to-noise ratio
- **Jitter**: < 50 ns peak-to-peak for high-speed mode

## Firmware/Software Integration

### Device Tree Entry (Linux)
```dts
i2c@40005000 {
    compatible = "vendor,i2c-master";
    reg = <0x40005000 0x100>;
    interrupts = <15 0>;
    clocks = <&sys_clk>;
    clock-names = "i2c";
    pinctrl-names = "default";
    pinctrl-0 = <&i2c_pins>;
    #address-cells = <1>;
    #size-cells = <0>;

    eeprom@50 {
        compatible = "atmel,24c256";
        reg = <0x50>;
        pagesize = <64>;
    };
};
```

### Linux Driver Structure
```c
#include <linux/i2c.h>
#include <linux/of.h>

#define DRIVER_NAME "i2c-master"

struct i2c_master_dev {
    void __iomem *regs;
    struct device *dev;
    struct i2c_adapter adapter;
    struct clk *clk;
    int irq;
};

static int i2c_master_xfer(struct i2c_adapter *adap, struct i2c_msg *msgs, int num) {
    struct i2c_master_dev *i2c_dev = i2c_get_adapdata(adap);
    // Implementation of transfer function
}

static u32 i2c_master_func(struct i2c_adapter *adap) {
    return I2C_FUNC_I2C | I2C_FUNC_SMBUS_EMUL;
}

static const struct i2c_algorithm i2c_master_algo = {
    .master_xfer = i2c_master_xfer,
    .functionality = i2c_master_func,
};

static int i2c_master_probe(struct platform_device *pdev) {
    struct i2c_master_dev *i2c_dev;
    struct resource *res;
    int ret;

    i2c_dev = devm_kzalloc(&pdev->dev, sizeof(*i2c_dev), GFP_KERNEL);
    if (!i2c_dev)
        return -ENOMEM;

    // Get resources
    res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    i2c_dev->regs = devm_ioremap_resource(&pdev->dev, res);
    if (IS_ERR(i2c_dev->regs))
        return PTR_ERR(i2c_dev->regs);

    i2c_dev->irq = platform_get_irq(pdev, 0);
    i2c_dev->clk = devm_clk_get(&pdev->dev, "i2c");
    if (IS_ERR(i2c_dev->clk))
        return PTR_ERR(i2c_dev->clk);

    // Enable clock
    ret = clk_prepare_enable(i2c_dev->clk);
    if (ret)
        return ret;

    // Initialize I2C adapter
    i2c_dev->adapter.owner = THIS_MODULE;
    i2c_dev->adapter.algo = &i2c_master_algo;
    i2c_dev->adapter.dev.parent = &pdev->dev;
    i2c_dev->adapter.dev.of_node = pdev->dev.of_node;
    snprintf(i2c_dev->adapter.name, sizeof(i2c_dev->adapter.name),
             "I2C Master Adapter");

    // Register I2C adapter
    ret = i2c_add_adapter(&i2c_dev->adapter);
    if (ret)
        goto err_disable_clk;

    platform_set_drvdata(pdev, i2c_dev);

    dev_info(&pdev->dev, "I2C master driver probed\n");

    return 0;

err_disable_clk:
    clk_disable_unprepare(i2c_dev->clk);
    return ret;
}
```

## Testing and Validation

### Integration Test Checklist
- [ ] Clock and reset signals connected correctly
- [ ] I2C pins routed with proper termination
- [ ] Power supplies filtered and decoupled
- [ ] ESD protection implemented
- [ ] Software driver loads without errors
- [ ] Basic I2C transactions work
- [ ] Interrupt handling functional
- [ ] Error conditions handled properly
- [ ] Power management works
- [ ] Multi-master scenarios tested

### Performance Benchmarks
- **Throughput**: Measure actual data transfer rates
- **Latency**: Measure response times for commands
- **Power**: Measure current consumption in different modes
- **Reliability**: Run extended stress tests

## Board Design Considerations

### I2C Bus Routing with External IO Buffers
- **Signal Integrity**: Route SDA and SCL traces with controlled impedance (50-100Ω)
- **Trace Length Matching**: Keep SDA and SCL trace lengths equal (< 30cm)
- **Crosstalk Minimization**: Maintain >10:1 signal-to-noise ratio
- **Layer Stack-up**: Use appropriate PCB layers for I2C signals

### Pull-up Resistor Selection
| Speed Mode | Pull-up Value | Bus Capacitance | Notes |
|------------|---------------|-----------------|-------|
| Standard (100kHz) | 4.7kΩ - 10kΩ | < 400pF | External resistors required |
| Fast (400kHz) | 1kΩ - 4.7kΩ | < 400pF | Lower values for faster edges |
| Fast+ (1MHz) | 470Ω - 2kΩ | < 200pF | Very low capacitance required |
| High Speed (3.4MHz) | 470Ω - 2kΩ | < 100pF | Specialized buffers needed |

### IO Buffer Placement
- **Location**: Place IO buffers near the physical I2C pins
- **Power Supply**: Connect to clean power rail with decoupling
- **Thermal Considerations**: Ensure adequate heat dissipation for high-drive buffers
- **Test Access**: Provide test points for SDA/SCL signals

### ESD and Protection
- **ESD Protection**: Include TVS diodes rated for ±8kV (HBM)
- **Protection Level**: Meet automotive ESD requirements if applicable
- **Clamping Voltage**: Ensure protection diodes clamp below VDD + 0.5V
- **Board-Level Testing**: Verify ESD protection during board bring-up

### Power Supply Filtering
```verilog
// Recommended decoupling for IO buffers
module power_filter (
    input wire vdd_raw,
    output wire vdd_clean
);

    // 10uF bulk capacitor
    // 0.1uF ceramic capacitor per buffer
    // Ferrite bead for noise isolation

endmodule
```

### Signal Quality Monitoring
- **Rise/Fall Times**: Monitor SDA/SCL edge rates
- **Overshoot/Undershoot**: Ensure < 10% of VDD
- **Jitter**: Keep clock jitter < 50ns peak-to-peak
- **Bus Contention**: Detect and handle multi-master conflicts

---

[Back to Index](index.md) | [Previous: Testing Guidelines](testing_guidelines.md)

[Back to Index](index.md) | [Previous: Testing Guidelines](testing_guidelines.md)