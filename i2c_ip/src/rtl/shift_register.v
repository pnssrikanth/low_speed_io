////////////////////////////////////////////////////////////////////////////////
// Module: shift_register.v
// Description: I2C Shift Register Module
//              Handles serial-to-parallel and parallel-to-serial data conversion
//              with configurable shift direction and ACK bit management.
// Author: AI Assistant
// Date: 2025
////////////////////////////////////////////////////////////////////////////////

module shift_register #(
    parameter DATA_WIDTH = 8,             // Data width (default 8 bits)
    parameter SHIFT_DIR = 0               // Shift direction (0: LSB first)
)(
    // System interface
    input  wire        i_sys_clk,         // System clock (from APB PCLK)
    input  wire        i_rst_n,           // Active low reset (from APB PRESETn)

    // Control interface
    input  wire        i_load_data,       // Load parallel data
    input  wire        i_shift_en,        // Shift enable
    input  wire        i_rw_mode,         // Read/Write mode (0: Write/TX, 1: Read/RX)
    input  wire        i_ack_en,          // ACK enable

    // Data interface
    input  wire [DATA_WIDTH-1:0] i_parallel_in,  // Parallel data input
    output wire [DATA_WIDTH-1:0] o_parallel_out, // Parallel data output
    input  wire        i_serial_in,       // Serial data input (SDA)
    output wire        o_serial_out,      // Serial data output (SDA)
    output wire        o_ack_bit,         // ACK bit output

    // Status interface
    output wire        o_shift_done,      // Shift operation complete
    output wire        o_data_valid,      // Output data valid
    output wire        o_ack_received     // ACK received (for TX)
);

    // Internal registers
    reg [DATA_WIDTH-1:0] shift_reg;       // Main shift register
    reg [3:0]            bit_counter;     // Bit counter (0-7 for 8-bit)
    reg                  shift_done_reg;  // Shift done flag
    reg                  data_valid_reg;  // Data valid flag
    reg                  ack_received_reg; // ACK received flag
    reg                  ack_bit_reg;     // ACK bit to send

    // State definitions
    localparam STATE_IDLE    = 2'b00;
    localparam STATE_LOAD    = 2'b01;
    localparam STATE_SHIFT   = 2'b10;
    localparam STATE_ACK     = 2'b11;

    reg [1:0] current_state;

    // Shift register logic
    always @(posedge i_sys_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            shift_reg        <= {DATA_WIDTH{1'b0}};
            bit_counter      <= 4'd0;
            shift_done_reg   <= 1'b0;
            data_valid_reg   <= 1'b0;
            ack_received_reg <= 1'b0;
            ack_bit_reg      <= 1'b1;     // Default ACK high (NACK)
            current_state    <= STATE_IDLE;
        end else begin
            case (current_state)
                STATE_IDLE: begin
                    shift_done_reg   <= 1'b0;
                    data_valid_reg   <= 1'b0;
                    ack_received_reg <= 1'b0;
                    bit_counter      <= 4'd0;

                    if (i_load_data) begin
                        current_state <= STATE_LOAD;
                    end
                end

                STATE_LOAD: begin
                    // Load parallel data into shift register
                    shift_reg <= i_parallel_in;
                    bit_counter <= 4'd0;
                    current_state <= STATE_SHIFT;
                end

                STATE_SHIFT: begin
                    if (i_shift_en) begin
                        if (bit_counter < DATA_WIDTH) begin
                            if (i_rw_mode) begin
                                // Read mode: shift in from SDA
                                if (SHIFT_DIR == 0) begin
                                    // LSB first
                                    shift_reg <= {i_serial_in, shift_reg[DATA_WIDTH-1:1]};
                                end else begin
                                    // MSB first
                                    shift_reg <= {shift_reg[DATA_WIDTH-2:0], i_serial_in};
                                end
                            end else begin
                                // Write mode: shift out to SDA
                                if (SHIFT_DIR == 0) begin
                                    // LSB first
                                    shift_reg <= {1'b0, shift_reg[DATA_WIDTH-1:1]};
                                end else begin
                                    // MSB first
                                    shift_reg <= {shift_reg[DATA_WIDTH-2:0], 1'b0};
                                end
                            end
                            bit_counter <= bit_counter + 4'd1;
                        end else begin
                            // All bits shifted
                            data_valid_reg <= 1'b1;
                            current_state <= STATE_ACK;
                        end
                    end
                end

                STATE_ACK: begin
                    if (i_rw_mode) begin
                        // Read mode: send ACK
                        ack_bit_reg <= ~i_ack_en;  // 0 for ACK, 1 for NACK
                    end else begin
                        // Write mode: receive ACK
                        ack_received_reg <= ~i_serial_in;  // 0 means ACK
                    end
                    shift_done_reg <= 1'b1;
                    current_state <= STATE_IDLE;
                end

                default: begin
                    current_state <= STATE_IDLE;
                end
            endcase
        end
    end

    // Serial output logic
    assign o_serial_out = (i_rw_mode) ? ack_bit_reg :
                          (SHIFT_DIR == 0) ? shift_reg[0] : shift_reg[DATA_WIDTH-1];

    // Parallel output
    assign o_parallel_out = shift_reg;

    // Status outputs
    assign o_shift_done   = shift_done_reg;
    assign o_data_valid   = data_valid_reg;
    assign o_ack_received = ack_received_reg;
    assign o_ack_bit      = ack_bit_reg;

endmodule