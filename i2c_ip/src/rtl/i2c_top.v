////////////////////////////////////////////////////////////////////////////////
// Module: i2c_top.v
// Description: I2C Controller Top-Level Module
//              Integrates all I2C sub-modules into a complete controller.
//              Implements AMBA APB (Advanced Peripheral Bus) interface.
// Author: AI Assistant
// Date: 2025
////////////////////////////////////////////////////////////////////////////////

module i2c_top #(
    parameter CLK_DIV = 100,              // Default clock divider
    parameter STRETCH_EN = 1,             // Clock stretching enable
    parameter DATA_WIDTH = 8,             // Data width
    parameter SHIFT_DIR = 0               // Shift direction (0: LSB first)
)(
    // APB Interface (AMBA APB Protocol)
    input  wire        PCLK,              // APB clock
    input  wire        PRESETn,           // APB reset (active low)
    input  wire [31:0] PADDR,             // APB address
    input  wire        PSEL,              // APB select
    input  wire        PENABLE,           // APB enable
    input  wire        PWRITE,            // APB write enable
    input  wire [31:0] PWDATA,            // APB write data
    output wire [31:0] PRDATA,            // APB read data
    output wire        PREADY,            // APB ready
    output wire        PSLVERR,           // APB slave error

    // I2C bus interface
    input  wire        i_sda_in,          // SDA input from buffer
    input  wire        i_scl_in,          // SCL input from buffer
    output wire        o_sda_out,         // SDA output to buffer
    output wire        o_sda_oe,          // SDA output enable
    output wire        o_scl_out,         // SCL output to buffer
    output wire        o_scl_oe,          // SCL output enable

    // Interrupt interface
    output wire        o_irq              // Interrupt request
);

    // Internal signals
    wire        enable;
    wire        start_tx;
    wire        stop_tx;
    wire        ack_en;
    wire [1:0]  mode;
    wire        int_en;
    wire        sw_rst;

    wire        busy;
    wire        tx_done;
    wire        rx_done;
    wire        arb_lost;
    wire        nack;
    wire        bus_err;
    wire        start_det;
    wire        stop_det;

    wire [7:0]  data_reg_out;
    wire [7:0]  data_reg_in;
    wire [6:0]  addr_reg;

    wire [31:0] config_reg;
    wire [31:0] timing_reg;

    wire        shift_load;
    wire        shift_en;
    wire        rw_mode;
    wire        shift_done;
    wire        ack_received;
    wire        data_valid;
    wire [7:0]  data_out;

    wire        stretch_req;
    wire [15:0] divider;
    wire [1:0]  speed_mode;

    // APB State Machine
    localparam APB_IDLE   = 2'b00;
    localparam APB_SETUP  = 2'b01;
    localparam APB_ACCESS = 2'b10;

    reg [1:0] apb_state;
    reg [31:0] apb_addr_reg;
    reg [31:0] apb_wdata_reg;
    reg        apb_write_reg;
    reg        apb_ready_reg;
    reg        apb_slverr_reg;

    // Register access control
    wire [3:0]  reg_addr;
    wire [31:0] reg_wdata;
    wire        reg_write;
    wire [31:0] reg_rdata;

    // APB state machine
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            apb_state      <= APB_IDLE;
            apb_addr_reg   <= 32'h0;
            apb_wdata_reg  <= 32'h0;
            apb_write_reg  <= 1'b0;
            apb_ready_reg  <= 1'b1;
            apb_slverr_reg <= 1'b0;
        end else begin
            case (apb_state)
                APB_IDLE: begin
                    apb_ready_reg  <= 1'b1;
                    apb_slverr_reg <= 1'b0;
                    if (PSEL && !PENABLE) begin
                        apb_state     <= APB_SETUP;
                        apb_addr_reg  <= PADDR;
                        apb_wdata_reg <= PWDATA;
                        apb_write_reg <= PWRITE;
                    end
                end

                APB_SETUP: begin
                    if (PSEL && PENABLE) begin
                        apb_state <= APB_ACCESS;
                        // Check for valid address range (0x00-0x14 for registers)
                        if (apb_addr_reg[7:0] > 8'h14) begin
                            apb_slverr_reg <= 1'b1;
                        end else begin
                            apb_slverr_reg <= 1'b0;
                        end
                        apb_ready_reg <= 1'b1;  // Single cycle access
                    end else if (!PSEL) begin
                        apb_state <= APB_IDLE;
                    end
                end

                APB_ACCESS: begin
                    apb_state <= APB_IDLE;
                    apb_ready_reg <= 1'b1;
                end

                default: begin
                    apb_state <= APB_IDLE;
                end
            endcase
        end
    end

    // APB interface signals
    assign reg_addr   = apb_addr_reg[3:0];  // Use lower 4 bits for register address
    assign reg_wdata  = apb_wdata_reg;
    assign reg_write  = apb_write_reg && (apb_state == APB_ACCESS) && !apb_slverr_reg;

    assign PRDATA     = reg_rdata;
    assign PREADY     = apb_ready_reg;
    assign PSLVERR    = apb_slverr_reg;

    // Extract configuration from registers
    assign divider    = timing_reg[15:0];
    assign speed_mode = config_reg[1:0];

    // Instantiate Register Bank
    register_bank u_register_bank (
        .i_sys_clk      (PCLK),
        .i_rst_n        (PRESETn && !sw_rst),  // Software reset

        .i_reg_addr     (reg_addr),
        .i_reg_wdata    (reg_wdata),
        .i_reg_write    (reg_write),
        .o_reg_rdata    (reg_rdata),

        .o_enable       (enable),
        .o_start_tx     (start_tx),
        .o_stop_tx      (stop_tx),
        .o_ack_en       (ack_en),
        .o_mode         (mode),
        .o_int_en       (int_en),
        .o_sw_rst       (sw_rst),

        .i_busy         (busy),
        .i_tx_done      (tx_done),
        .i_rx_done      (rx_done),
        .i_arb_lost     (arb_lost),
        .i_nack         (nack),
        .i_bus_err      (bus_err),
        .i_start_det    (start_det),
        .i_stop_det     (stop_det),

        .o_data_reg     (data_reg_out),
        .i_data_reg     (data_out),
        .o_addr_reg     (addr_reg),

        .o_config_reg   (config_reg),
        .o_timing_reg   (timing_reg)
    );

    // Instantiate Control FSM
    control_fsm u_control_fsm (
        .i_sys_clk      (PCLK),
        .i_rst_n        (PRESETn),

        .i_enable       (enable),
        .i_mode         (mode),
        .i_start_tx     (start_tx),
        .i_stop_tx      (stop_tx),
        .i_ack_en       (ack_en),

        .i_sda_in       (i_sda_in),
        .i_scl_in       (i_scl_in),
        .o_sda_out      (o_sda_out),
        .o_sda_oe       (o_sda_oe),
        .o_scl_out      (o_scl_out),
        .o_scl_oe       (o_scl_oe),

        .o_shift_load   (shift_load),
        .o_shift_en     (shift_en),
        .o_rw_mode      (rw_mode),
        .i_shift_done   (shift_done),
        .i_ack_received (ack_received),

        .i_data_reg     (data_reg_out),
        .i_addr_reg     (addr_reg),
        .o_data_valid   (data_valid),
        .o_data_out     (data_out),

        .o_busy         (busy),
        .o_tx_done      (tx_done),
        .o_rx_done      (rx_done),
        .o_arb_lost     (arb_lost),
        .o_nack         (nack),
        .o_bus_err      (bus_err),
        .o_start_det    (start_det),
        .o_stop_det     (stop_det),

        .o_stretch_req  (stretch_req)
    );

    // Instantiate Shift Register
    shift_register #(
        .DATA_WIDTH     (DATA_WIDTH),
        .SHIFT_DIR      (SHIFT_DIR)
    ) u_shift_register (
        .i_sys_clk      (PCLK),
        .i_rst_n        (PRESETn),

        .i_load_data    (shift_load),
        .i_shift_en     (shift_en),
        .i_rw_mode      (rw_mode),
        .i_ack_en       (ack_en),

        .i_parallel_in  (data_reg_out),
        .o_parallel_out (data_out),
        .i_serial_in    (i_sda_in),
        .o_serial_out   (),  // Connected through FSM
        .o_ack_bit      (),

        .o_shift_done   (shift_done),
        .o_data_valid   (),
        .o_ack_received (ack_received)
    );

    // Instantiate Clock Manager
    clock_manager #(
        .CLK_DIV        (CLK_DIV),
        .STRETCH_EN     (STRETCH_EN)
    ) u_clock_manager (
        .i_sys_clk      (PCLK),
        .i_rst_n        (PRESETn),
        .i_enable       (enable),
        .i_stretch_req  (stretch_req),

        .o_scl_out      (),  // Connected through FSM
        .o_scl_oe       (),  // Connected through FSM
        .o_timing_valid (),

        .i_divider      (divider),
        .i_speed_mode   (speed_mode)
    );

    // Interrupt generation
    assign o_irq = int_en && (tx_done || rx_done || arb_lost || nack || bus_err || start_det || stop_det);

endmodule