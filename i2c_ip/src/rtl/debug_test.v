////////////////////////////////////////////////////////////////////////////////
// Module: debug_test.v
// Description: I2C Debug and Test Interface Module
//              Provides debug access and test capabilities.
// Author: AI Assistant
// Date: 2025
////////////////////////////////////////////////////////////////////////////////

module debug_test (
    // System interface
    input  wire        i_sys_clk,         // System clock (from APB PCLK)
    input  wire        i_rst_n,           // Active low reset (from APB PRESETn)

    // JTAG interface (simplified)
    input  wire        i_tck,             // Test clock
    input  wire        i_tms,             // Test mode select
    input  wire        i_tdi,             // Test data in
    output wire        o_tdo,             // Test data out
    input  wire        i_trst_n,          // Test reset (active low)

    // Debug register interface
    input  wire [7:0]  i_dbg_addr,        // Debug register address
    input  wire [31:0] i_dbg_wdata,       // Debug write data
    input  wire        i_dbg_write,       // Debug write enable
    output wire [31:0] o_dbg_rdata,       // Debug read data

    // Internal signal probing
    input  wire [3:0]  i_current_state,   // Current FSM state
    input  wire        i_sda_in,          // SDA input
    input  wire        i_sda_out,         // SDA output
    input  wire        i_scl_in,          // SCL input
    input  wire        i_scl_out,         // SCL output
    input  wire [7:0]  i_shift_reg,       // Shift register value
    input  wire        i_busy,            // Busy status

    // Debug control outputs
    output reg         o_dbg_mode_en,     // Debug mode enable
    output reg         o_force_sda,       // Force SDA value
    output reg         o_force_scl,       // Force SCL value
    output reg         o_inject_error     // Error injection enable
);

    // Debug register definitions
    localparam [7:0] DBG_CTRL     = 8'h00;  // Debug control
    localparam [7:0] DBG_STATUS   = 8'h04;  // Debug status
    localparam [7:0] DBG_DATA     = 8'h08;  // Debug data access
    localparam [7:0] DBG_BREAK    = 8'h0C;  // Breakpoint configuration
    localparam [7:0] DBG_LOG      = 8'h10;  // Transaction log
    localparam [7:0] DBG_PROBE    = 8'h14;  // Signal probe

    // Internal registers
    reg [31:0] dbg_ctrl_reg;
    reg [31:0] dbg_status_reg;
    reg [31:0] dbg_data_reg;
    reg [31:0] dbg_break_reg;
    reg [31:0] dbg_log_reg;
    reg [31:0] dbg_probe_reg;

    // JTAG TAP controller states (simplified)
    localparam [3:0] TAP_RESET     = 4'h0;
    localparam [3:0] TAP_IDLE      = 4'h1;
    localparam [3:0] TAP_DR_SELECT = 4'h2;
    localparam [3:0] TAP_DR_CAPTURE= 4'h3;
    localparam [3:0] TAP_DR_SHIFT  = 4'h4;
    localparam [3:0] TAP_DR_EXIT1  = 4'h5;
    localparam [3:0] TAP_DR_PAUSE  = 4'h6;
    localparam [3:0] TAP_DR_EXIT2  = 4'h7;
    localparam [3:0] TAP_DR_UPDATE = 4'h8;
    localparam [3:0] TAP_IR_SELECT = 4'h9;
    localparam [3:0] TAP_IR_CAPTURE= 4'hA;
    localparam [3:0] TAP_IR_SHIFT  = 4'hB;
    localparam [3:0] TAP_IR_EXIT1  = 4'hC;
    localparam [3:0] TAP_IR_PAUSE  = 4'hD;
    localparam [3:0] TAP_IR_EXIT2  = 4'hE;
    localparam [3:0] TAP_IR_UPDATE = 4'hF;

    reg [3:0] tap_state;
    reg [31:0] jtag_shift_reg;
    reg [7:0]  jtag_ir;  // Instruction register

    // TAP controller
    always @(posedge i_tck or negedge i_trst_n) begin
        if (!i_trst_n) begin
            tap_state <= TAP_RESET;
            jtag_ir   <= 8'h00;
        end else begin
            case (tap_state)
                TAP_RESET: begin
                    if (!i_tms) tap_state <= TAP_IDLE;
                end

                TAP_IDLE: begin
                    if (i_tms) tap_state <= TAP_DR_SELECT;
                    else tap_state <= TAP_IDLE;
                end

                TAP_DR_SELECT: begin
                    if (i_tms) tap_state <= TAP_IR_SELECT;
                    else tap_state <= TAP_DR_CAPTURE;
                end

                TAP_IR_SELECT: begin
                    if (i_tms) tap_state <= TAP_RESET;
                    else tap_state <= TAP_IR_CAPTURE;
                end

                TAP_DR_CAPTURE: begin
                    tap_state <= TAP_DR_SHIFT;
                end

                TAP_IR_CAPTURE: begin
                    jtag_ir <= 8'h01;  // Default instruction
                    tap_state <= TAP_IR_SHIFT;
                end

                TAP_DR_SHIFT: begin
                    if (i_tms) tap_state <= TAP_DR_EXIT1;
                    else tap_state <= TAP_DR_SHIFT;
                end

                TAP_IR_SHIFT: begin
                    if (i_tms) tap_state <= TAP_IR_EXIT1;
                    else tap_state <= TAP_IR_SHIFT;
                end

                TAP_DR_EXIT1: begin
                    if (i_tms) tap_state <= TAP_DR_UPDATE;
                    else tap_state <= TAP_DR_PAUSE;
                end

                TAP_IR_EXIT1: begin
                    if (i_tms) tap_state <= TAP_IR_UPDATE;
                    else tap_state <= TAP_IR_PAUSE;
                end

                TAP_DR_PAUSE: begin
                    if (i_tms) tap_state <= TAP_DR_EXIT2;
                    else tap_state <= TAP_DR_PAUSE;
                end

                TAP_IR_PAUSE: begin
                    if (i_tms) tap_state <= TAP_IR_EXIT2;
                    else tap_state <= TAP_IR_PAUSE;
                end

                TAP_DR_EXIT2: begin
                    if (i_tms) tap_state <= TAP_DR_UPDATE;
                    else tap_state <= TAP_DR_SHIFT;
                end

                TAP_IR_EXIT2: begin
                    if (i_tms) tap_state <= TAP_IR_UPDATE;
                    else tap_state <= TAP_IR_SHIFT;
                end

                TAP_DR_UPDATE: begin
                    if (i_tms) tap_state <= TAP_DR_SELECT;
                    else tap_state <= TAP_IDLE;
                end

                TAP_IR_UPDATE: begin
                    if (i_tms) tap_state <= TAP_DR_SELECT;
                    else tap_state <= TAP_IDLE;
                end

                default: tap_state <= TAP_RESET;
            endcase
        end
    end

    // JTAG data shifting
    always @(posedge i_tck) begin
        if (tap_state == TAP_DR_SHIFT) begin
            jtag_shift_reg <= {i_tdi, jtag_shift_reg[31:1]};
        end else if (tap_state == TAP_IR_SHIFT) begin
            jtag_ir <= {i_tdi, jtag_ir[7:1]};
        end
    end

    // TDO output
    assign o_tdo = (tap_state == TAP_DR_SHIFT) ? jtag_shift_reg[0] :
                   (tap_state == TAP_IR_SHIFT) ? jtag_ir[0] : 1'b0;

    // Debug register access
    always @(posedge i_sys_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            dbg_ctrl_reg   <= 32'h00000000;
            dbg_status_reg <= 32'h00000000;
            dbg_data_reg   <= 32'h00000000;
            dbg_break_reg  <= 32'h00000000;
            dbg_log_reg    <= 32'h00000000;
            dbg_probe_reg  <= 32'h00000000;
            o_dbg_mode_en  <= 1'b0;
            o_force_sda    <= 1'b0;
            o_force_scl    <= 1'b0;
            o_inject_error <= 1'b0;
        end else if (i_dbg_write) begin
            case (i_dbg_addr)
                DBG_CTRL: begin
                    dbg_ctrl_reg  <= i_dbg_wdata;
                    o_dbg_mode_en <= i_dbg_wdata[0];
                    o_force_sda   <= i_dbg_wdata[1];
                    o_force_scl   <= i_dbg_wdata[2];
                    o_inject_error<= i_dbg_wdata[3];
                end
                DBG_DATA:  dbg_data_reg  <= i_dbg_wdata;
                DBG_BREAK: dbg_break_reg <= i_dbg_wdata;
                default: ; // No action
            endcase
        end else begin
            // Update status and probe registers
            dbg_status_reg <= {28'd0, i_busy, i_current_state};
            dbg_probe_reg  <= {16'd0, i_scl_out, i_scl_in, i_sda_out, i_sda_in, i_shift_reg};
        end
    end

    // Debug read data
    reg [31:0] dbg_read_data;
    assign o_dbg_rdata = dbg_read_data;

    always @(*) begin
        case (i_dbg_addr)
            DBG_CTRL:   dbg_read_data = dbg_ctrl_reg;
            DBG_STATUS: dbg_read_data = dbg_status_reg;
            DBG_DATA:   dbg_read_data = dbg_data_reg;
            DBG_BREAK:  dbg_read_data = dbg_break_reg;
            DBG_LOG:    dbg_read_data = dbg_log_reg;
            DBG_PROBE:  dbg_read_data = dbg_probe_reg;
            default:    dbg_read_data = 32'h00000000;
        endcase
    end

endmodule