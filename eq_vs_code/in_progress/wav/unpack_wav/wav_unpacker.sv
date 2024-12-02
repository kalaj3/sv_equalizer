
//------------------------------------------------------------------------------
// Module: wav_unpacker_to_pdm
//------------------------------------------------------------------------------
// This module implements a WAV file unpacker and converter to PDM (Pulse Density
// Modulation) output. It processes WAV file data byte by byte, extracts header
// information, buffers audio samples, and converts PCM data to PDM output.
//
// Key Features:
// - WAV header parsing and validation
// - Configurable PCM width and FIFO buffer depth
// - Automatic sample rate and format detection
// - Integrated PCM to PDM conversion
// - Status reporting for header parsing and format validation
//
// Typical Use Case:
// This module is designed for audio processing systems that need to convert
// WAV file data into PDM format, commonly used in digital microphones and
// audio DACs. It's particularly useful in embedded audio processing applications.
//
// Parameters:
// - PCM_WIDTH  : Width of PCM samples (default: 32 bits)
// - FIFO_DEPTH : Depth of internal buffer (default: 1024 entries)
//
// Clock Domains:
// - clk     : Main system clock domain for data processing
// - pdm_clk : PDM output clock domain (typically 2-3MHz)
//
// Reset:
// - Asynchronous active-low reset (rst_n)
//
// Dependencies:
// - wav_header_parser : Parses WAV file header
// - audio_fifo       : Buffers audio samples
// - pcm_to_pdm      : Converts PCM to PDM
//
// Limitations:
// - Supports single-channel WAV files only
// - Buffer overflow possible if input rate exceeds PDM conversion rate
// - No support for compressed WAV formats
//
// Notes:
// 1. WAV data must be supplied byte-by-byte with valid signal assertion
// 2. Header parsing must complete before audio data processing begins
// 3. PDM output is only generated when header is valid and no format errors
//
// Author: [Your Name]
// Date: [Current Date]
// Version: 1.0
//------------------------------------------------------------------------------
module wav_unpacker_to_pdm #(
    parameter PCM_WIDTH = 32,
    parameter FIFO_DEPTH = 1024
)(
    input  logic        clk,           // System clock
    input  logic        pdm_clk,       // PDM clock (typically 2-3MHz)
    input  logic        rst_n,         // Active low reset
    
    // WAV File Input Interface
    input  logic [7:0]  wav_data,      // Byte-wise WAV file input
    input  logic        wav_valid,
    output logic        wav_ready,
    
    // PDM Output Interface
    output logic        pdm_out,       // PDM output signal
    output logic        pdm_valid,     // PDM valid signal
    
    // Status Interface
    output logic        header_valid,   // WAV header successfully parsed
    output logic        format_error,   // Invalid format detected
    output logic [31:0] sample_rate,   // Detected sample rate
    output logic [15:0] bit_depth,     // Detected bit depth
    output logic [15:0] num_channels   // Number of audio channels
);

    // Internal signals
    logic        data_start;           // Indicates start of audio data
    logic [31:0] pcm_data;            // PCM data from FIFO
    logic        pcm_valid;           // PCM data valid
    logic        pcm_ready;           // PCM to PDM converter ready
    logic        fifo_write;          // FIFO write enable
    logic        fifo_read;           // FIFO read enable
    logic        fifo_empty;          // FIFO empty flag
    logic        fifo_full;           // FIFO full flag
    logic [7:0]  fifo_data_in;       // Data to write to FIFO
    
    // WAV header parser instance
    wav_header_parser header_parser (
        .clk           (clk),
        .rst_n         (rst_n),
        .data_in       (wav_data),
        .data_valid    (wav_valid),
        .data_ready    (wav_ready),
        .sample_rate   (sample_rate),
        .bit_depth     (bit_depth),
        .num_channels  (num_channels),
        .data_start    (data_start),
        .header_valid  (header_valid),
        .format_error  (format_error)
    );
    
    // Audio data FIFO instance
    audio_fifo #(
        .DEPTH(FIFO_DEPTH)
    ) fifo_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .write_en      (fifo_write),
        .read_en       (fifo_read),
        .data_in       (fifo_data_in),
        .data_out      (pcm_data),
        .empty         (fifo_empty),
        .full          (fifo_full)
    );
    
    // PCM to PDM converter instance
    pcm_to_pdm #(
        .PCM_WIDTH     (PCM_WIDTH)
    ) pdm_converter (
        .clk           (clk),
        .pdm_clk       (pdm_clk),
        .rst_n         (rst_n),
        .enable        (header_valid && !format_error),
        .pcm_data      (pcm_data),
        .pcm_valid     (pcm_valid),
        .pcm_ready     (pcm_ready),
        .pdm_out       (pdm_out),
        .pdm_valid     (pdm_valid)
    );
    
    // FIFO control logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_write <= 1'b0;
            fifo_data_in <= 8'h0;
        end else begin
            // Write to FIFO only after header is parsed and when receiving valid audio data
            fifo_write <= wav_valid && data_start && !fifo_full;
            fifo_data_in <= wav_data;
        end
    end
    
    // PCM data valid generation
    assign pcm_valid = !fifo_empty;
    assign fifo_read = pcm_ready && pcm_valid;

endmodule
