module pcm_to_pdm #(
    parameter PCM_WIDTH = 32
)(
    input  logic clk,           // Main clock
    input  logic pdm_clk,       // High-speed PDM clock
    input  logic rst_n,         // Active low reset
    input  logic enable,        // Module enable
    
    // PCM Input Interface
    input  logic [PCM_WIDTH-1:0] pcm_data,
    input  logic pcm_valid,
    output logic pcm_ready,
    
    // PDM Output Interface
    output logic pdm_out,
    output logic pdm_valid
);

    // Local signals for IP core interface
    logic signed [23:0] pcm_data_scaled;  // IP core expects 24-bit input
    
    // Scale input PCM data to 24-bit for IP core
    always_comb begin
        if (PCM_WIDTH > 24)
            pcm_data_scaled = pcm_data[PCM_WIDTH-1:PCM_WIDTH-24];
        else
            pcm_data_scaled = pcm_data << (24 - PCM_WIDTH);
    end

    // Instantiate Xilinx Delta-Sigma IP Core
    dsd_1bit_v1_0 dsd_inst (
        .aclk(clk),                    // Clock input
        .pdm_clk(pdm_clk),            // PDM output clock
        .aresetn(rst_n),              // Active low reset
        
        .s_axis_tdata(pcm_data_scaled),// Input PCM data
        .s_axis_tvalid(pcm_valid),     // Input valid
        .s_axis_tready(pcm_ready),     // Ready for input
        
        .m_axis_tdata(pdm_out),        // PDM output
        .m_axis_tvalid(pdm_valid)      // Output valid
    );

endmodule