`timescale 1ns / 1ps


module pdm_mic(
    input logic clk,
    input logic rst,
   
   

    //mic out
    output  logic [15:0] pcm_data, //16 bit audio output
    output  logic  pcm_data_valid,
   
 

    //mic - board
    input logic m_clk_rising,
    input  logic MIC_CLK, //connects to PDM microphone
    input logic MIC_DATA //connects to PDM microphone board

);




logic [15:0] cic_out_data; //8bit output width
logic     cic_out_valid;


//decimation rate fixed at 10 - sample rate specifications




// in compiler set up - fixed decimation rate under sample rate specifications
//bit rate is set in output data width
//note - output data width range is [input,input+sample_rate]
   cic_decimator cic_compiler
     (
      .aclk(clk),                              // input wire aclk
//      .aresetn(~rst), //exists in documentation
      .s_axis_data_tdata({7'b0,MIC_DATA}),    // 2 bit input 
      .s_axis_data_tvalid(m_clk_rising),         // input wire s_axis_data_tvalid
      // output wire, unclear if necessary  

      .m_axis_data_tdata(cic_out_data),    // 8 bit output 
      .m_axis_data_tvalid(cic_out_valid)  // output wire m_axis_data_tvalid
                    
      );


   assign pcm_data = cic_out_data;
   assign pcm_data_valid = cic_out_valid;
   
endmodule