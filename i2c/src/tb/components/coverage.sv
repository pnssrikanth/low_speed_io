/**
 * Coverage Collection Component
 * Measures functional and code coverage metrics
 */

class coverage_collector;

    // Functional coverage groups
    covergroup i2c_protocol_cov;
        // Address coverage
        address_cp: coverpoint address {
            bins addr_7bit[16] = {[0:127]};
            bins addr_10bit[4] = {[0:1023]};
            bins reserved_addr = {0, 127};  // General call and reserved
        }

        // Read/Write operation coverage
        rw_cp: coverpoint rw_bit {
            bins read_op = {1};
            bins write_op = {0};
        }

        // Data value coverage
        data_cp: coverpoint data_byte {
            bins zero = {0};
            bins all_ones = {255};
            bins low_values[8] = {[1:31]};
            bins mid_values[8] = {[32:223]};
            bins high_values[8] = {[224:254]};
        }

        // Transaction length coverage
        length_cp: coverpoint num_bytes {
            bins single_byte = {1};
            bins small_transfer[3] = {[2:4]};
            bins medium_transfer[4] = {[5:16]};
            bins large_transfer[2] = {[17:64]};
            bins max_transfer = {65};
        }

        // ACK/NACK coverage
        ack_cp: coverpoint ack_bit {
            bins ack_received = {0};
            bins nack_received = {1};
        }

        // Speed mode coverage
        speed_cp: coverpoint speed_mode {
            bins standard_mode = {0};
            bins fast_mode = {1};
            bins fast_plus_mode = {2};
            bins high_speed_mode = {3};
        }

        // Cross coverage
        addr_x_rw: cross address_cp, rw_cp;
        data_x_ack: cross data_cp, ack_cp;
        length_x_speed: cross length_cp, speed_cp;
        rw_x_speed: cross rw_cp, speed_cp;
    endgroup

    // Register access coverage
    covergroup register_cov;
        reg_addr_cp: coverpoint reg_address {
            bins ctrl_reg = {'h00};
            bins status_reg = {'h04};
            bins int_en_reg = {'h08};
            bins int_status_reg = {'h0C};
            bins timing_reg = {'h10};
            bins addr_reg = {'h14};
            bins tx_data_reg = {'h18};
            bins rx_data_reg = {'h1C};
            bins fifo_status_reg = {'h20};
            bins fifo_thresh_reg = {'h24};
            bins error_reg = {'h28};
            bins diag_reg = {'h2C};
            bins safety_reg = {'h30};
            bins version_reg = {'h34};
        }

        reg_op_cp: coverpoint reg_operation {
            bins read_op = {0};
            bins write_op = {1};
        }

        reg_x_op: cross reg_addr_cp, reg_op_cp;
    endgroup

    // Interrupt coverage
    covergroup interrupt_cov;
        int_source_cp: coverpoint int_source {
            bins tx_done = {0};
            bins rx_done = {1};
            bins tx_thresh = {2};
            bins rx_thresh = {3};
            bins tx_empty = {4};
            bins rx_full = {5};
            bins addr_match = {6};
            bins arb_lost = {7};
            bins bus_error = {8};
            bins nack_error = {9};
        }

        int_action_cp: coverpoint int_action {
            bins int_asserted = {1};
            bins int_cleared = {0};
        }

        int_x_action: cross int_source_cp, int_action_cp;
    endgroup

    // Error condition coverage
    covergroup error_cov;
        error_type_cp: coverpoint error_type {
            bins arb_lost = {0};
            bins bus_error = {1};
            bins nack_error = {2};
            bins timeout_error = {3};
            bins crc_error = {4};
            bins parity_error = {5};
            bins overrun_error = {6};
        }

        error_recovery_cp: coverpoint error_recovery {
            bins auto_retry = {0};
            bins manual_retry = {1};
            bins abort_transaction = {2};
            bins reset_required = {3};
        }

        error_x_recovery: cross error_type_cp, error_recovery_cp;
    endgroup

    // Safety mechanism coverage
    covergroup safety_cov;
        safety_feature_cp: coverpoint safety_feature {
            bins watchdog = {0};
            bins ecc = {1};
            bins parity = {2};
            bins crc = {3};
            bins lockstep = {4};
            bins redundancy = {5};
        }

        safety_mode_cp: coverpoint safety_mode {
            bins normal_mode = {0};
            bins safety_mode = {1};
            bins diagnostic_mode = {2};
        }

        safety_x_mode: cross safety_feature_cp, safety_mode_cp;
    endgroup

    // Coverage statistics
    int total_samples;
    int protocol_samples;
    int register_samples;
    int interrupt_samples;
    int error_samples;
    int safety_samples;

    /**
     * Constructor
     * Initialize all coverage groups
     */
    function new();
        i2c_protocol_cov = new();
        register_cov = new();
        interrupt_cov = new();
        error_cov = new();
        safety_cov = new();

        total_samples = 0;
        protocol_samples = 0;
        register_samples = 0;
        interrupt_samples = 0;
        error_samples = 0;
        safety_samples = 0;

        $display("[COVERAGE] Coverage collector initialized");
    endfunction : new

    /**
     * Sample I2C protocol coverage
     * @param txn - I2C transaction to sample
     * @param speed - Current speed mode
     */
    function void sample_protocol(i2c_transaction txn, int speed);
        // Sample address
        i2c_protocol_cov.address_cp = txn.address;
        i2c_protocol_cov.rw_cp = txn.rw_bit;
        i2c_protocol_cov.length_cp = txn.num_bytes;
        i2c_protocol_cov.speed_cp = speed;

        // Sample data bytes
        foreach (txn.data[i]) begin
            i2c_protocol_cov.data_cp = txn.data[i];
        end

        // Sample ACK bits
        foreach (txn.ack[i]) begin
            i2c_protocol_cov.ack_cp = txn.ack[i];
        end

        protocol_samples++;
        total_samples++;

        $display("[COVERAGE] Sampled I2C protocol transaction");
    endfunction : sample_protocol

    /**
     * Sample register access coverage
     * @param addr - Register address
     * @param operation - Read (0) or Write (1)
     */
    function void sample_register(bit [31:0] addr, bit operation);
        register_cov.reg_addr_cp = addr;
        register_cov.reg_op_cp = operation;

        register_samples++;
        total_samples++;

        $display("[COVERAGE] Sampled register access: addr=0x%h, op=%s",
                addr, operation ? "write" : "read");
    endfunction : sample_register

    /**
     * Sample interrupt coverage
     * @param source - Interrupt source
     * @param action - Assert (1) or Clear (0)
     */
    function void sample_interrupt(int source, bit action);
        interrupt_cov.int_source_cp = source;
        interrupt_cov.int_action_cp = action;

        interrupt_samples++;
        total_samples++;

        $display("[COVERAGE] Sampled interrupt: source=%0d, action=%s",
                source, action ? "assert" : "clear");
    endfunction : sample_interrupt

    /**
     * Sample error condition coverage
     * @param error_type - Type of error
     * @param recovery - Recovery method used
     */
    function void sample_error(int error_type, int recovery);
        error_cov.error_type_cp = error_type;
        error_cov.error_recovery_cp = recovery;

        error_samples++;
        total_samples++;

        $display("[COVERAGE] Sampled error: type=%0d, recovery=%0d",
                error_type, recovery);
    endfunction : sample_error

    /**
     * Sample safety mechanism coverage
     * @param feature - Safety feature used
     * @param mode - Safety mode
     */
    function void sample_safety(int feature, int mode);
        safety_cov.safety_feature_cp = feature;
        safety_cov.safety_mode_cp = mode;

        safety_samples++;
        total_samples++;

        $display("[COVERAGE] Sampled safety feature: feature=%0d, mode=%0d",
                feature, mode);
    endfunction : sample_safety

    /**
     * Generate coverage report
     */
    function void generate_report();
        $display("\n");
        $display("=================================================================");
        $display("                    COVERAGE REPORT");
        $display("=================================================================");

        // Overall statistics
        $display("\nSAMPLING STATISTICS:");
        $display("Total Samples: %0d", total_samples);
        $display("Protocol Samples: %0d", protocol_samples);
        $display("Register Samples: %0d", register_samples);
        $display("Interrupt Samples: %0d", interrupt_samples);
        $display("Error Samples: %0d", error_samples);
        $display("Safety Samples: %0d", safety_samples);

        // Coverage percentages
        $display("\nCOVERAGE PERCENTAGES:");
        $display("I2C Protocol Coverage: %.2f%%", i2c_protocol_cov.get_coverage());
        $display("Register Access Coverage: %.2f%%", register_cov.get_coverage());
        $display("Interrupt Coverage: %.2f%%", interrupt_cov.get_coverage());
        $display("Error Handling Coverage: %.2f%%", error_cov.get_coverage());
        $display("Safety Mechanism Coverage: %.2f%%", safety_cov.get_coverage());

        // Overall coverage
        real overall_coverage = (
            i2c_protocol_cov.get_coverage() +
            register_cov.get_coverage() +
            interrupt_cov.get_coverage() +
            error_cov.get_coverage() +
            safety_cov.get_coverage()
        ) / 5.0;

        $display("Overall Functional Coverage: %.2f%%", overall_coverage);

        // Coverage holes analysis
        analyze_coverage_holes();

        $display("\n=================================================================");
    endfunction : generate_report

    /**
     * Analyze coverage holes
     */
    function void analyze_coverage_holes();
        $display("\nCOVERAGE HOLES ANALYSIS:");

        // Check for uncovered bins
        if (i2c_protocol_cov.get_coverage() < 90.0) begin
            $display("⚠️  I2C Protocol coverage below 90%");
            $display("   Missing coverage in: address ranges, data patterns, or speed modes");
        end

        if (register_cov.get_coverage() < 95.0) begin
            $display("⚠️  Register coverage below 95%");
            $display("   Missing coverage in: register access patterns or address ranges");
        end

        if (interrupt_cov.get_coverage() < 90.0) begin
            $display("⚠️  Interrupt coverage below 90%");
            $display("   Missing coverage in: interrupt sources or handling");
        end

        if (error_cov.get_coverage() < 85.0) begin
            $display("⚠️  Error handling coverage below 85%");
            $display("   Missing coverage in: error types or recovery methods");
        end

        if (safety_cov.get_coverage() < 90.0) begin
            $display("⚠️  Safety mechanism coverage below 90%");
            $display("   Missing coverage in: safety features or modes");
        end
    endfunction : analyze_coverage_holes

    /**
     * Get coverage summary
     * @return String with coverage summary
     */
    function string get_summary();
        string summary;
        real overall = (
            i2c_protocol_cov.get_coverage() +
            register_cov.get_coverage() +
            interrupt_cov.get_coverage() +
            error_cov.get_coverage() +
            safety_cov.get_coverage()
        ) / 5.0;

        $sformat(summary, "Coverage Summary: %.2f%% overall (%0d samples)",
                overall, total_samples);
        return summary;
    endfunction : get_summary

    /**
     * Check if coverage goals are met
     * @return 1 if goals met, 0 otherwise
     */
    function bit goals_met();
        return (
            i2c_protocol_cov.get_coverage() >= 90.0 &&
            register_cov.get_coverage() >= 95.0 &&
            interrupt_cov.get_coverage() >= 90.0 &&
            error_cov.get_coverage() >= 85.0 &&
            safety_cov.get_coverage() >= 90.0
        );
    endfunction : goals_met

    /**
     * Reset coverage statistics
     */
    function void reset();
        // Reset coverage groups
        i2c_protocol_cov = new();
        register_cov = new();
        interrupt_cov = new();
        error_cov = new();
        safety_cov = new();

        // Reset counters
        total_samples = 0;
        protocol_samples = 0;
        register_samples = 0;
        interrupt_samples = 0;
        error_samples = 0;
        safety_samples = 0;

        $display("[COVERAGE] Coverage statistics reset");
    endfunction : reset

endclass : coverage_collector