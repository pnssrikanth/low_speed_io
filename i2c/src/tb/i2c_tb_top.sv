/**
 * I2C IP Core Testbench Top Module
 * Main testbench that instantiates DUT and verification components
 */

`timescale 1ns/1ps

module i2c_tb_top;

    // =========================================================================
    // Clock and Reset Generation
    // =========================================================================

    // System clock (APB clock domain)
    logic sys_clk;
    const int SYS_CLK_PERIOD = 10;  // 10ns = 100MHz

    // I2C clock (derived from system clock)
    logic i2c_clk;

    // Reset signals
    logic sys_rst_n;
    logic i2c_rst_n;

    // Clock generation
    initial begin
        sys_clk = 1'b0;
        forever #(SYS_CLK_PERIOD/2) sys_clk = ~sys_clk;
    end

    // Reset generation
    initial begin
        sys_rst_n = 1'b0;
        i2c_rst_n = 1'b0;

        // Hold reset for 100ns
        #100;

        // Release resets
        sys_rst_n = 1'b1;
        i2c_rst_n = 1'b1;

        $display("[TB_TOP] System reset released at %0t", $time);
    end

    // =========================================================================
    // Interface Instantiations
    // =========================================================================

    // APB interface
    apb_if apb_if_inst (
        .pclk(sys_clk),
        .presetn(sys_rst_n)
    );

    // I2C interface
    i2c_if i2c_if_inst ();

    // =========================================================================
    // DUT Instantiation
    // =========================================================================

    // I2C IP Core (DUT)
    i2c_core dut (
        // APB Interface
        .pclk(apb_if_inst.pclk),
        .presetn(apb_if_inst.presetn),
        .psel(apb_if_inst.psel),
        .penable(apb_if_inst.penable),
        .pwrite(apb_if_inst.pwrite),
        .paddr(apb_if_inst.paddr),
        .pwdata(apb_if_inst.pwdata),
        .prdata(apb_if_inst.prdata),
        .pready(apb_if_inst.pready),
        .pslverr(apb_if_inst.pslverr),

        // I2C Interface
        .scl(i2c_if_inst.scl),
        .sda(i2c_if_inst.sda),

        // Control signals
        .irq(),           // Interrupt output
        .dma_req(),       // DMA request
        .dma_ack(1'b0)    // DMA acknowledge (tied low for now)
    );

    // =========================================================================
    // Test Case Selection and Execution
    // =========================================================================

    // Test case selection from command line
    string test_name;
    base_test test_h;

    initial begin
        // Get test name from command line argument
        if ($value$plusargs("TEST_NAME=%s", test_name)) begin
            $display("[TB_TOP] Running test: %s", test_name);
        end else begin
            $display("[TB_TOP] No test specified, running default test");
            test_name = "test_reset";
        end

        // Create and run the selected test
        case (test_name)
            "test_reset": begin
                test_reset t = new(apb_if_inst, i2c_if_inst);
                test_h = t;
            end

            // Add more test cases here as they are implemented
            // "test_basic_master_tx": begin
            //     test_basic_master_tx t = new(apb_if_inst, i2c_if_inst);
            //     test_h = t;
            // end

            default: begin
                $error("[TB_TOP] Unknown test: %s", test_name);
                $display("[TB_TOP] Available tests:");
                $display("[TB_TOP]   test_reset - Reset functionality test");
                $finish;
            end
        endcase

        // Run the test
        if (test_h != null) begin
            test_h.run();
        end

        // End simulation
        $display("[TB_TOP] Test completed, ending simulation");
        $finish;
    end

    // =========================================================================
    // Waveform Dumping
    // =========================================================================

    initial begin
        $dumpfile("i2c_tb_top.vcd");
        $dumpvars(0, i2c_tb_top);

        // Dump key signals
        $dumpvars(1, sys_clk);
        $dumpvars(1, sys_rst_n);
        $dumpvars(1, apb_if_inst.psel);
        $dumpvars(1, apb_if_inst.penable);
        $dumpvars(1, apb_if_inst.pwrite);
        $dumpvars(1, apb_if_inst.paddr);
        $dumpvars(1, apb_if_inst.pwdata);
        $dumpvars(1, apb_if_inst.prdata);
        $dumpvars(1, i2c_if_inst.scl);
        $dumpvars(1, i2c_if_inst.sda);

        $display("[TB_TOP] Waveform dumping enabled");
    end

    // =========================================================================
    // Timeout Protection
    // =========================================================================

    initial begin
        // Global timeout (adjust as needed for different tests)
        int timeout_cycles = 1000000;  // 1ms at 10ns clock period
        int cycle_count = 0;

        while (cycle_count < timeout_cycles) begin
            @(posedge sys_clk);
            cycle_count++;
        end

        $error("[TB_TOP] Global timeout reached after %0d cycles", cycle_count);
        $display("[TB_TOP] Simulation terminated due to timeout");
        $finish;
    end

    // =========================================================================
    // Simulation Control and Monitoring
    // =========================================================================

    // Display simulation progress
    always @(posedge sys_clk) begin
        if ($time % 100000 == 0) begin  // Every 100us
            $display("[TB_TOP] Simulation time: %0t", $time);
        end
    end

    // Monitor APB transactions
    always @(posedge sys_clk) begin
        if (apb_if_inst.psel && apb_if_inst.penable) begin
            if (apb_if_inst.pwrite) begin
                $display("[TB_TOP] APB Write: addr=0x%h, data=0x%h",
                        apb_if_inst.paddr, apb_if_inst.pwdata);
            end else begin
                $display("[TB_TOP] APB Read: addr=0x%h, data=0x%h",
                        apb_if_inst.paddr, apb_if_inst.prdata);
            end
        end
    end

    // Monitor I2C bus activity
    always @(i2c_if_inst.scl or i2c_if_inst.sda) begin
        $display("[TB_TOP] I2C Bus: SCL=%b, SDA=%b at %0t",
                i2c_if_inst.scl, i2c_if_inst.sda, $time);
    end

    // =========================================================================
    // Final Statistics and Cleanup
    // =========================================================================

    final begin
        $display("\n");
        $display("=================================================================");
        $display("                    SIMULATION COMPLETED");
        $display("=================================================================");
        $display("Simulation Time: %0t", $time);
        $display("Test Executed: %s", test_name);

        if (test_h != null) begin
            $display("Test Result: %s", test_h.test_passed ? "PASSED" : "FAILED");
            $display("Test Statistics:");
            $display("%s", test_h.get_statistics());
        end

        $display("=================================================================");
    end

endmodule : i2c_tb_top