////////////////////////////////////////////////////////////////////////////////
// Module: register_bank.v
// Description: I2C Register Bank Module
//              Implements all configuration, status, and data registers
//              for the I2C controller with read/write access.
// Author: AI Assistant
// Date: 2025
////////////////////////////////////////////////////////////////////////////////

module register_bank (
    // System interface
    input  wire        i_sys_clk,         // System clock
    input  wire        i_rst_n,           // Active low reset

    // Register access interface
    input  wire [3:0]  i_reg_addr,        // Register address (4-bit for 16 registers)
    input  wire [31:0] i_reg_wdata,       // Write data
    input  wire        i_reg_write,       // Write enable
    output wire [31:0] o_reg_rdata,       // Read data

    // Control outputs (from CTRL register)
    output wire        o_enable,          // IP enable
    output wire        o_start_tx,        // Start transmission
    output wire        o_stop_tx,         // Stop transmission
    output wire        o_ack_en,          // ACK enable
    output wire [1:0]  o_mode,            // Operation mode
    output wire        o_int_en,          // Interrupt enable
    output wire        o_sw_rst,          // Software reset

    // Status inputs (to STATUS register)
    input  wire        i_busy,            // IP busy
    input  wire        i_tx_done,         // Transmission complete
    input  wire        i_rx_done,         // Reception complete
    input  wire        i_arb_lost,        // Arbitration lost
    input  wire        i_nack,            // NACK received
    input  wire        i_bus_err,         // Bus error
    input  wire        i_start_det,       // START condition detected
    input  wire        i_stop_det,        // STOP condition detected

    // Data register interface
    output wire [7:0]  o_data_reg,        // Data register output
    input  wire [7:0]  i_data_reg,        // Data register input
    output wire [6:0]  o_addr_reg,        // Address register output

    // Configuration outputs
    output wire [31:0] o_config_reg,      // Configuration register
    output wire [31:0] o_timing_reg       // Timing register
);

    // Register definitions
    localparam REG_CTRL     = 4'h0;       // Control register
    localparam REG_STATUS   = 4'h1;       // Status register
    localparam REG_DATA     = 4'h2;       // Data register
    localparam REG_ADDR     = 4'h3;       // Address register
    localparam REG_CONFIG   = 4'h4;       // Configuration register
    localparam REG_TIMING   = 4'h5;       // Timing register

    // Register storage
    reg [31:0] ctrl_reg;                  // Control register
    reg [31:0] status_reg;                // Status register
    reg [7:0]  data_reg;                  // Data register
    reg [6:0]  addr_reg;                  // Address register
    reg [31:0] config_reg;                // Configuration register
    reg [31:0] timing_reg;                // Timing register

    // Read data multiplexer
    reg [31:0] read_data;
    assign o_reg_rdata = read_data;

    // Control register bit fields
    assign o_enable   = ctrl_reg[0];      // Bit 0: ENABLE
    assign o_start_tx = ctrl_reg[1];      // Bit 1: START
    assign o_stop_tx  = ctrl_reg[2];      // Bit 2: STOP
    assign o_ack_en   = ctrl_reg[3];      // Bit 3: ACK_EN
    assign o_mode     = ctrl_reg[5:4];    // Bits 5:4: MODE
    assign o_int_en   = ctrl_reg[6];      // Bit 6: INT_EN
    assign o_sw_rst   = ctrl_reg[7];      // Bit 7: RST

    // Status register bit fields
    wire [31:0] status_bits = {24'd0, i_stop_det, i_start_det, i_bus_err,
                                i_nack, i_arb_lost, i_rx_done, i_tx_done, i_busy};

    // Data and address outputs
    assign o_data_reg   = data_reg;
    assign o_addr_reg   = addr_reg;
    assign o_config_reg = config_reg;
    assign o_timing_reg = timing_reg;

    // Register write logic
    always @(posedge i_sys_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            // Reset all registers to default values
            ctrl_reg    <= 32'h00000000; // All disabled
            status_reg  <= 32'h00000000; // Clear all status
            data_reg    <= 8'h00;        // Clear data
            addr_reg    <= 7'h00;        // Clear address
            config_reg  <= 32'h00000000; // Default config
            timing_reg  <= 32'h00000000; // Default timing
        end else if (i_reg_write) begin
            case (i_reg_addr)
                REG_CTRL: begin
                    ctrl_reg <= i_reg_wdata;
                    // Clear start/stop bits after write (pulse)
                    ctrl_reg[1] <= 1'b0; // START
                    ctrl_reg[2] <= 1'b0; // STOP
                end
                REG_DATA: begin
                    data_reg <= i_reg_wdata[7:0];
                end
                REG_ADDR: begin
                    addr_reg <= i_reg_wdata[6:0];
                end
                REG_CONFIG: begin
                    config_reg <= i_reg_wdata;
                end
                REG_TIMING: begin
                    timing_reg <= i_reg_wdata;
                end
                // STATUS register is read-only
                default: begin
                    // No action for invalid addresses
                end
            endcase
        end else begin
            // Update status register with input signals
            status_reg <= status_bits;
        end
    end

    // Register read logic
    always @(*) begin
        case (i_reg_addr)
            REG_CTRL:   read_data = ctrl_reg;
            REG_STATUS: read_data = status_reg;
            REG_DATA:   read_data = {24'd0, data_reg};
            REG_ADDR:   read_data = {25'd0, addr_reg};
            REG_CONFIG: read_data = config_reg;
            REG_TIMING: read_data = timing_reg;
            default:    read_data = 32'h00000000; // Invalid address
        endcase
    end

endmodule