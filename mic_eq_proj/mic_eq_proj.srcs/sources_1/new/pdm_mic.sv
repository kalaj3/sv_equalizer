`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/24/2024 11:53:43 AM
// Design Name: 
// Module Name: pdm_mic
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


module pdm_mic(
#(
    parameter INPUT_FREQ = 
    parameter PDM_FREQ = 

    )
   (
    input         clk,
    input         rst,

    output [31:0] mic_data,
    output        mic_data_valid,


    output        M_CLK,
    input         M_DATA,
    output        M_LRSEL

    );
endmodule
