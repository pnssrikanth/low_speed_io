/**
 * I2C Protocol Monitor
 * Monitors I2C bus activity and captures protocol transactions
 */

// I2C Transaction structure
typedef struct {
    bit [6:0] address;           // 7-bit slave address
    bit [9:0] address_10bit;     // 10-bit slave address (if applicable)
    bit rw_bit;                  // Read/Write bit (0=write, 1=read)
    bit [7:0] data[];            // Array of data bytes
    bit ack[];                   // Array of ACK/NACK bits
    int num_bytes;               // Number of data bytes
    bit start_detected;          // START condition detected
    bit stop_detected;           // STOP condition detected
    bit arbitration_lost;        // Arbitration loss detected
    time start_time;             // Transaction start time
    time end_time;               // Transaction end time
} i2c_transaction;

class i2c_monitor;

    // Interface handle
    virtual i2c_if vif;

    // Mailbox for communication with scoreboard
    mailbox mon2sb;

    // Transaction counters
    int total_transactions;
    int read_transactions;
    int write_transactions;
    int error_transactions;

    // Current transaction being monitored
    i2c_transaction current_txn;

    /**
     * Constructor
     * @param vif - Virtual I2C interface
     * @param mon2sb - Mailbox to scoreboard
     */
    function new(virtual i2c_if vif, mailbox mon2sb);
        this.vif = vif;
        this.mon2sb = mon2sb;
        this.total_transactions = 0;
        this.read_transactions = 0;
        this.write_transactions = 0;
        this.error_transactions = 0;

        $display("[I2C_MON] I2C Monitor initialized");
    endfunction : new

    /**
     * Main monitoring task
     * Continuously monitors I2C bus for transactions
     */
    task run();
        $display("[I2C_MON] Starting I2C bus monitoring");

        forever begin
            // Wait for START condition
            wait_for_start_condition();

            // Capture transaction
            capture_transaction();

            // Send to scoreboard
            mon2sb.put(current_txn);

            // Update statistics
            update_statistics();

            $display("[I2C_MON] Transaction captured and sent to scoreboard");
        end
    endtask : run

    /**
     * Wait for START condition on I2C bus
     */
    task wait_for_start_condition();
        $display("[I2C_MON] Waiting for START condition");

        // Wait for SDA to go low while SCL is high
        @(negedge vif.sda);
        if (vif.scl) begin
            $display("[I2C_MON] START condition detected");
            current_txn.start_detected = 1'b1;
            current_txn.start_time = $time;
        end
    endtask : wait_for_start_condition

    /**
     * Capture complete I2C transaction
     */
    task capture_transaction();
        bit [7:0] addr_byte;
        bit ack_bit;

        $display("[I2C_MON] Capturing I2C transaction");

        // Initialize transaction
        current_txn = '{default: 0};
        current_txn.data = new[0];
        current_txn.ack = new[0];

        // Capture address byte
        capture_byte(addr_byte);
        current_txn.address = addr_byte[7:1];
        current_txn.rw_bit = addr_byte[0];

        // Send ACK for address
        capture_ack(ack_bit);
        current_txn.ack = new[1];
        current_txn.ack[0] = ack_bit;

        // Check if this is a read or write transaction
        if (current_txn.rw_bit) begin
            // Read transaction - capture data until STOP
            capture_read_data();
            read_transactions++;
        end else begin
            // Write transaction - capture data until STOP
            capture_write_data();
            write_transactions++;
        end

        // Wait for STOP condition
        wait_for_stop_condition();
        current_txn.stop_detected = 1'b1;
        current_txn.end_time = $time;

        total_transactions++;
    endtask : capture_transaction

    /**
     * Capture a single byte from I2C bus
     * @param byte_out - Captured byte
     */
    task capture_byte(output bit [7:0] byte_out);
        byte_out = 8'h00;

        $display("[I2C_MON] Capturing byte");

        // Capture 8 bits
        for (int i = 7; i >= 0; i--) begin
            @(posedge vif.scl);
            byte_out[i] = vif.sda;
        end

        $display("[I2C_MON] Byte captured: 0x%h", byte_out);
    endtask : capture_byte

    /**
     * Capture ACK/NACK bit
     * @param ack_out - ACK bit (0=ACK, 1=NACK)
     */
    task capture_ack(output bit ack_out);
        $display("[I2C_MON] Capturing ACK/NACK");

        // ACK/NACK is the 9th bit
        @(posedge vif.scl);
        ack_out = vif.sda;

        if (ack_out) begin
            $display("[I2C_MON] NACK received");
        end else begin
            $display("[I2C_MON] ACK received");
        end
    endtask : capture_ack

    /**
     * Capture data for read transaction
     */
    task capture_read_data();
        bit [7:0] data_byte;
        bit ack_bit;
        int byte_count = 0;

        $display("[I2C_MON] Capturing read transaction data");

        // Continue until STOP condition
        while (!current_txn.stop_detected) begin
            // Capture data byte
            capture_byte(data_byte);

            // Add to transaction data array
            current_txn.data = new[byte_count + 1](current_txn.data);
            current_txn.data[byte_count] = data_byte;
            byte_count++;

            // Capture ACK/NACK from master
            capture_ack(ack_bit);
            current_txn.ack = new[byte_count](current_txn.ack);
            current_txn.ack[byte_count - 1] = ack_bit;

            // Check for repeated START (Sr)
            if (check_repeated_start()) begin
                break;
            end
        end

        current_txn.num_bytes = byte_count;
        $display("[I2C_MON] Read transaction: %0d bytes captured", byte_count);
    endtask : capture_read_data

    /**
     * Capture data for write transaction
     */
    task capture_write_data();
        bit [7:0] data_byte;
        bit ack_bit;
        int byte_count = 0;

        $display("[I2C_MON] Capturing write transaction data");

        // Continue until STOP condition
        while (!current_txn.stop_detected) begin
            // Capture data byte
            capture_byte(data_byte);

            // Add to transaction data array
            current_txn.data = new[byte_count + 1](current_txn.data);
            current_txn.data[byte_count] = data_byte;
            byte_count++;

            // Capture ACK/NACK from slave
            capture_ack(ack_bit);
            current_txn.ack = new[byte_count](current_txn.ack);
            current_txn.ack[byte_count - 1] = ack_bit;

            // Check for repeated START (Sr)
            if (check_repeated_start()) begin
                break;
            end
        end

        current_txn.num_bytes = byte_count;
        $display("[I2C_MON] Write transaction: %0d bytes captured", byte_count);
    endtask : capture_write_data

    /**
     * Wait for STOP condition
     */
    task wait_for_stop_condition();
        $display("[I2C_MON] Waiting for STOP condition");

        // Wait for SDA to go high while SCL is high
        @(posedge vif.sda);
        if (vif.scl) begin
            $display("[I2C_MON] STOP condition detected");
        end
    endtask : wait_for_stop_condition

    /**
     * Check for repeated START condition
     * @return 1 if repeated START detected, 0 otherwise
     */
    function bit check_repeated_start();
        // Look for SDA going high then low while SCL is high
        if (vif.sda && vif.scl) begin
            // This could be a repeated START
            return 1'b1;
        end
        return 1'b0;
    endfunction : check_repeated_start

    /**
     * Update monitoring statistics
     */
    task update_statistics();
        $display("[I2C_MON] Transaction statistics updated");
        $display("[I2C_MON] Total transactions: %0d", total_transactions);
        $display("[I2C_MON] Read transactions: %0d", read_transactions);
        $display("[I2C_MON] Write transactions: %0d", write_transactions);
    endtask : update_statistics

    /**
     * Get monitoring statistics
     * @return String with statistics summary
     */
    function string get_statistics();
        string stats;
        $sformat(stats, "I2C Monitor Statistics:\n");
        $sformat(stats, "%s  Total Transactions: %0d\n", stats, total_transactions);
        $sformat(stats, "%s  Read Transactions: %0d\n", stats, read_transactions);
        $sformat(stats, "%s  Write Transactions: %0d\n", stats, write_transactions);
        $sformat(stats, "%s  Error Transactions: %0d\n", stats, error_transactions);
        return stats;
    endfunction : get_statistics

endclass : i2c_monitor