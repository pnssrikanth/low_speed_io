# I2C IP Core Testbench

This directory contains the complete SystemVerilog testbench for the I2C IP core verification. The testbench is designed to be hierarchical, reusable, and compatible with Icarus Verilog.

## Directory Structure

```
src/tb/
├── interfaces/          # Interface definitions
│   ├── apb_if.sv       # APB interface
│   └── i2c_if.sv       # I2C interface
├── components/          # Verification components
│   ├── apb_bfm.sv      # APB Bus Functional Model
│   ├── i2c_monitor.sv  # I2C protocol monitor
│   ├── scoreboard.sv   # Result checking and statistics
│   └── coverage.sv     # Coverage collection
├── tests/               # Test case implementations
│   ├── base_test.sv    # Base test class
│   └── test_reset.sv   # TC_001: Reset functionality
├── i2c_tb_top.sv       # Main testbench top module
└── README.md           # This file
```

## Quick Start

### Prerequisites
- Icarus Verilog (iverilog)
- GTKWave (optional, for waveform viewing)

### Running a Test

1. **Compile the testbench:**
   ```bash
   cd i2c/
   ./scripts/compile_tb.sh
   ```

2. **Run a specific test:**
   ```bash
   ./scripts/run_test.sh --test=test_reset
   ```

3. **Run with waveform generation:**
   ```bash
   ./scripts/run_test.sh --test=test_reset --waveform
   gtkwave sim/i2c_tb_top.vcd
   ```

## Testbench Architecture

### Components Overview

#### 1. Interfaces (`interfaces/`)
- **APB Interface**: Defines AMBA APB protocol signals
- **I2C Interface**: Defines I2C bus protocol signals

#### 2. Verification Components (`components/`)

##### APB BFM (Bus Functional Model)
- Handles all APB bus transactions
- Provides high-level API for register access
- Supports read/write operations with error checking

##### I2C Monitor
- Passively monitors I2C bus activity
- Captures protocol transactions
- Sends transaction data to scoreboard

##### Scoreboard
- Compares expected vs actual transactions
- Maintains test statistics
- Generates detailed test reports

##### Coverage Collector
- Measures functional and code coverage
- Samples coverage points during test execution
- Generates coverage reports

#### 3. Test Cases (`tests/`)

##### Base Test Class
- Provides common functionality for all tests
- Handles setup, teardown, and result reporting
- Defines standard test flow

##### Individual Test Cases
- Inherit from base test class
- Implement specific test scenarios
- Follow TC_001 to TC_025 from verification plan

### Test Execution Flow

1. **Setup Phase**
   - Initialize verification components
   - Reset DUT
   - Configure basic settings

2. **Test Execution Phase**
   - Run test-specific stimulus
   - Monitor DUT responses
   - Collect coverage data

3. **Teardown Phase**
   - Generate reports
   - Check test results
   - Clean up resources

## Adding New Test Cases

### 1. Create Test File
Create a new file in `tests/` directory:

```verilog
class test_your_test extends base_test;
    function new(virtual apb_if apb_vif, virtual i2c_if i2c_vif);
        super.new("TC_XXX_Your_Test_Name", apb_vif, i2c_vif);
        this.test_id = XXX;
    endfunction

    task run();
        setup();

        // Your test implementation here
        // Use apb_bfm_h for APB transactions
        // Use i2c_mon_h for I2C monitoring
        // Use sb_h for result checking
        // Use cov_h for coverage

        teardown();
    endtask
endclass
```

### 2. Register Test in Testbench Top
Add your test to the case statement in `i2c_tb_top.sv`:

```verilog
case (test_name)
    "test_reset": begin
        test_reset t = new(apb_if_inst, i2c_if_inst);
        test_h = t;
    end
    "test_your_test": begin
        test_your_test t = new(apb_if_inst, i2c_if_inst);
        test_h = t;
    end
    // ...
endcase
```

### 3. Run Your Test
```bash
./scripts/run_test.sh --test=test_your_test
```

## Coverage Goals

The testbench implements comprehensive coverage collection:

- **Functional Coverage**: ≥95%
  - I2C protocol coverage (addresses, data, speed modes)
  - Register access coverage
  - Interrupt coverage
  - Error handling coverage
  - Safety mechanism coverage

- **Code Coverage**: ≥90%
  - Statement coverage
  - Branch coverage
  - Toggle coverage
  - FSM state coverage

## Debugging and Analysis

### Waveform Analysis
Use GTKWave to view simulation waveforms:
```bash
gtkwave sim/i2c_tb_top.vcd
```

### Log Analysis
Test execution generates detailed logs showing:
- APB transactions
- I2C bus activity
- Test progress
- Error messages
- Coverage statistics

### Common Debug Techniques
1. **Check signal timing** in waveforms
2. **Verify register values** through logs
3. **Monitor I2C transactions** for protocol compliance
4. **Review coverage reports** for test completeness

## Integration with CI/CD

The testbench is designed for automated testing:

```bash
# Compile and run all tests
./scripts/compile_tb.sh
./scripts/run_test.sh --test=test_reset
./scripts/run_test.sh --test=test_basic_master_tx
# ... run all tests

# Check coverage
# (Coverage analysis would be added here)
```

## Best Practices

### Test Development
- Use descriptive test names
- Include detailed comments
- Follow consistent coding style
- Test both positive and negative scenarios

### Debugging
- Use waveform viewer for timing issues
- Check logs for transaction details
- Verify coverage for completeness
- Isolate failing components

### Maintenance
- Keep test cases independent
- Update documentation with changes
- Review coverage regularly
- Maintain backward compatibility

## Troubleshooting

### Compilation Issues
- Ensure all dependencies are installed
- Check file paths in compilation script
- Verify SystemVerilog syntax

### Runtime Issues
- Check waveform timing
- Verify interface connections
- Review test configuration
- Check for race conditions

### Coverage Issues
- Add missing coverage points
- Review test scenarios
- Check coverage exclusions
- Analyze coverage holes

## Future Enhancements

- Add more test cases (TC_002 to TC_025)
- Implement constrained random testing
- Add formal verification
- Integrate with commercial simulators
- Add performance profiling
- Implement regression testing framework

## References

- [I2C Bus Specification](https://www.nxp.com/docs/en/user-guide/UM10204.pdf)
- [AMBA APB Protocol Specification](https://developer.arm.com/documentation/ihi0024/latest/)
- [SystemVerilog LRM](https://ieeexplore.ieee.org/document/8299595)
- [Verification Plan](../docs/verification_plan.md)
- [Testbench Architecture](../docs/testbench_architecture.md)