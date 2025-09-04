////////////////////////////////////////////////////////////////////////////////
// Module: power_mgmt.v
// Description: I2C Power Management Module
//              Handles low-power states and clock gating for power optimization.
// Author: AI Assistant
// Date: 2025
////////////////////////////////////////////////////////////////////////////////

module power_mgmt #(
    parameter IDLE_TIMEOUT = 1000,        // Inactivity timeout for auto-idle (cycles)
    parameter SLEEP_EN = 1,               // Enable sleep mode
    parameter WAKE_ON_BUS = 1             // Wake on bus activity
)(
    // System interface
    input  wire        i_sys_clk,         // System clock (from APB PCLK)
    input  wire        i_rst_n,           // Active low reset (from APB PRESETn)

    // Control interface
    input  wire [1:0]  i_power_state_req, // Requested power state
    input  wire        i_wake_up_en,      // Wake-up enable
    output reg [1:0]   o_power_state_ack, // Acknowledged power state
    output reg         o_wake_up_event,   // Wake-up event occurred

    // Activity monitoring
    input  wire        i_bus_activity,    // I2C bus activity detected
    input  wire        i_reg_access,      // Register access detected

    // Clock gating outputs
    output reg         o_core_clk_en,     // Core clock enable
    output reg         o_reg_clk_en,      // Register bank clock enable
    output reg         o_fsm_clk_en,      // FSM clock enable

    // Status
    output wire        o_in_low_power     // Currently in low-power state
);

    // Power state definitions
    localparam [1:0] PWR_ACTIVE = 2'b00;
    localparam [1:0] PWR_IDLE   = 2'b01;
    localparam [1:0] PWR_SLEEP  = 2'b10;
    localparam [1:0] PWR_OFF    = 2'b11;

    // Internal registers
    reg [1:0]   current_state;
    reg [15:0]  idle_counter;
    reg         activity_detected;
    reg         wake_up_pending;

    // Activity detection
    always @(posedge i_sys_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            activity_detected <= 1'b0;
        end else begin
            activity_detected <= i_bus_activity || i_reg_access;
        end
    end

    // Power state machine
    always @(posedge i_sys_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            current_state     <= PWR_ACTIVE;
            o_power_state_ack <= PWR_ACTIVE;
            idle_counter      <= 16'd0;
            wake_up_pending   <= 1'b0;
            o_wake_up_event   <= 1'b0;
        end else begin
            case (current_state)
                PWR_ACTIVE: begin
                    o_power_state_ack <= PWR_ACTIVE;
                    idle_counter      <= 16'd0;

                    if (i_power_state_req == PWR_IDLE && idle_counter >= IDLE_TIMEOUT) begin
                        current_state <= PWR_IDLE;
                    end else if (i_power_state_req == PWR_SLEEP && SLEEP_EN) begin
                        current_state <= PWR_SLEEP;
                    end else if (i_power_state_req == PWR_OFF) begin
                        current_state <= PWR_OFF;
                    end
                end

                PWR_IDLE: begin
                    o_power_state_ack <= PWR_IDLE;

                    if (activity_detected) begin
                        current_state <= PWR_ACTIVE;
                    end else if (i_power_state_req == PWR_SLEEP && SLEEP_EN) begin
                        current_state <= PWR_SLEEP;
                    end else if (i_power_state_req == PWR_OFF) begin
                        current_state <= PWR_OFF;
                    end
                end

                PWR_SLEEP: begin
                    o_power_state_ack <= PWR_SLEEP;

                    if ((WAKE_ON_BUS && i_bus_activity) || i_reg_access || wake_up_pending) begin
                        current_state   <= PWR_ACTIVE;
                        o_wake_up_event <= 1'b1;
                        wake_up_pending <= 1'b0;
                    end else if (i_power_state_req == PWR_OFF) begin
                        current_state <= PWR_OFF;
                    end
                end

                PWR_OFF: begin
                    o_power_state_ack <= PWR_OFF;

                    // Only external reset can wake from OFF
                    if (i_wake_up_en) begin
                        wake_up_pending <= 1'b1;
                    end
                end

                default: begin
                    current_state <= PWR_ACTIVE;
                end
            endcase

            // Idle timeout counter
            if (current_state == PWR_ACTIVE && !activity_detected) begin
                if (idle_counter < IDLE_TIMEOUT) begin
                    idle_counter <= idle_counter + 16'd1;
                end
            end else begin
                idle_counter <= 16'd0;
            end

            // Clear wake-up event after one cycle
            if (o_wake_up_event) begin
                o_wake_up_event <= 1'b0;
            end
        end
    end

    // Clock gating logic
    always @(*) begin
        case (current_state)
            PWR_ACTIVE: begin
                o_core_clk_en = 1'b1;
                o_reg_clk_en  = 1'b1;
                o_fsm_clk_en  = 1'b1;
            end

            PWR_IDLE: begin
                o_core_clk_en = 1'b1;
                o_reg_clk_en  = 1'b0;  // Gate register clock
                o_fsm_clk_en  = 1'b0;  // Gate FSM clock
            end

            PWR_SLEEP: begin
                o_core_clk_en = 1'b0;  // Gate all clocks
                o_reg_clk_en  = 1'b0;
                o_fsm_clk_en  = 1'b0;
            end

            PWR_OFF: begin
                o_core_clk_en = 1'b0;
                o_reg_clk_en  = 1'b0;
                o_fsm_clk_en  = 1'b0;
            end

            default: begin
                o_core_clk_en = 1'b1;
                o_reg_clk_en  = 1'b1;
                o_fsm_clk_en  = 1'b1;
            end
        endcase
    end

    // Low power status
    assign o_in_low_power = (current_state != PWR_ACTIVE);

endmodule