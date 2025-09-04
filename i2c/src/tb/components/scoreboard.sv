/**
 * Scoreboard Component
 * Compares expected vs actual transactions and tracks verification results
 */

class scoreboard;

    // Mailboxes for communication
    mailbox mon2sb;      // From monitor
    mailbox drv2sb;      // From driver (expected transactions)

    // Statistics counters
    int total_transactions;
    int passed_transactions;
    int failed_transactions;
    int error_transactions;

    // Transaction queues
    i2c_transaction expected_queue[$];
    i2c_transaction actual_queue[$];

    // Results storage
    typedef struct {
        int id;
        time timestamp;
        bit success;
        string description;
        bit [31:0] expected_data;
        bit [31:0] actual_data;
        string error_message;
    } test_result;

    test_result results[$];

    /**
     * Constructor
     * @param mon2sb - Mailbox from monitor (actual transactions)
     * @param drv2sb - Mailbox from driver (expected transactions)
     */
    function new(mailbox mon2sb, mailbox drv2sb);
        this.mon2sb = mon2sb;
        this.drv2sb = drv2sb;
        this.total_transactions = 0;
        this.passed_transactions = 0;
        this.failed_transactions = 0;
        this.error_transactions = 0;

        $display("[SCOREBOARD] Scoreboard initialized");
    endfunction : new

    /**
     * Main scoreboard task
     * Continuously processes transactions from monitor and driver
     */
    task run();
        i2c_transaction expected_txn, actual_txn;

        $display("[SCOREBOARD] Starting scoreboard processing");

        forever begin
            // Get expected transaction from driver
            drv2sb.get(expected_txn);
            expected_queue.push_back(expected_txn);

            // Get actual transaction from monitor
            mon2sb.get(actual_txn);
            actual_queue.push_back(actual_txn);

            // Compare transactions
            compare_transactions(expected_txn, actual_txn);

            // Update statistics
            total_transactions++;
        end
    endtask : run

    /**
     * Compare expected and actual transactions
     * @param expected - Expected transaction
     * @param actual - Actual transaction
     */
    task compare_transactions(i2c_transaction expected, i2c_transaction actual);
        bit transaction_pass = 1'b1;
        string error_msg = "";

        $display("[SCOREBOARD] Comparing transactions");
        $display("[SCOREBOARD] Expected: addr=0x%h, rw=%b, bytes=%0d",
                expected.address, expected.rw_bit, expected.num_bytes);
        $display("[SCOREBOARD] Actual:   addr=0x%h, rw=%b, bytes=%0d",
                actual.address, actual.rw_bit, actual.num_bytes);

        // Compare basic transaction parameters
        if (expected.address != actual.address) begin
            transaction_pass = 1'b0;
            $sformat(error_msg, "%s Address mismatch: expected 0x%h, got 0x%h",
                    error_msg, expected.address, actual.address);
        end

        if (expected.rw_bit != actual.rw_bit) begin
            transaction_pass = 1'b0;
            $sformat(error_msg, "%s R/W bit mismatch: expected %b, got %b",
                    error_msg, expected.rw_bit, actual.rw_bit);
        end

        if (expected.num_bytes != actual.num_bytes) begin
            transaction_pass = 1'b0;
            $sformat(error_msg, "%s Byte count mismatch: expected %0d, got %0d",
                    error_msg, expected.num_bytes, actual.num_bytes);
        end

        // Compare data bytes if present
        if (expected.num_bytes > 0 && actual.num_bytes > 0) begin
            for (int i = 0; i < expected.num_bytes && i < actual.num_bytes; i++) begin
                if (expected.data[i] != actual.data[i]) begin
                    transaction_pass = 1'b0;
                    $sformat(error_msg, "%s Data[%0d] mismatch: expected 0x%h, got 0x%h",
                            error_msg, i, expected.data[i], actual.data[i]);
                end
            end
        end

        // Compare ACK bits if present
        if (expected.ack.size() > 0 && actual.ack.size() > 0) begin
            for (int i = 0; i < expected.ack.size() && i < actual.ack.size(); i++) begin
                if (expected.ack[i] != actual.ack[i]) begin
                    transaction_pass = 1'b0;
                    $sformat(error_msg, "%s ACK[%0d] mismatch: expected %b, got %b",
                            error_msg, i, expected.ack[i], actual.ack[i]);
                end
            end
        end

        // Record result
        record_result(transaction_pass, error_msg, expected, actual);

        // Update counters
        if (transaction_pass) begin
            passed_transactions++;
            $display("[SCOREBOARD] ✓ Transaction PASSED");
        end else begin
            failed_transactions++;
            $error("[SCOREBOARD] ✗ Transaction FAILED: %s", error_msg);
        end
    endtask : compare_transactions

    /**
     * Record test result
     * @param success - Whether test passed
     * @param error_msg - Error message if failed
     * @param expected - Expected transaction
     * @param actual - Actual transaction
     */
    task record_result(bit success, string error_msg,
                      i2c_transaction expected, i2c_transaction actual);
        test_result result;

        result.id = total_transactions + 1;
        result.timestamp = $time;
        result.success = success;
        result.description = $sformatf("I2C Transaction %0d", result.id);
        result.error_message = error_msg;

        // Store first data byte for summary
        if (expected.num_bytes > 0) begin
            result.expected_data = expected.data[0];
        end
        if (actual.num_bytes > 0) begin
            result.actual_data = actual.data[0];
        end

        results.push_back(result);
    endtask : record_result

    /**
     * Generate detailed test report
     */
    function void generate_report();
        real pass_rate;

        $display("\n");
        $display("=================================================================");
        $display("                    SCOREBOARD TEST REPORT");
        $display("=================================================================");

        // Summary statistics
        $display("\nSUMMARY STATISTICS:");
        $display("Total Transactions: %0d", total_transactions);
        $display("Passed Transactions: %0d", passed_transactions);
        $display("Failed Transactions: %0d", failed_transactions);
        $display("Error Transactions: %0d", error_transactions);

        if (total_transactions > 0) begin
            pass_rate = (passed_transactions * 100.0) / total_transactions;
            $display("Pass Rate: %.2f%%", pass_rate);
        end

        // Detailed results
        $display("\nDETAILED RESULTS:");
        $display("%-5s %-12s %-8s %-s", "ID", "Time", "Result", "Description");
        $display("----- ------------ -------- ------------------------------");

        foreach (results[i]) begin
            string result_str = results[i].success ? "PASS" : "FAIL";
            $display("%-5d %-12t %-8s %-s",
                    results[i].id,
                    results[i].timestamp,
                    result_str,
                    results[i].description);

            if (!results[i].success && results[i].error_message.len() > 0) begin
                $display("      Error: %s", results[i].error_message);
            end
        end

        // Performance metrics
        $display("\nPERFORMANCE METRICS:");
        if (results.size() > 1) begin
            time total_time = results[$].timestamp - results[0].timestamp;
            real avg_time = total_time / results.size();
            $display("Total Test Time: %0t", total_time);
            $display("Average Transaction Time: %.2f ns", avg_time);
        end

        $display("\n=================================================================");
    endfunction : generate_report

    /**
     * Get summary statistics
     * @return String with summary
     */
    function string get_summary();
        string summary;
        real pass_rate = 0.0;

        if (total_transactions > 0) begin
            pass_rate = (passed_transactions * 100.0) / total_transactions;
        end

        $sformat(summary, "Scoreboard Summary: %0d/%0d transactions passed (%.2f%%)",
                passed_transactions, total_transactions, pass_rate);
        return summary;
    endfunction : get_summary

    /**
     * Check if all transactions passed
     * @return 1 if all passed, 0 otherwise
     */
    function bit all_passed();
        return (failed_transactions == 0 && error_transactions == 0);
    endfunction : all_passed

    /**
     * Reset scoreboard statistics
     */
    function void reset();
        total_transactions = 0;
        passed_transactions = 0;
        failed_transactions = 0;
        error_transactions = 0;
        expected_queue.delete();
        actual_queue.delete();
        results.delete();

        $display("[SCOREBOARD] Statistics reset");
    endfunction : reset

endclass : scoreboard