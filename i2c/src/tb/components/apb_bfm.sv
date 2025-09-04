/**
 * APB Bus Functional Model (BFM)
 * Provides high-level API for APB bus transactions
 */
class apb_bfm;

    // Interface handle
    virtual apb_if vif;

    // Transaction counters for statistics
    int total_transactions;
    int read_transactions;
    int write_transactions;
    int error_transactions;

    // Timing parameters
    int setup_time = 1;  // Setup time in ns
    int hold_time = 1;   // Hold time in ns

    /**
     * Constructor
     * @param vif - Virtual interface handle
     */
    function new(virtual apb_if vif);
        this.vif = vif;
        this.total_transactions = 0;
        this.read_transactions = 0;
        this.write_transactions = 0;
        this.error_transactions = 0;

        $display("[APB_BFM] Initialized APB Bus Functional Model");
    endfunction : new

    /**
     * Reset APB signals to default state
     */
    task reset_signals();
        vif.psel <= 1'b0;
        vif.penable <= 1'b0;
        vif.pwrite <= 1'b0;
        vif.paddr <= 32'h0;
        vif.pwdata <= 32'h0;
        $display("[APB_BFM] Reset all APB signals to default state");
    endtask : reset_signals

    /**
     * Write data to APB slave
     * @param addr - Address to write to
     * @param data - Data to write
     * @return 1 if successful, 0 if error
     */
    task automatic write_reg(input bit [31:0] addr, input bit [31:0] data);
        int success = 1;

        $display("[APB_BFM] Starting write transaction: addr=0x%h, data=0x%h", addr, data);

        // Setup phase
        @(posedge vif.pclk);
        vif.psel <= 1'b1;
        vif.penable <= 1'b0;
        vif.pwrite <= 1'b1;
        vif.paddr <= addr;
        vif.pwdata <= data;

        // Access phase
        @(posedge vif.pclk);
        vif.penable <= 1'b1;

        // Wait for slave ready
        while (!vif.pready) begin
            @(posedge vif.pclk);
        end

        // Check for errors
        if (vif.pslverr) begin
            $error("[APB_BFM] Write transaction failed: PSLVERR asserted at addr=0x%h", addr);
            success = 0;
            error_transactions++;
        end else begin
            $display("[APB_BFM] Write transaction completed successfully");
        end

        // End transaction
        vif.psel <= 1'b0;
        vif.penable <= 1'b0;

        // Update statistics
        total_transactions++;
        write_transactions++;

        // Return success status
        // Note: SystemVerilog tasks cannot return values directly in this context
    endtask : write_reg

    /**
     * Read data from APB slave
     * @param addr - Address to read from
     * @param data - Output data read
     * @return 1 if successful, 0 if error
     */
    task automatic read_reg(input bit [31:0] addr, output bit [31:0] data);
        int success = 1;

        $display("[APB_BFM] Starting read transaction: addr=0x%h", addr);

        // Setup phase
        @(posedge vif.pclk);
        vif.psel <= 1'b1;
        vif.penable <= 1'b0;
        vif.pwrite <= 1'b0;
        vif.paddr <= addr;

        // Access phase
        @(posedge vif.pclk);
        vif.penable <= 1'b1;

        // Wait for slave ready
        while (!vif.pready) begin
            @(posedge vif.pclk);
        end

        // Capture read data
        data = vif.prdata;

        // Check for errors
        if (vif.pslverr) begin
            $error("[APB_BFM] Read transaction failed: PSLVERR asserted at addr=0x%h", addr);
            success = 0;
            error_transactions++;
        end else begin
            $display("[APB_BFM] Read transaction completed: data=0x%h", data);
        end

        // End transaction
        vif.psel <= 1'b0;
        vif.penable <= 1'b0;

        // Update statistics
        total_transactions++;
        read_transactions++;

        // Return success status
        // Note: SystemVerilog tasks cannot return values directly in this context
    endtask : read_reg

    /**
     * Perform burst write operation
     * @param start_addr - Starting address
     * @param data_array - Array of data to write
     */
    task burst_write(input bit [31:0] start_addr, input bit [31:0] data_array[]);
        bit [31:0] current_addr = start_addr;

        $display("[APB_BFM] Starting burst write: %0d words starting at 0x%h",
                data_array.size(), start_addr);

        foreach (data_array[i]) begin
            write_reg(current_addr, data_array[i]);
            current_addr += 4; // Increment by word size
        end

        $display("[APB_BFM] Burst write completed");
    endtask : burst_write

    /**
     * Perform burst read operation
     * @param start_addr - Starting address
     * @param num_words - Number of words to read
     * @param data_array - Output array for read data
     */
    task burst_read(input bit [31:0] start_addr, input int num_words,
                   output bit [31:0] data_array[]);
        bit [31:0] current_addr = start_addr;
        data_array = new[num_words];

        $display("[APB_BFM] Starting burst read: %0d words starting at 0x%h",
                num_words, start_addr);

        for (int i = 0; i < num_words; i++) begin
            read_reg(current_addr, data_array[i]);
            current_addr += 4; // Increment by word size
        end

        $display("[APB_BFM] Burst read completed");
    endtask : burst_read

    /**
     * Wait for specified number of clock cycles
     * @param cycles - Number of clock cycles to wait
     */
    task wait_cycles(input int cycles);
        repeat (cycles) @(posedge vif.pclk);
    endtask : wait_cycles

    /**
     * Get transaction statistics
     * @return String with statistics summary
     */
    function string get_statistics();
        string stats;
        $sformat(stats, "APB BFM Statistics:\n");
        $sformat(stats, "%s  Total Transactions: %0d\n", stats, total_transactions);
        $sformat(stats, "%s  Read Transactions: %0d\n", stats, read_transactions);
        $sformat(stats, "%s  Write Transactions: %0d\n", stats, write_transactions);
        $sformat(stats, "%s  Error Transactions: %0d\n", stats, error_transactions);
        return stats;
    endfunction : get_statistics

endclass : apb_bfm