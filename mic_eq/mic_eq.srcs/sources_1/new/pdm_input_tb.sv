`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2024 02:52:18 PM
// Design Name: 
// Module Name: pdm_input_tb
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


`timescale 1ps / 1ps


module read_pdm_from_file
  #(
    parameter FILENAME = "output.log",
    parameter LENGTH = 29

    )
   (
    input                      clk,
    input                      rst,
    output signed [LENGTH-1:0] data,
    output                     data_valid

    );

   integer                     input_file;
   integer                     scan_file;

   initial begin
      input_file     = $fopen(FILENAME, "r");
      if (input_file == 0) begin
         $display("ERROR opening file!!");
         $finish;
      end
   end

   logic [LENGTH-1:0] stim;
   logic              stim_valid;


   initial begin
      stim       = 0;
      stim_valid = 0;

      wait(~rst);

      while(!$feof(input_file)) begin
         scan_file  = $fscanf(input_file, "%d\n", stim);
         stim_valid = 1;

         @(posedge clk);

      end
   end

   assign data = stim;
   assign data_valid = stim_valid;



endmodule

