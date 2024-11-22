`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/21/2024 03:38:40 AM
// Design Name:
// Module Name: file_reader
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////



module read_file #(parameter FILENAME = "output.log", parameter FILE_LENGTH = 32)
(
    input wire clk,
    input wire rst,
    output reg data_bit,
    output reg data_bit_valid
);

    // Internal memory to store file content
    reg [0:0] file_memory [0:FILE_LENGTH-1]; // Memory array for file content (1 bit wide per entry)
    integer read_index;                      // Index to track current read position

    // File loading (runs once at simulation start)
    initial begin
        $readmemb(FILENAME, file_memory);    // Load the file content into memory array
        read_index = 0;                      // Initialize read index to 0
    end

    // Sequential logic to output bits
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_index <= 0;                 // Reset the read index on reset
            data_bit_valid <= 0;             // Output is invalid on reset
        end else begin
            if (read_index < FILE_LENGTH) begin
                data_bit <= file_memory[read_index]; // Output the current bit
                data_bit_valid <= 1;         // Mark data as valid
                read_index <= read_index + 1; // Move to the next bit
            end else begin
                data_bit_valid <= 0;         // Invalidate output after reading all bits
            end
        end
    end

endmodule