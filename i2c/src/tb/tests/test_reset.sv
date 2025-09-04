/**
 * Test Case TC_001: Reset Functionality
 * Tests the reset behavior of the I2C IP core
 */

class test_reset extends base_test;

    /**
     * Constructor
     */
    function new(virtual apb_if apb_vif, virtual i2c_if i2c_vif);
        super.new("TC_001_Reset_Functionality", apb_vif, i2c_vif);
        this.test_id = 1;
    endfunction : new

    /**
     * Main test execution
     */
    task run();
        bit test_result = 1'b1;
        bit [31:0] reg_value;

        $display("\n");
        $display("=================================================================");
        $display("                STARTING TEST TC_001: Reset Functionality");
        $display("=================================================================");

        // Setup test environment
        setup();

        // Test Phase 1: Configure registers before reset
        $display("\n[TC_001] Phase 1: Configure registers before reset");
        apb_bfm_h.write_reg(TIMING_ADDR, 32'h1234_5678);
        apb_bfm_h.write_reg(ADDR_ADDR, 32'h0000_00AA);
        apb_bfm_h.write_reg(INT_EN_ADDR, 32'hFFFF_FFFF);

        // Verify registers are configured
        apb_bfm_h.read_reg(TIMING_ADDR, reg_value);
        if (reg_value != 32'h1234_5678) begin
            $error("[TC_001] Register configuration failed: expected 0x12345678, got 0x%h", reg_value);
            test_result = 1'b0;
        end

        // Test Phase 2: Assert reset and verify register clearing
        $display("\n[TC_001] Phase 2: Assert reset and verify register clearing");

        // Assert reset via software reset
        apb_bfm_h.write_reg(CTRL_ADDR, (1 << CTRL_SOFT_RST));

        // Wait for reset to complete
        #200;  // Allow time for reset propagation

        // Check that registers are cleared (except read-only registers)
        apb_bfm_h.read_reg(TIMING_ADDR, reg_value);
        if (reg_value != 32'h0000_0000) begin
            $error("[TC_001] TIMING register not cleared: got 0x%h", reg_value);
            test_result = 1'b0;
        end

        apb_bfm_h.read_reg(ADDR_ADDR, reg_value);
        if (reg_value != 32'h0000_0000) begin
            $error("[TC_001] ADDR register not cleared: got 0x%h", reg_value);
            test_result = 1'b0;
        end

        apb_bfm_h.read_reg(INT_EN_ADDR, reg_value);
        if (reg_value != 32'h0000_0000) begin
            $error("[TC_001] INT_EN register not cleared: got 0x%h", reg_value);
            test_result = 1'b0;
        end

        // Test Phase 3: Verify core is disabled after reset
        $display("\n[TC_001] Phase 3: Verify core is disabled after reset");

        apb_bfm_h.read_reg(CTRL_ADDR, reg_value);
        if (reg_value & (1 << CTRL_EN)) begin
            $error("[TC_001] Core not disabled after reset: CTRL=0x%h", reg_value);
            test_result = 1'b0;
        end

        // Test Phase 4: Re-enable core and verify functionality
        $display("\n[TC_001] Phase 4: Re-enable core and verify functionality");

        // Re-enable the core
        apb_bfm_h.write_reg(CTRL_ADDR, (1 << CTRL_EN));

        // Verify core is enabled
        apb_bfm_h.read_reg(CTRL_ADDR, reg_value);
        if (!(reg_value & (1 << CTRL_EN))) begin
            $error("[TC_001] Core not re-enabled: CTRL=0x%h", reg_value);
            test_result = 1'b0;
        end

        // Test Phase 5: Test hardware reset
        $display("\n[TC_001] Phase 5: Test hardware reset");

        // Configure registers again
        apb_bfm_h.write_reg(TIMING_ADDR, 32'hABCD_EF12);

        // Assert hardware reset
        apb_vif.presetn = 1'b0;
        #100;

        // De-assert reset
        apb_vif.presetn = 1'b1;
        #100;

        // Verify registers are cleared after hardware reset
        apb_bfm_h.read_reg(TIMING_ADDR, reg_value);
        if (reg_value != 32'h0000_0000) begin
            $error("[TC_001] Hardware reset failed: TIMING=0x%h", reg_value);
            test_result = 1'b0;
        end

        // Update test result
        check_result(test_result);

        // Sample coverage
        cov_h.sample_register(TIMING_ADDR, 1'b1);  // Write operation
        cov_h.sample_register(CTRL_ADDR, 1'b1);    // Write operation

        // Teardown
        teardown();

        $display("\n=================================================================");
        $display("                TEST TC_001 COMPLETED");
        $display("=================================================================");
    endtask : run

endclass : test_reset