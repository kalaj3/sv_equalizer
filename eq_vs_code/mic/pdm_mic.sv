`timescale 1ns / 1ps


module pdm_mic#(
    parameter IN_FREQ = 100_000_000,   // input logic FPGA clock frequency (100 MHz)
    parameter OUT_FREQ = 480_000,     // Desired PDM clock frequency (480khz)
    parameter BIT_DEPTH = 8,
    parameter DECIMATION_RATE = 10 // unused - all hidden in cic instantiation
)(
    input logic clk,
    input logic rst,
   
   

    //mic out
    output  logic [31:0] pcm_data, // this is wrong  // should probably be one bit/ array of size bit_depth that feeds into the fifo/next location
    output  logic  pcm_data_valid,
   
 

    //mic - board
    input logic m_clk_rising,
    input  logic MIC_CLK, //connects to PDM microphone
    input logic MIC_DATA //connects to PDM microphone board

);


logic [2:0]  mic_data_queue;


always_ff @(posedge clk or posedge rst) begin //buffer on mic_data in to delay input logic contents
    if (rst) begin
        mic_data_queue <= 3'b0;
    end else begin
        mic_data_queue <= {mic_data_queue[1:0], MIC_DATA};
    end
end
//just a delay function - no alterations to data





//CIC filter/other -> pdm_data

//digital signal created - might not be available on spartan 7
// litteraly just complicated moving average

// all of the values are fixed and need to be modified in the cic IP Block if changed
logic [31:0] cic_out_data; // might change bc of upsampling above // dependent on sample rate?
   logic        cic_out_valid;


// in compiler set up - fixed decimation rate under sample rate specifications
//bit rate is set in output data width
//note - output data width range is [input,input+sample_rate]
   cic_compiler_0 cic_compiler
     (
      .aclk(clk),                              // input wire aclk
      .s_axis_data_tdata({7{mic_data_queue[2]}}, mic_data_queue[2])    // input wire [7 : 0] s_axis_data_tdata
      .s_axis_data_tvalid(m_clk_rising),         // input wire s_axis_data_tvalid
      .s_axis_data_tready(),  

      .m_axis_data_tdata(cic_out_data),    // output wire [39 : 0] m_axis_data_tda
      .m_axis_data_tvalid(cic_out_valid)  // output wire m_axis_data_tvalid
      );

    always_ff @(posedge clk) begin
    if (cic_out_valid) begin
        pcm_data <= cic_out_data;
        pcm_data_valid <= 1'b1;
    end else begin
        pcm_data_valid <= 1'b0;
    end
end

   assign pcm_data = cic_out_data;
   assign pcm_data_valid = cic_out_valid;
   
endmodule