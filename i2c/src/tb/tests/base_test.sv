/**
 * Base Test Class
 * Provides common functionality for all I2C IP test cases
 */

class base_test;

    // Test identification
    string test_name;
    int test_id;

    // Verification components
    apb_bfm apb_bfm_h;
    i2c_monitor i2c_mon_h;
    scoreboard sb_h;
    coverage_collector cov_h;

    // Mailboxes for inter-component communication
    mailbox mon2sb;
    mailbox drv2sb;

    // Virtual interfaces
    virtual apb_if apb_vif;
    virtual i2c_if i2c_vif;

    // Test control flags
    bit test_passed;
    bit test_completed;
    time test_start_time;
    time test_end_time;

    // I2C register addresses (from register map)
    const bit [31:0] CTRL_ADDR       = 'h00;
    const bit [31:0] STATUS_ADDR     = 'h04;
    const bit [31:0] INT_EN_ADDR     = 'h08;
    const bit [31:0] INT_STATUS_ADDR = 'h0C;
    const bit [31:0] TIMING_ADDR     = 'h10;
    const bit [31:0] ADDR_ADDR       = 'h14;
    const bit [31:0] TX_DATA_ADDR    = 'h18;
    const bit [31:0] RX_DATA_ADDR    = 'h1C;
    const bit [31:0] FIFO_STATUS_ADDR = 'h20;
    const bit [31:0] FIFO_THRESH_ADDR = 'h24;
    const bit [31:0] ERROR_ADDR      = 'h28;
    const bit [31:0] DIAG_ADDR       = 'h2C;
    const bit [31:0] SAFETY_ADDR     = 'h30;
    const bit [31:0] VERSION_ADDR    = 'h34;

    // Control register bit definitions
    const bit [4:0] CTRL_EN           = 0;
    const bit [4:0] CTRL_MASTER_EN    = 2;
    const bit [4:0] CTRL_SLAVE_EN     = 3;
    const bit [4:0] CTRL_FAST_MODE    = 4;
    const bit [4:0] CTRL_HS_MODE      = 5;
    const bit [4:0] CTRL_DMA_EN       = 6;
    const bit [4:0] CTRL_SAFETY_EN    = 7;
    const bit [4:0] CTRL_SOFT_RST     = 1;

    /**
     * Constructor
     * @param name - Test case name
     * @param apb_vif - APB virtual interface
     * @param i2c_vif - I2C virtual interface
     */
    function new(string name, virtual apb_if apb_vif, virtual i2c_if i2c_vif);
        this.test_name = name;
        this.apb_vif = apb_vif;
        this.i2c_vif = i2c_vif;

        // Initialize mailboxes
        mon2sb = new();
        drv2sb = new();

        // Initialize verification components
        apb_bfm_h = new(apb_vif);
        i2c_mon_h = new(i2c_vif, mon2sb);
        sb_h = new(mon2sb, drv2sb);
        cov_h = new();

        // Initialize test flags
        test_passed = 1'b0;
        test_completed = 1'b0;

        $display("[BASE_TEST] Test '%s' initialized", test_name);
    endfunction : new

    /**
     * Setup test environment
     * Called before test execution
     */
    virtual task setup();
        $display("[BASE_TEST] Setting up test environment for '%s'", test_name);

        // Reset DUT
        reset_dut();

        // Configure basic settings
        configure_basic();

        // Start verification components
        fork
            i2c_mon_h.run();
            sb_h.run();
        join_none

        // Record test start time
        test_start_time = $time;

        $display("[BASE_TEST] Test setup completed");
    endtask : setup

    /**
     * Teardown test environment
     * Called after test execution
     */
    virtual task teardown();
        $display("[BASE_TEST] Tearing down test environment for '%s'", test_name);

        // Record test end time
        test_end_time = $time;

        // Generate reports
        sb_h.generate_report();
        cov_h.generate_report();

        // Display test summary
        display_test_summary();

        // Mark test as completed
        test_completed = 1'b1;

        $display("[BASE_TEST] Test teardown completed");
    endtask : teardown

    /**
     * Reset DUT via APB interface
     */
    task reset_dut();
        $display("[BASE_TEST] Resetting DUT");

        // Assert reset
        apb_vif.presetn = 1'b0;
        #100;  // Hold reset for 100ns

        // De-assert reset
        apb_vif.presetn = 1'b1;
        #100;  // Wait for stabilization

        $display("[BASE_TEST] DUT reset completed");
    endtask : reset_dut

    /**
     * Configure basic I2C settings
     */
    task configure_basic();
        $display("[BASE_TEST] Configuring basic I2C settings");

        // Enable I2C core
        apb_bfm_h.write_reg(CTRL_ADDR, (1 << CTRL_EN));

        // Set standard timing (100kHz @ 10MHz system clock)
        apb_bfm_h.write_reg(TIMING_ADDR, 32'h00FA_00FA);  // SCL_HIGH=250, SCL_LOW=250

        // Set slave address (for slave mode tests)
        apb_bfm_h.write_reg(ADDR_ADDR, 32'h0000_0055);  // Address 0x55

        $display("[BASE_TEST] Basic configuration completed");
    endtask : configure_basic

    /**
     * Enable master mode
     */
    task enable_master_mode();
        bit [31:0] ctrl_reg;
        $display("[BASE_TEST] Enabling master mode");

        // Read current control register
        apb_bfm_h.read_reg(CTRL_ADDR, ctrl_reg);

        // Set master enable bit
        ctrl_reg |= (1 << CTRL_MASTER_EN);

        // Write back
        apb_bfm_h.write_reg(CTRL_ADDR, ctrl_reg);

        $display("[BASE_TEST] Master mode enabled");
    endtask : enable_master_mode

    /**
     * Enable slave mode
     */
    task enable_slave_mode();
        bit [31:0] ctrl_reg;
        $display("[BASE_TEST] Enabling slave mode");

        // Read current control register
        apb_bfm_h.read_reg(CTRL_ADDR, ctrl_reg);

        // Set slave enable bit
        ctrl_reg |= (1 << CTRL_SLAVE_EN);

        // Write back
        apb_bfm_h.write_reg(CTRL_ADDR, ctrl_reg);

        $display("[BASE_TEST] Slave mode enabled");
    endtask : enable_slave_mode

    /**
     * Set I2C speed mode
     * @param speed - 0: Standard, 1: Fast, 2: Fast+, 3: High Speed
     */
    task set_speed_mode(int speed);
        bit [31:0] ctrl_reg;
        $display("[BASE_TEST] Setting speed mode to %0d", speed);

        // Read current control register
        apb_bfm_h.read_reg(CTRL_ADDR, ctrl_reg);

        // Clear speed mode bits
        ctrl_reg &= ~( (1 << CTRL_FAST_MODE) | (1 << CTRL_HS_MODE) );

        // Set appropriate speed mode
        case (speed)
            0: ; // Standard mode (default)
            1: ctrl_reg |= (1 << CTRL_FAST_MODE);     // Fast mode
            2: ctrl_reg |= (1 << CTRL_FAST_MODE);     // Fast+ mode (same bit as fast)
            3: ctrl_reg |= (1 << CTRL_HS_MODE);       // High speed mode
            default: $error("[BASE_TEST] Invalid speed mode: %0d", speed);
        endcase

        // Write back
        apb_bfm_h.write_reg(CTRL_ADDR, ctrl_reg);

        // Update timing register based on speed mode
        update_timing_for_speed(speed);

        $display("[BASE_TEST] Speed mode set to %0d", speed);
    endtask : set_speed_mode

    /**
     * Update timing register for specific speed mode
     * @param speed - Speed mode
     */
    task update_timing_for_speed(int speed);
        bit [31:0] timing_value;

        case (speed)
            0: timing_value = 32'h00FA_00FA;  // Standard: 100kHz
            1: timing_value = 32'h0032_0032;  // Fast: 400kHz
            2: timing_value = 32'h0014_0014;  // Fast+: 1MHz
            3: timing_value = 32'h0005_0005;  // HS: 3.4MHz
            default: timing_value = 32'h00FA_00FA;
        endcase

        apb_bfm_h.write_reg(TIMING_ADDR, timing_value);
        $display("[BASE_TEST] Timing updated for speed mode %0d: 0x%h", speed, timing_value);
    endtask : update_timing_for_speed

    /**
     * Wait for I2C transaction to complete
     * @param timeout - Timeout in clock cycles
     */
    task wait_for_transaction_complete(int timeout = 1000);
        bit [31:0] status_reg;
        int cycles = 0;

        $display("[BASE_TEST] Waiting for transaction to complete");

        do begin
            apb_bfm_h.read_reg(STATUS_ADDR, status_reg);
            cycles++;
            if (cycles >= timeout) begin
                $error("[BASE_TEST] Timeout waiting for transaction completion");
                break;
            end
            @(posedge apb_vif.pclk);
        end while ((status_reg & 'h0000_0003) == 0);  // Wait for TX_DONE or RX_DONE

        $display("[BASE_TEST] Transaction completed after %0d cycles", cycles);
    endtask : wait_for_transaction_complete

    /**
     * Check test result and update flags
     * @param result - Test result (1=pass, 0=fail)
     */
    function void check_result(bit result);
        if (result) begin
            test_passed = 1'b1;
            $display("[BASE_TEST] ✓ Test PASSED");
        end else begin
            test_passed = 1'b0;
            $error("[BASE_TEST] ✗ Test FAILED");
        end
    endfunction : check_result

    /**
     * Display test summary
     */
    function void display_test_summary();
        time test_duration = test_end_time - test_start_time;
        string result_str = test_passed ? "PASSED" : "FAILED";

        $display("\n");
        $display("=================================================================");
        $display("                    TEST SUMMARY");
        $display("=================================================================");
        $display("Test Name: %s", test_name);
        $display("Test ID: %0d", test_id);
        $display("Result: %s", result_str);
        $display("Duration: %0t", test_duration);
        $display("Start Time: %0t", test_start_time);
        $display("End Time: %0t", test_end_time);
        $display("=================================================================");
    endfunction : display_test_summary

    /**
     * Main test execution task
     * Must be overridden by derived test classes
     */
    virtual task run();
        $display("[BASE_TEST] Running base test (should be overridden)");
        setup();
        // Test-specific code goes here
        teardown();
    endtask : run

    /**
     * Get test statistics
     * @return String with test statistics
     */
    function string get_statistics();
        string stats;
        $sformat(stats, "Test Statistics for '%s':\n", test_name);
        $sformat(stats, "%s  Result: %s\n", stats, test_passed ? "PASSED" : "FAILED");
        $sformat(stats, "%s  Duration: %0t\n", stats, test_end_time - test_start_time);
        $sformat(stats, "%s  Completed: %s\n", stats, test_completed ? "YES" : "NO");
        return stats;
    endfunction : get_statistics

endclass : base_test