`timescale 1ns / 1ps


module pdm_mic#(
    parameter IN_FREQ = 100_000_000,   // input logic FPGA clock frequency (100 MHz)
    parameter OUT_FREQ = 3_072_000     // Desired PDM clock frequency (3.072 MHz) 
)(
    input logic clk, 
    input logic rst,
    
    

    //mic out
    output  logic [31:0] pdc_data,
    output  logic      pdc_data_valid, 
    output logic        sample_rate, //48khz
    output logic       bit_depth,

    //mic - board
    output  logic MIC_CLK, //connects to PDM microphone
    input logic MIC_DATA, //connects to PDM microphone

);

//! a 64 PCM  decimation ratio - this is sample rate, not bit depth



logic sample_rate_i;
assign sample_rate_i = out_freq/64; //64 magic number from real digital datasheet 
logic bit_depth_i;
assign bit_depth_i = 32; //must be <40 for CIC compiler but idk the difference between 32..40



logic [2:0]  mic_data_queue;
logic mic_clk_rising;

always_ff @(posedge clk or posedge rst) begin //buffer on mic_data in to delay input logic contents 
    if (rst) begin
        mic_data_queue <= 3'b0;
    end else begin
        mic_data_queue <= {mic_data_queue[1:0], MIC_DATA};
    end
end


//clk 100mhz (infreq)
//mic_clk 3.072mhz (outfreq) /64 
//this creates a 48khz sampling rate
/*
In typical applications, 64 (or more) clocks are driven into the T3902 for each PCM sample.
For example, if the FPGA drove a 3.072MHz clock into the T3902, then consecutive groups of 
64 points could be combined into a PCM sample, resulting in a 48KHz PCM sample rate (3.072MHz/64 = 48KHz).
*/ 
pdm_clk_gen #(
    .IN_FREQ(IN_FREQ),
    .OUT_FREQ(OUT_FREQ)
) pdm_clk_gen_inst (
    .clk(clk),
    .rst(rst),
    .MIC_CLK(MIC_CLK),
    .m_clk_rising(mic_clk_rising)
);


//CIC filter/other -> pdm_data

//digital signal created - might not be available on spartan 7
// litteraly just complicated moving average
logic [(bit_depth_i-1):0] cic_out_data;
   logic        cic_out_valid;

   cic_compiler_0 cic_compiler
     (
      .aclk(clk),                              // input logic wire aclk
      .s_axis_data_tdata({7'b0,m_data_q[2]}),    // input logic wire [7 : 0] s_axis_data_tdata
      .s_axis_data_tvalid(m_clk_rising),         // input logic wire s_axis_data_tvalid
      .s_axis_data_tready(),   // output  logic wire s_axis_data_tready

      .m_axis_data_tdata(cic_out_data),    // output  logic wire [39 : 0] m_axis_data_tdata
      .m_axis_data_tvalid(cic_out_valid)  // output  logic wire m_axis_data_tvalid
      );

/*
So:
Your CIC filter produces 40-bit samples
You're truncating/taking 32 bits for your final PCM data
Therefore, your bit depth is 32 bits

However, effective bit depth might be less due to:

CIC filter gain
Noise floor
Truncation/rounding

To determine effective bit depth, you'd need to:

Check CIC filter parameters (decimation ratio, stages)
Look at the T3902 SNR specifications
Consider if you need all 32 bits or could truncate further
*/




    //!data returned in  PCM format
   
   assign pdc_data = cic_out_data;
   assign pdc_data_valid = cic_out_valid;
   assign sample_rate = sample_rate_i;
endmodule