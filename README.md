# Low Speed IO Repository

This repository contains IP cores for low-speed communication protocols.

## I2C IP Core

The first IP in this repository is an I2C (Inter-Integrated Circuit) protocol implementation.

### Directory Structure
- `i2c_ip/src/`: Source Verilog files
  - `i2c_master.v`: I2C master module
  - `i2c_slave.v`: I2C slave module
- `i2c_ip/docs/`: Documentation
  - `arch_spec/`: High-level architecture specification
  - `micro_arch_spec/`: Detailed micro-architecture specification
  - `PRD.md`: Product Requirements Document
- `i2c_ip/test/`: Testbenches and test files

### Features
- I2C master and slave implementations
- Configurable slave address
- Basic read/write operations
- Automotive-grade safety features
- Configurable for different SoC classes

### Documentation
- **[Architecture Specification](i2c_ip/docs/arch_spec/)**: High-level design overview
- **[Micro-Architecture Specification](i2c_ip/docs/micro_arch_spec/)**: Detailed implementation guide
- **[Product Requirements Document](i2c_ip/docs/PRD.md)**: Requirements and features

### Usage
1. Instantiate the modules in your design
2. Connect clock, reset, and I2C lines
3. Use the control signals to initiate transactions
4. Refer to the micro-architecture specification for detailed implementation guidance

### Development Status
This is an initial skeleton. Full implementation and testing are in progress. The detailed micro-architecture specification provides comprehensive guidance for production-ready implementation.

## Contributing
Please follow standard Verilog coding practices and add comments to the code.