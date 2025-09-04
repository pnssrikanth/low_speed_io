////////////////////////////////////////////////////////////////////////////////
// Module: clock_manager.v
// Description: I2C Clock Manager Module
//              Generates SCL clock signals with configurable frequency and
//              supports clock stretching for I2C protocol compliance.
// Author: AI Assistant
// Date: 2025
////////////////////////////////////////////////////////////////////////////////

module clock_manager #(
    /* verilator lint_off UNUSEDPARAM */
    parameter CLK_DIV = 100,      // Clock divider for SCL frequency (default 100 for 100kHz at 10MHz sys clk)
    /* verilator lint_on UNUSEDPARAM */
    parameter STRETCH_EN = 1      // Enable clock stretching (1: enabled, 0: disabled)
)(
    // System interface
    input  wire        i_sys_clk,         // System clock input (from APB PCLK)
    input  wire        i_rst_n,           // Active low reset (from APB PRESETn)
    input  wire        i_enable,          // Module enable
    input  wire        i_stretch_req,     // Clock stretching request from slave

    // I2C interface
    output reg         o_scl_out,         // SCL output to I/O buffer
    output reg         o_scl_oe,          // SCL output enable
    output wire        o_timing_valid,    // Timing validation signal

    // Control interface
    input  wire [15:0] i_divider,         // Dynamic clock divider value
    input  wire [1:0]  i_speed_mode       // Speed mode (00: Standard, 01: Fast, 10: Fast+, 11: HS)
);

    // Internal registers
    reg [15:0] clk_counter;               // Clock divider counter
    reg [15:0] divider_reg;               // Current divider value
    reg        scl_toggle;                // SCL toggle flag
    reg        stretch_active;            // Clock stretching active flag
    reg        timing_error;              // Timing validation error

    // Clock divider selection based on speed mode
    localparam [15:0] DIV_STANDARD  = 16'd100;   // 100kHz at 10MHz
    localparam [15:0] DIV_FAST      = 16'd25;    // 400kHz at 10MHz
    localparam [15:0] DIV_FAST_PLUS = 16'd10;    // 1MHz at 10MHz
    localparam [15:0] DIV_HIGH_SPEED = 16'd3;    // 3.4MHz at 10MHz

    // Divider value selection
    always @(*) begin
        case (i_speed_mode)
            2'b00: divider_reg = DIV_STANDARD;
            2'b01: divider_reg = DIV_FAST;
            2'b10: divider_reg = DIV_FAST_PLUS;
            2'b11: divider_reg = DIV_HIGH_SPEED;
            default: divider_reg = DIV_STANDARD;
        endcase

        // Override with dynamic divider if non-zero
        if (i_divider != 16'd0) begin
            divider_reg = i_divider;
        end
    end

    // Clock generation and stretching logic
    always @(posedge i_sys_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            clk_counter     <= 16'd0;
            scl_toggle      <= 1'b0;
            o_scl_out       <= 1'b1;      // SCL high in reset
            o_scl_oe        <= 1'b1;      // Enable output
            stretch_active  <= 1'b0;
            timing_error    <= 1'b0;
        end else if (i_enable) begin
            // Clock stretching handling
            if (STRETCH_EN && i_stretch_req && !stretch_active) begin
                stretch_active <= 1'b1;
                o_scl_oe       <= 1'b0;    // Disable SCL output (high-Z)
            end else if (stretch_active && !i_stretch_req) begin
                stretch_active <= 1'b0;
                o_scl_oe       <= 1'b1;    // Re-enable SCL output
                clk_counter    <= 16'd0;   // Reset counter after stretching
            end

            // Clock generation when not stretching
            if (!stretch_active) begin
                if (divider_reg >= 16'd2 && clk_counter >= divider_reg - 1) begin
                    clk_counter <= 16'd0;
                    scl_toggle  <= ~scl_toggle;
                    o_scl_out   <= scl_toggle;
                end else if (divider_reg >= 16'd2) begin
                    clk_counter <= clk_counter + 16'd1;
                end
                // If divider_reg < 2, don't increment counter to prevent invalid clock
            end

            // Timing validation
            if (divider_reg < 16'd10) begin  // Minimum divider for valid I2C timing
                timing_error <= 1'b1;     // Invalid divider (too small)
            end else begin
                timing_error <= 1'b0;
            end
        end else begin
            // Module disabled
            o_scl_out      <= 1'b1;       // SCL high when disabled
            o_scl_oe       <= 1'b0;       // Disable output
            clk_counter    <= 16'd0;
            scl_toggle     <= 1'b0;
            stretch_active <= 1'b0;
        end
    end

    // Timing validation output
    assign o_timing_valid = !timing_error && i_enable;

endmodule
