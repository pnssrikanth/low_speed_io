/**
 * I2C Interface Definition
 * Defines the signals for I2C protocol communication
 */
interface i2c_if;

    // I2C bus signals
    logic scl;        // Serial clock line
    logic sda;        // Serial data line
    logic scl_oe;     // SCL output enable
    logic sda_oe;     // SDA output enable

    // Control signals for external I/O buffers
    logic scl_in;     // SCL input from buffer
    logic sda_in;     // SDA input from buffer
    logic scl_out;    // SCL output to buffer
    logic sda_out;    // SDA output to buffer

    // Internal signals for monitoring
    logic start_detected;    // START condition detected
    logic stop_detected;     // STOP condition detected
    logic arbitration_lost;  // Arbitration loss detected

    // Clocking block for I2C timing
    clocking cb_i2c @(posedge scl);
        default input #1ns output #1ns;
        input sda;
        output scl_out, sda_out, scl_oe, sda_oe;
    endclocking

    // Modports for different usage contexts
    modport master (
        clocking cb_i2c,
        output scl_out, sda_out, scl_oe, sda_oe,
        input scl_in, sda_in, start_detected, stop_detected
    );

    modport slave (
        clocking cb_i2c,
        input scl_in, sda_in,
        output scl_out, sda_out, scl_oe, sda_oe
    );

    modport monitor (
        input scl, sda, scl_in, sda_in,
        input start_detected, stop_detected, arbitration_lost
    );

    // I2C timing parameters (in clock cycles)
    parameter SCL_LOW_TIME = 50;    // SCL low time for 100kHz @ 10MHz
    parameter SCL_HIGH_TIME = 50;   // SCL high time for 100kHz @ 10MHz
    parameter START_HOLD_TIME = 47; // START condition hold time
    parameter STOP_SETUP_TIME = 40; // STOP condition setup time
    parameter DATA_SETUP_TIME = 25; // Data setup time
    parameter DATA_HOLD_TIME = 0;   // Data hold time

endinterface : i2c_if