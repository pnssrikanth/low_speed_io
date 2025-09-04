# 8. Software Interface

## 8.1 Driver Architecture

### 8.1.1 Driver Layers

```
+-------------------+
| Application Layer |
+-------------------+
| OS Driver Layer   |
+-------------------+
| HAL Layer         |
+-------------------+
| Register Interface|
+-------------------+
| Hardware          |
+-------------------+
```

### 8.1.2 Driver Components

- **Core Driver**: Basic I2C operations
- **Bus Driver**: Multi-device management
- **Slave Driver**: Device-specific drivers
- **Interrupt Handler**: Event processing

## 8.2 API Reference

### 8.2.1 Initialization Functions

```c
/**
 * Initialize I2C controller
 * @param base_addr Base address of I2C controller
 * @param clk_freq System clock frequency
 * @param i2c_speed Desired I2C bus speed
 * @return 0 on success, error code otherwise
 */
int i2c_init(uint32_t base_addr, uint32_t clk_freq, uint32_t i2c_speed);

/**
 * Configure I2C controller mode
 * @param base_addr Base address
 * @param mode I2C_MODE_MASTER, I2C_MODE_SLAVE, I2C_MODE_DUAL
 * @return 0 on success
 */
int i2c_set_mode(uint32_t base_addr, i2c_mode_t mode);
```

### 8.2.2 Data Transfer Functions

```c
/**
 * Write data to I2C slave
 * @param base_addr Base address
 * @param slave_addr 7-bit slave address
 * @param data Pointer to data buffer
 * @param length Number of bytes to write
 * @param timeout_ms Timeout in milliseconds
 * @return Number of bytes written, negative on error
 */
int i2c_write(uint32_t base_addr, uint8_t slave_addr,
              const uint8_t *data, uint32_t length, uint32_t timeout_ms);

/**
 * Read data from I2C slave
 * @param base_addr Base address
 * @param slave_addr 7-bit slave address
 * @param data Pointer to data buffer
 * @param length Number of bytes to read
 * @param timeout_ms Timeout in milliseconds
 * @return Number of bytes read, negative on error
 */
int i2c_read(uint32_t base_addr, uint8_t slave_addr,
             uint8_t *data, uint32_t length, uint32_t timeout_ms);
```

### 8.2.3 Advanced Functions

```c
/**
 * Perform I2C combined write-read transaction
 * @param base_addr Base address
 * @param slave_addr 7-bit slave address
 * @param write_data Data to write
 * @param write_len Length of write data
 * @param read_data Buffer for read data
 * @param read_len Length of read data
 * @return 0 on success
 */
int i2c_write_read(uint32_t base_addr, uint8_t slave_addr,
                   const uint8_t *write_data, uint32_t write_len,
                   uint8_t *read_data, uint32_t read_len);

/**
 * Configure slave address for slave mode
 * @param base_addr Base address
 * @param slave_addr 7-bit or 10-bit slave address
 * @param addr_mode I2C_ADDR_7BIT or I2C_ADDR_10BIT
 * @return 0 on success
 */
int i2c_set_slave_addr(uint32_t base_addr, uint16_t slave_addr,
                       i2c_addr_mode_t addr_mode);
```

## 8.3 Interrupt Handling

### 8.3.1 Interrupt Sources

| Interrupt | Description | Priority |
|-----------|-------------|----------|
| TX_DONE | Transmit complete | Medium |
| RX_DONE | Receive complete | Medium |
| TX_THRESH | TX FIFO threshold | Low |
| RX_THRESH | RX FIFO threshold | Low |
| ERROR | Bus error | High |
| ARB_LOST | Arbitration lost | High |

### 8.3.2 Interrupt Service Routine

```c
void i2c_isr(uint32_t base_addr) {
    uint32_t int_status = I2C_READ_REG(base_addr, INT_STATUS);

    if (int_status & INT_TX_DONE) {
        // Handle transmit complete
        tx_complete_handler();
        I2C_WRITE_REG(base_addr, INT_STATUS, INT_TX_DONE);
    }

    if (int_status & INT_RX_DONE) {
        // Handle receive complete
        rx_complete_handler();
        I2C_WRITE_REG(base_addr, INT_STATUS, INT_RX_DONE);
    }

    if (int_status & INT_ERROR) {
        // Handle error
        error_handler();
        I2C_WRITE_REG(base_addr, INT_STATUS, INT_ERROR);
    }
}
```

## 8.4 Firmware Integration

### 8.4.1 Bootloader Integration

```c
// Initialize I2C for EEPROM access during boot
void bootloader_init_i2c(void) {
    i2c_init(I2C_BASE_ADDR, SYS_CLK_FREQ, I2C_SPEED_400K);

    // Read configuration from EEPROM
    uint8_t config_data[64];
    i2c_read(I2C_BASE_ADDR, EEPROM_ADDR, config_data, 64, 100);

    // Parse configuration
    parse_boot_config(config_data);
}
```

### 8.4.2 RTOS Integration

```c
// I2C task for RTOS
void i2c_task(void *param) {
    QueueHandle_t i2c_queue = (QueueHandle_t)param;
    i2c_transaction_t transaction;

    while (1) {
        // Wait for transaction request
        if (xQueueReceive(i2c_queue, &transaction, portMAX_DELAY)) {
            // Process transaction
            int result = i2c_process_transaction(&transaction);

            // Send result back
            xQueueSend(transaction.result_queue, &result, 0);
        }
    }
}
```

