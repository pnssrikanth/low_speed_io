/**
 * APB Interface Definition
 * Defines the signals for AMBA APB protocol communication
 */
interface apb_if (
    input logic pclk,      // APB clock
    input logic presetn    // APB reset (active low)
);

    // APB Master to Slave signals
    logic        psel;     // Peripheral select
    logic        penable;  // Peripheral enable
    logic        pwrite;   // Write enable (1=write, 0=read)
    logic [31:0] paddr;    // Address bus
    logic [31:0] pwdata;   // Write data bus

    // APB Slave to Master signals
    logic [31:0] prdata;   // Read data bus
    logic        pready;   // Ready signal
    logic        pslverr;  // Slave error

    // Clocking blocks for synchronous operation
    clocking cb_master @(posedge pclk);
        default input #1ns output #1ns;
        output psel, penable, pwrite, paddr, pwdata;
        input prdata, pready, pslverr;
    endclocking

    clocking cb_slave @(posedge pclk);
        default input #1ns output #1ns;
        input psel, penable, pwrite, paddr, pwdata;
        output prdata, pready, pslverr;
    endclocking

    // Modports for different usage contexts
    modport master (
        clocking cb_master,
        output psel, penable, pwrite, paddr, pwdata,
        input prdata, pready, pslverr
    );

    modport slave (
        clocking cb_slave,
        input psel, penable, pwrite, paddr, pwdata,
        output prdata, pready, pslverr
    );

    modport passive (
        input psel, penable, pwrite, paddr, pwdata,
        input prdata, pready, pslverr
    );

endinterface : apb_if