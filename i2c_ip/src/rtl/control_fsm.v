////////////////////////////////////////////////////////////////////////////////
// Module: control_fsm.v
// Description: I2C Control Finite State Machine
//              Implements master and slave operation state machines
//              for I2C protocol handling.
// Author: AI Assistant
// Date: 2025
////////////////////////////////////////////////////////////////////////////////

module control_fsm (
    // System interface
    input  wire        i_sys_clk,         // System clock (from APB PCLK)
    input  wire        i_rst_n,           // Active low reset (from APB PRESETn)

    // Control inputs
    input  wire        i_enable,          // IP enable
    input  wire [1:0]  i_mode,            // Operation mode (00: Idle, 01: Master TX, 10: Master RX, 11: Slave)
    input  wire        i_start_tx,        // Start transmission
    input  wire        i_stop_tx,         // Stop transmission
    input  wire        i_ack_en,          // ACK enable

    // I2C bus interface
    input  wire        i_sda_in,          // SDA input from buffer
    input  wire        i_scl_in,          // SCL input from buffer
    output reg         o_sda_out,         // SDA output to buffer
    output reg         o_sda_oe,          // SDA output enable
    output reg         o_scl_out,         // SCL output to buffer
    output reg         o_scl_oe,          // SCL output enable

    // Shift register interface
    output reg         o_shift_load,      // Load data into shift register
    output reg         o_shift_en,        // Shift enable
    output reg         o_rw_mode,         // Read/Write mode
    input  wire        i_shift_done,      // Shift operation complete
    input  wire        i_ack_received,    // ACK received

    // Register interface
    input  wire [7:0]  i_data_reg,        // Data register
    input  wire [6:0]  i_addr_reg,        // Address register
    output reg         o_data_valid,      // Data valid for register
    output reg [7:0]   o_data_out,        // Data output to register

    // Status outputs
    output reg         o_busy,            // IP busy
    output reg         o_tx_done,         // Transmission complete
    output reg         o_rx_done,         // Reception complete
    output reg         o_arb_lost,        // Arbitration lost
    output reg         o_nack,            // NACK received
    output reg         o_bus_err,         // Bus error
    output reg         o_start_det,       // START condition detected
    output reg         o_stop_det,        // STOP condition detected

    // Clock manager interface
    output reg         o_stretch_req      // Clock stretching request
);

    // State definitions
    localparam [3:0] STATE_IDLE      = 4'h0;
    localparam [3:0] STATE_START     = 4'h1;
    localparam [3:0] STATE_ADDR      = 4'h2;
    localparam [3:0] STATE_TX_DATA   = 4'h3;
    localparam [3:0] STATE_RX_DATA   = 4'h4;
    localparam [3:0] STATE_ACK_TX    = 4'h5;
    localparam [3:0] STATE_ACK_RX    = 4'h6;
    localparam [3:0] STATE_STOP      = 4'h7;
    localparam [3:0] STATE_ARB_LOST  = 4'h8;
    localparam [3:0] STATE_ACK_ADDR  = 4'h9;
    localparam [3:0] STATE_WAIT_ACK  = 4'hA;
    localparam [3:0] STATE_SEND_ACK  = 4'hB;

    // Internal registers
    reg [3:0] current_state;
    reg [3:0] next_state;
    reg [7:0] tx_data_buffer;
    reg [6:0] addr_buffer;
    reg       rw_bit;
    reg       start_detected;
    reg       stop_detected;
    reg       arbitration_lost;

    // START/STOP detection
    reg sda_prev;
    reg scl_prev;

    always @(posedge i_sys_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            sda_prev <= 1'b1;
            scl_prev <= 1'b1;
            start_detected <= 1'b0;
            stop_detected <= 1'b0;
        end else begin
            sda_prev <= i_sda_in;
            scl_prev <= i_scl_in;

            // START: SDA high-to-low while SCL high
            if (scl_prev && !i_scl_in && sda_prev && !i_sda_in) begin
                start_detected <= 1'b1;
            end else begin
                start_detected <= 1'b0;
            end

            // STOP: SDA low-to-high while SCL high
            if (scl_prev && !i_scl_in && !sda_prev && i_sda_in) begin
                stop_detected <= 1'b1;
            end else begin
                stop_detected <= 1'b0;
            end
        end
    end

    // State machine logic
    always @(posedge i_sys_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            current_state <= STATE_IDLE;
        end else if (i_enable) begin
            current_state <= next_state;
        end else begin
            current_state <= STATE_IDLE;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = current_state;

        case (current_state)
            STATE_IDLE: begin
                if (i_mode[1] && start_detected) begin  // Slave mode and START detected
                    next_state = STATE_ACK_ADDR;
                end else if ((i_mode == 2'b01 || i_mode == 2'b10) && i_start_tx) begin  // Master mode
                    next_state = STATE_START;
                end
            end

            STATE_START: begin
                // Transition to address phase after START timing
                next_state = STATE_ADDR;
            end

            STATE_ADDR: begin
                if (i_shift_done) begin
                    if (i_ack_received) begin
                        next_state = (i_mode == 2'b01) ? STATE_TX_DATA : STATE_RX_DATA;
                    end else begin
                        next_state = STATE_STOP;  // NACK received
                    end
                end
            end

            STATE_TX_DATA: begin
                if (i_shift_done) begin
                    next_state = STATE_ACK_TX;
                end
            end

            STATE_RX_DATA: begin
                if (i_shift_done) begin
                    next_state = STATE_ACK_RX;
                end
            end

            STATE_ACK_TX: begin
                if (i_ack_received) begin
                    next_state = STATE_TX_DATA;  // Continue with next byte
                end else begin
                    next_state = STATE_STOP;     // NACK or end of transmission
                end
            end

            STATE_ACK_RX: begin
                next_state = STATE_RX_DATA;      // Continue receiving
            end

            STATE_STOP: begin
                next_state = STATE_IDLE;
            end

            STATE_ACK_ADDR: begin
                if (i_shift_done) begin
                    next_state = (rw_bit) ? STATE_TX_DATA : STATE_RX_DATA;
                end
            end

            STATE_WAIT_ACK: begin
                if (i_ack_received) begin
                    next_state = STATE_TX_DATA;
                end else begin
                    next_state = STATE_IDLE;
                end
            end

            STATE_SEND_ACK: begin
                next_state = STATE_RX_DATA;
            end

            default: begin
                next_state = STATE_IDLE;
            end
        endcase
    end

    // Output logic
    always @(posedge i_sys_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_sda_out       <= 1'b1;
            o_sda_oe        <= 1'b0;
            o_scl_out       <= 1'b1;
            o_scl_oe        <= 1'b0;
            o_shift_load    <= 1'b0;
            o_shift_en      <= 1'b0;
            o_rw_mode       <= 1'b0;
            o_data_valid    <= 1'b0;
            o_data_out      <= 8'h00;
            o_busy          <= 1'b0;
            o_tx_done       <= 1'b0;
            o_rx_done       <= 1'b0;
            o_arb_lost      <= 1'b0;
            o_nack          <= 1'b0;
            o_bus_err       <= 1'b0;
            o_start_det     <= 1'b0;
            o_stop_det      <= 1'b0;
            o_stretch_req   <= 1'b0;
            tx_data_buffer  <= 8'h00;
            addr_buffer     <= 7'h00;
            rw_bit          <= 1'b0;
        end else begin
            // Default values
            o_shift_load <= 1'b0;
            o_shift_en   <= 1'b0;
            o_data_valid <= 1'b0;
            o_tx_done    <= 1'b0;
            o_rx_done    <= 1'b0;
            o_start_det  <= start_detected;
            o_stop_det   <= stop_detected;

            case (current_state)
                STATE_IDLE: begin
                    o_busy        <= 1'b0;
                    o_sda_out     <= 1'b1;
                    o_sda_oe      <= 1'b0;
                    o_scl_out     <= 1'b1;
                    o_scl_oe      <= 1'b0;
                    o_stretch_req <= 1'b0;
                end

                STATE_START: begin
                    o_busy    <= 1'b1;
                    o_sda_out <= 1'b0;    // SDA low
                    o_sda_oe  <= 1'b1;    // Enable SDA output
                    o_scl_out <= 1'b1;    // SCL high
                    o_scl_oe  <= 1'b1;    // Enable SCL output
                    // Load address for transmission
                    addr_buffer <= i_addr_reg;
                    rw_bit      <= (i_mode == 2'b10) ? 1'b1 : 1'b0;  // Read for RX mode
                end

                STATE_ADDR: begin
                    o_rw_mode    <= 1'b0; // Write mode for address
                    o_shift_load <= 1'b1; // Load address + RW bit
                    o_shift_en   <= 1'b1; // Start shifting
                    tx_data_buffer <= {addr_buffer, rw_bit};
                end

                STATE_TX_DATA: begin
                    o_rw_mode    <= 1'b0; // Write mode
                    o_shift_load <= 1'b1; // Load data
                    o_shift_en   <= 1'b1;
                    tx_data_buffer <= i_data_reg;
                end

                STATE_RX_DATA: begin
                    o_rw_mode    <= 1'b1; // Read mode
                    o_shift_load <= 1'b1; // Prepare for receive
                    o_shift_en   <= 1'b1;
                    o_sda_oe     <= 1'b0; // Release SDA for input
                end

                STATE_ACK_TX: begin
                    o_nack <= ~i_ack_received;
                    if (!i_ack_received) begin
                        o_tx_done <= 1'b1;
                    end
                end

                STATE_ACK_RX: begin
                    o_data_valid <= 1'b1;
                    o_data_out   <= tx_data_buffer;  // From shift register
                    o_rx_done    <= 1'b1;
                end

                STATE_STOP: begin
                    o_sda_out <= 1'b0;    // SDA low
                    o_sda_oe  <= 1'b1;
                    o_scl_out <= 1'b1;    // SCL high
                    o_scl_oe  <= 1'b1;
                    o_tx_done <= 1'b1;
                    o_busy    <= 1'b0;
                end

                STATE_ACK_ADDR: begin
                    o_rw_mode    <= 1'b1; // Read address
                    o_shift_load <= 1'b1;
                    o_shift_en   <= 1'b1;
                end

                STATE_WAIT_ACK: begin
                    // Wait for ACK in slave TX
                end

                STATE_SEND_ACK: begin
                    o_sda_out <= ~i_ack_en;  // ACK or NACK
                    o_sda_oe  <= 1'b1;
                end

            endcase
        end
    end

endmodule