## 8.5 Board Design Considerations

### 8.5.1 I2C Bus Design

#### Pull-up Resistors
- **Standard Mode**: 4.7kΩ pull-ups
- **Fast Mode**: 1kΩ pull-ups
- **Fast Mode Plus**: 470Ω pull-ups

#### Bus Length
- **Standard Mode**: Up to 100 meters (with appropriate pull-ups)
- **Fast Mode**: Up to 10 meters
- **High Speed**: Up to 1 meter

### 8.5.2 Power Supply

```verilog
// Power supply filtering
module power_filter (
    input vdd_raw,
    output vdd_filtered
);

// Decoupling capacitors and filtering
assign vdd_filtered = vdd_raw;  // Implementation depends on requirements
endmodule
```

### 8.5.3 Signal Integrity

- **Termination**: Series termination for high-speed signals
- **Ground Planes**: Separate ground planes for analog and digital
- **EMI Filtering**: Ferrite beads for noise suppression

## 8.6 Device Driver Examples

### 8.6.1 EEPROM Driver

```c
#define EEPROM_ADDR 0x50
#define PAGE_SIZE 64

int eeprom_write_page(uint32_t i2c_base, uint16_t addr, const uint8_t *data, uint8_t len) {
    uint8_t buffer[PAGE_SIZE + 2];

    // Address high byte
    buffer[0] = (addr >> 8) & 0xFF;
    // Address low byte
    buffer[1] = addr & 0xFF;
    // Data
    memcpy(&buffer[2], data, len);

    return i2c_write(i2c_base, EEPROM_ADDR, buffer, len + 2, 100);
}

int eeprom_read_page(uint32_t i2c_base, uint16_t addr, uint8_t *data, uint8_t len) {
    uint8_t addr_buffer[2];

    addr_buffer[0] = (addr >> 8) & 0xFF;
    addr_buffer[1] = addr & 0xFF;

    return i2c_write_read(i2c_base, EEPROM_ADDR,
                         addr_buffer, 2, data, len);
}
```

### 8.6.2 Sensor Driver

```c
#define SENSOR_ADDR 0x68
#define TEMP_REG 0x41

float read_temperature(uint32_t i2c_base) {
    uint8_t temp_data[2];
    uint16_t raw_temp;

    // Read temperature register
    i2c_write_read(i2c_base, SENSOR_ADDR, &TEMP_REG, 1, temp_data, 2);

    // Convert to 16-bit value
    raw_temp = (temp_data[0] << 8) | temp_data[1];

    // Convert to Celsius (sensor-specific formula)
    return (raw_temp / 340.0) + 36.53;
}
```

## 8.7 Performance Optimization

### 8.7.1 DMA Usage

```c
// Configure DMA for large transfers
int i2c_dma_transfer(uint32_t i2c_base, uint8_t slave_addr,
                     uint8_t *buffer, uint32_t length, uint8_t direction) {
    // Enable DMA in I2C controller
    I2C_WRITE_REG(i2c_base, CTRL, I2C_READ_REG(i2c_base, CTRL) | DMA_EN);

    // Configure DMA controller
    dma_config_t dma_cfg = {
        .src_addr = (direction == I2C_READ) ? I2C_RX_DATA_REG : (uint32_t)buffer,
        .dst_addr = (direction == I2C_READ) ? (uint32_t)buffer : I2C_TX_DATA_REG,
        .length = length,
        .transfer_size = DMA_TRANSFER_8BIT
    };

    return dma_start_transfer(&dma_cfg);
}
```

### 8.7.2 Interrupt Optimization

```c
// Use threshold interrupts for efficiency
void optimize_interrupts(uint32_t i2c_base) {
    // Set TX threshold to half FIFO depth
    I2C_WRITE_REG(i2c_base, FIFO_THRESH,
                  (FIFO_DEPTH/2 << 8) | (FIFO_DEPTH/2));

    // Enable threshold interrupts
    I2C_WRITE_REG(i2c_base, INT_EN,
                  INT_TX_THRESH_EN | INT_RX_THRESH_EN);
}
```

## 8.8 Error Handling

### 8.8.1 Error Codes

```c
typedef enum {
    I2C_SUCCESS = 0,
    I2C_ERROR_TIMEOUT = -1,
    I2C_ERROR_NACK = -2,
    I2C_ERROR_ARB_LOST = -3,
    I2C_ERROR_BUS_STUCK = -4,
    I2C_ERROR_INVALID_PARAM = -5
} i2c_error_t;
```

### 8.8.2 Error Recovery

```c
int i2c_recover_from_error(uint32_t i2c_base, i2c_error_t error) {
    switch (error) {
        case I2C_ERROR_TIMEOUT:
            // Reset controller
            i2c_reset(i2c_base);
            break;

        case I2C_ERROR_ARB_LOST:
            // Wait for bus free, then retry
            vTaskDelay(pdMS_TO_TICKS(10));
            break;

        case I2C_ERROR_BUS_STUCK:
            // Force bus reset
            i2c_force_bus_reset(i2c_base);
            break;

        default:
            return I2C_ERROR_INVALID_PARAM;
    }

    return I2C_SUCCESS;
}
```

---

[Previous: Implementation Guidelines](./implementation.md) | [Next: Testing and Verification](./testing.md)