// Basic testbench for i2c_top
module i2c_top_tb;

    // Testbench signals
    reg         PCLK;
    reg         PRESETn;
    reg [31:0]  PADDR;
    reg         PSEL;
    reg         PENABLE;
    reg         PWRITE;
    reg [31:0]  PWDATA;
    wire [31:0] PRDATA;
    wire        PREADY;
    wire        PSLVERR;

    reg         i_sda_in;
    reg         i_scl_in;
    wire        o_sda_out;
    wire        o_sda_oe;
    wire        o_scl_out;
    wire        o_scl_oe;

    wire        o_irq;

    // Instantiate DUT
    i2c_top dut (
        .PCLK       (PCLK),
        .PRESETn    (PRESETn),
        .PADDR      (PADDR),
        .PSEL       (PSEL),
        .PENABLE    (PENABLE),
        .PWRITE     (PWRITE),
        .PWDATA     (PWDATA),
        .PRDATA     (PRDATA),
        .PREADY     (PREADY),
        .PSLVERR    (PSLVERR),
        .i_sda_in   (i_sda_in),
        .i_scl_in   (i_scl_in),
        .o_sda_out  (o_sda_out),
        .o_sda_oe   (o_sda_oe),
        .o_scl_out  (o_scl_out),
        .o_scl_oe   (o_scl_oe),
        .o_irq      (o_irq)
    );

    // Clock generation
    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;
    end

    // Test sequence
    initial begin
        // Reset
        PRESETn = 0;
        PSEL = 0;
        PENABLE = 0;
        PWRITE = 0;
        PADDR = 0;
        PWDATA = 0;
        i_sda_in = 1;
        i_scl_in = 1;
        #20;
        PRESETn = 1;
        #20;

        // Write to control register to enable
        PADDR = 4'h0;
        PWDATA = 32'h00000001; // Enable
        PWRITE = 1;
        PSEL = 1;
        #10;
        PENABLE = 1;
        #10;
        PSEL = 0;
        PENABLE = 0;
        #20;

        // Write to address register
        PADDR = 4'h3;
        PWDATA = 32'h00000050; // Address 0x50
        PWRITE = 1;
        PSEL = 1;
        #10;
        PENABLE = 1;
        #10;
        PSEL = 0;
        PENABLE = 0;
        #20;

        // Write to data register
        PADDR = 4'h2;
        PWDATA = 32'h000000AA; // Data 0xAA
        PWRITE = 1;
        PSEL = 1;
        #10;
        PENABLE = 1;
        #10;
        PSEL = 0;
        PENABLE = 0;
        #20;

        // Start transmission
        PADDR = 4'h0;
        PWDATA = 32'h00000003; // Start TX
        PWRITE = 1;
        PSEL = 1;
        #10;
        PENABLE = 1;
        #10;
        PSEL = 0;
        PENABLE = 0;
        #100;

        $finish;
    end

endmodule