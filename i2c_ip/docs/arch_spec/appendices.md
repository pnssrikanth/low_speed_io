# 10. Appendices

## 10.1 Glossary

### A
- **ACK**: Acknowledge signal in I2C protocol
- **APB**: Advanced Peripheral Bus, ARM's low-power bus
- **AHB**: Advanced High-performance Bus, ARM's high-performance bus
- **ASIC**: Application-Specific Integrated Circuit
- **ASIL**: Automotive Safety Integrity Level

### B
- **BIST**: Built-In Self-Test
- **BRAM**: Block RAM in FPGA devices

### C
- **CDC**: Clock Domain Crossing
- **CRC**: Cyclic Redundancy Check
- **Crosstalk**: Unwanted coupling between signals

### D
- **DMA**: Direct Memory Access
- **DRC**: Design Rule Check

### E
- **ECC**: Error-Correcting Code
- **EMI**: Electromagnetic Interference
- **ESD**: Electrostatic Discharge

### F
- **FIFO**: First In, First Out buffer
- **FPGA**: Field-Programmable Gate Array
- **FSM**: Finite State Machine

### H
- **HS Mode**: High-Speed mode in I2C (3.4 Mbps)

### I
- **I2C**: Inter-Integrated Circuit bus
- **IP**: Intellectual Property core
- **ISR**: Interrupt Service Routine

### L
- **LFM**: Latent Fault Metric
- **LIN**: Local Interconnect Network
- **LUT**: Look-Up Table in FPGA

### M
- **MBIST**: Memory Built-In Self-Test
- **MCU**: Microcontroller Unit
- **MTBF**: Mean Time Between Failures

### N
- **NACK**: Not Acknowledge signal

### O
- **OBD-II**: On-Board Diagnostics version 2

### P
- **PLL**: Phase-Locked Loop
- **PRD**: Product Requirements Document
- **PVT**: Process, Voltage, Temperature

### R
- **RDC**: Reset Domain Crossing
- **RTL**: Register Transfer Level

### S
- **SCL**: Serial Clock line in I2C
- **SDA**: Serial Data line in I2C
- **SoC**: System on Chip
- **SPFM**: Single-Point Fault Metric
- **SPI**: Serial Peripheral Interface

### T
- **TCL**: Tool Command Language
- **TLM**: Transaction-Level Modeling

### U
- **UVM**: Universal Verification Methodology
- **UVVM**: Universal VHDL Verification Methodology

### V
- **Verilog**: Hardware description language
- **VHDL**: VHSIC Hardware Description Language

## 10.2 References

### Standards and Specifications

1. **I2C-bus specification and user manual** (UM10204)
   - NXP Semiconductors
   - Version 7.0, October 2021
   - https://www.nxp.com/docs/en/user-guide/UM10204.pdf

2. **ISO 26262: Road vehicles - Functional safety**
   - International Organization for Standardization
   - Parts 1-12, various dates
   - https://www.iso.org/standard/43464.html

3. **AEC-Q100: Failure mechanism based stress test qualification for integrated circuits**
   - Automotive Electronics Council
   - Revision H, September 2014
   - https://www.aecouncil.com/Documents/AEC_Q100.pdf

4. **ARM AMBA 3 APB Protocol Specification**
   - ARM Limited
   - Version 1.0, 2004
   - https://developer.arm.com/documentation/ihi0024/latest/

5. **ARM AMBA 3 AHB-Lite Protocol Specification**
   - ARM Limited
   - Version 1.0, 2006
   - https://developer.arm.com/documentation/ihi0033/latest/

### Books and Technical References

6. **I2C Manual: Including Specification for I3C**
   - Jean-Marc Irazabal and Vincent Himpe
   - Published by Embedded Systems Academy, 2015
   - ISBN: 978-0-9836656-2-0

7. **The Design of Reliable Systems using Unreliable Components**
   - Behrooz Parhami
   - Published by Springer, 2005
   - ISBN: 978-0-387-24084-5

8. **ASIC Design in the Silicon Age**
   - Daniel Nenni and Paul McLellan
   - Published by Newnes, 2003
   - ISBN: 978-1-878707-97-8

### Online Resources

9. **OpenCores I2C Master Core**
   - https://opencores.org/projects/i2c

10. **ZipCPU I2C Controller**
    - https://zipcpu.com/blog/2017/10/29/i2c.html

11. **FPGA Prototyping by SystemVerilog Examples**
    - Pong P. Chu
    - Wiley, 2018
    - ISBN: 978-1-119-28263-8

## 10.3 Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-01-01 | Open-Source Team | Initial release of architecture specification |
| 1.1 | 2025-01-15 | Open-Source Team | Added automotive safety features |
| 1.2 | 2025-02-01 | Open-Source Team | Updated implementation guidelines |
| 1.3 | 2025-02-15 | Open-Source Team | Added software interface details |
| 1.4 | 2025-03-01 | Open-Source Team | Comprehensive testing and verification section |

## 10.4 Acronyms and Abbreviations

| Acronym | Expansion |
|---------|-----------|
| ACK | Acknowledge |
| AEC | Automotive Electronics Council |
| AHB | Advanced High-performance Bus |
| AMBA | Advanced Microcontroller Bus Architecture |
| APB | Advanced Peripheral Bus |
| ASIL | Automotive Safety Integrity Level |
| ASIC | Application-Specific Integrated Circuit |
| BIST | Built-In Self-Test |
| CAN | Controller Area Network |
| CDC | Clock Domain Crossing |
| CRC | Cyclic Redundancy Check |
| DMA | Direct Memory Access |
| DRC | Design Rule Check |
| ECC | Error-Correcting Code |
| EMI | Electromagnetic Interference |
| ESD | Electrostatic Discharge |
| FIFO | First In, First Out |
| FPGA | Field-Programmable Gate Array |
| FSM | Finite State Machine |
| FMEA | Failure Mode and Effects Analysis |
| HS | High Speed |
| I2C | Inter-Integrated Circuit |
| IP | Intellectual Property |
| ISR | Interrupt Service Routine |
| LIN | Local Interconnect Network |
| LFM | Latent Fault Metric |
| LUT | Look-Up Table |
| MBIST | Memory Built-In Self-Test |
| MCU | Microcontroller Unit |
| MTBF | Mean Time Between Failures |
| NACK | Not Acknowledge |
| OBD | On-Board Diagnostics |
| PLL | Phase-Locked Loop |
| PRD | Product Requirements Document |
| PVT | Process, Voltage, Temperature |
| RDC | Reset Domain Crossing |
| RTL | Register Transfer Level |
| SCL | Serial Clock |
| SDA | Serial Data |
| SoC | System on Chip |
| SPFM | Single-Point Fault Metric |
| SPI | Serial Peripheral Interface |
| TCL | Tool Command Language |
| TLM | Transaction-Level Modeling |
| UVM | Universal Verification Methodology |
| UVVM | Universal VHDL Verification Methodology |
| Verilog | Hardware Description Language |
| VHDL | VHSIC Hardware Description Language |

## 10.5 Contact Information

For questions, feedback, or contributions:

- **GitHub Repository**: https://github.com/pnssrikanth/low_speed_io
- **Issues**: https://github.com/pnssrikanth/low_speed_io/issues
- **Discussions**: https://github.com/pnssrikanth/low_speed_io/discussions
- **Email**: [Maintainer email if applicable]

## 10.6 License

This document is part of the I2C IP core project and is licensed under the Apache License 2.0.

```
Copyright 2025 Open-Source I2C IP Development Team

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

[Previous: Testing and Verification](./testing.md)