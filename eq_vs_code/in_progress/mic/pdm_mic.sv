`timescale 1ns / 1ps


module pdm_mic(
    input logic clk,
    input logic rst,
   
   

    //mic out
    output  logic [7:0] pcm_data, //8 bit audio output
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

reg [7:0] cic_out_data; //8bit output width
wire     cic_out_valid;


//decimation rate fixed at 10 - sample rate specifications




// in compiler set up - fixed decimation rate under sample rate specifications
//bit rate is set in output data width
//note - output data width range is [input,input+sample_rate]
   cic_compiler_0 cic_compiler
     (
      .aclk(clk),                              // input wire aclk
      .aresetn(~rst), //reset is active low
      .s_axis_data_tdata({1'b0,mic_data_queue[2]}),    // 2 bit input 
      .s_axis_data_tvalid(m_clk_rising),         // input wire s_axis_data_tvalid
      .s_axis_data_tready(),                // output wire, unclear if necessary  

      .m_axis_data_tdata(cic_out_data),    // 8 bit output 
      .m_axis_data_tvalid(cic_out_valid)  // output wire m_axis_data_tvalid
      .m_axis_data_tready()                // output wire, unclear if necessary
                                            //TREADY for the Data Output Channel. Asserted by the external 
// slave to signal that it is ready to accept data. Only present when the 
// XCO parameter HAS_DOUT_TREADY is TRUE.
      );


   assign pcm_data = cic_out_data;
   assign pcm_data_valid = cic_out_valid;
   
endmodule