////////////////////////////////////////////////////////////////////////////////
// Module: pec_module.v
// Description: SMBus Packet Error Checking (PEC) Module
//              Implements CRC-8 calculation for SMBus data integrity.
// Author: AI Assistant
// Date: 2025
////////////////////////////////////////////////////////////////////////////////

module pec_module (
    // System interface
    input  wire        i_sys_clk,         // System clock (from APB PCLK)
    input  wire        i_rst_n,           // Active low reset (from APB PRESETn)

    // Control interface
    input  wire        i_pec_en,          // PEC enable
    input  wire        i_pec_start,       // Start PEC calculation
    input  wire        i_pec_valid,       // Data valid
    input  wire [7:0]  i_pec_data,        // Data byte for PEC calculation

    // Output interface
    output reg [7:0]   o_pec_byte,        // Calculated PEC byte
    output reg         o_pec_error,       // PEC error detected
    output reg         o_pec_done         // PEC calculation complete
);

    // CRC-8 polynomial: x^8 + x^2 + x + 1 (0x07)
    localparam [7:0] CRC_POLY = 8'h07;

    // Internal registers
    reg [7:0] crc_reg;                   // CRC register
    reg       calculating;               // Calculation in progress
    reg [7:0] received_pec;              // Received PEC for validation
    reg       validate_mode;             // Validation mode flag

    // CRC calculation function
    function [7:0] crc8_calc;
        input [7:0] data;
        input [7:0] current_crc;
        reg   [7:0] crc;
        integer i;
        begin
            crc = current_crc;
            for (i = 0; i < 8; i = i + 1) begin
                if ((crc[7] ^ data[i]) == 1'b1) begin
                    crc = {crc[6:0], 1'b0} ^ CRC_POLY;
                end else begin
                    crc = {crc[6:0], 1'b0};
                end
            end
            crc8_calc = crc;
        end
    endfunction

    // PEC processing logic
    always @(posedge i_sys_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            crc_reg       <= 8'h00;
            calculating   <= 1'b0;
            o_pec_byte    <= 8'h00;
            o_pec_error   <= 1'b0;
            o_pec_done    <= 1'b0;
            received_pec  <= 8'h00;
            validate_mode <= 1'b0;
        end else if (i_pec_en) begin
            if (i_pec_start) begin
                // Initialize CRC for new calculation
                crc_reg       <= 8'h00;
                calculating   <= 1'b1;
                o_pec_done    <= 1'b0;
                o_pec_error   <= 1'b0;
                validate_mode <= 1'b0;
            end else if (calculating && i_pec_valid) begin
                // Process data byte
                crc_reg <= crc8_calc(i_pec_data, crc_reg);

                // Check if this is the PEC byte (for validation)
                if (validate_mode) begin
                    received_pec <= i_pec_data;
                    if (crc_reg == i_pec_data) begin
                        o_pec_error <= 1'b0;  // PEC matches
                    end else begin
                        o_pec_error <= 1'b1;  // PEC mismatch
                    end
                    o_pec_done  <= 1'b1;
                    calculating <= 1'b0;
                end
            end else if (!i_pec_valid && calculating) begin
                // End of data, output calculated PEC
                o_pec_byte  <= crc_reg;
                o_pec_done  <= 1'b1;
                calculating <= 1'b0;
                validate_mode <= 1'b1;  // Next byte is PEC for validation
            end
        end else begin
            // PEC disabled
            crc_reg     <= 8'h00;
            calculating <= 1'b0;
            o_pec_done  <= 1'b0;
            o_pec_error <= 1'b0;
        end
    end

endmodule
