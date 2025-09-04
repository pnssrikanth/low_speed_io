module i2c_master #(
    parameter AUTOMOTIVE_MODE = 0,  // 1=Automotive, 0=General-purpose
    parameter WATCHDOG_EN = 0,      // Enable watchdog in automotive mode
    parameter PARITY_EN = 0         // Enable parity checking
)(
    input wire clk,          // System clock
    input wire rst_n,        // Active low reset
    input wire [6:0] slave_addr,  // 7-bit slave address
    input wire [7:0] data_in,     // Data to send
    input wire start,             // Start transaction
    output reg [7:0] data_out,    // Received data
    output reg ack,               // Acknowledge bit
    output reg busy,              // Busy flag
    inout wire sda,               // I2C data line
    output reg scl,               // I2C clock line
    // Automotive-specific ports
`ifdef AUTOMOTIVE_MODE
    output reg watchdog_timeout,   // Watchdog timeout indicator
    output reg parity_error,       // Parity error flag
`endif
);

// State machine states
localparam IDLE = 0;
localparam START = 1;
localparam SEND_ADDR = 2;
localparam SEND_DATA = 3;
localparam RECEIVE_DATA = 4;
localparam STOP = 5;

// Registers
reg [2:0] state;
reg [3:0] bit_cnt;
reg sda_out;
reg sda_dir;  // 1 for output, 0 for input

// Automotive-specific registers
`ifdef AUTOMOTIVE_MODE
reg [7:0] watchdog_counter;
reg parity_bit;
`endif

// SDA tri-state control
assign sda = sda_dir ? sda_out : 1'bz;

// Basic state machine with automotive features
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        busy <= 0;
        scl <= 1;
        sda_dir <= 1;
        sda_out <= 1;
`ifdef AUTOMOTIVE_MODE
        watchdog_counter <= 0;
        watchdog_timeout <= 0;
        parity_error <= 0;
`endif
    end else begin
`ifdef AUTOMOTIVE_MODE
        // Watchdog counter
        if (WATCHDOG_EN) begin
            if (state != IDLE) begin
                watchdog_counter <= watchdog_counter + 1;
                if (watchdog_counter == 8'hFF) begin
                    watchdog_timeout <= 1;
                    state <= IDLE;
                    busy <= 0;
                end
            end else begin
                watchdog_counter <= 0;
                watchdog_timeout <= 0;
            end
        end

        // Parity checking
        if (PARITY_EN && state == SEND_ADDR) begin
            parity_bit <= ^slave_addr;  // Calculate parity
        end
`endif

        case (state)
            IDLE: begin
                if (start) begin
                    state <= START;
                    busy <= 1;
`ifdef AUTOMOTIVE_MODE
                    watchdog_counter <= 0;
`endif
                end
            end
            START: begin
                // Generate start condition
                sda_out <= 0;
                scl <= 1;
                state <= SEND_ADDR;
                bit_cnt <= 7;
            end
            // Add more states for address, data, etc.
            default: state <= IDLE;
        endcase
    end
end

endmodule