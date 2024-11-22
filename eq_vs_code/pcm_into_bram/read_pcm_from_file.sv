`timescale 1ps / 1ps

module read_pcm_from_file
  #(
    parameter FILENAME = "output_pcm.log",  // PCM data file
    parameter BIT_DEPTH = 8               // Typical PCM bit depth (e.g., 16-bit)
    )
   (
    input                     clk,
    input                     rst,
    output signed [BIT_DEPTH-1:0] data,    // PCM sample output
    output                    data_valid  // Indicates valid PCM sample
    );

   integer                    input_file;
   integer                    scan_file;

   initial begin
      input_file = $fopen(FILENAME, "r");
      if (input_file == 0) begin
         $display("ERROR opening PCM file: %s", FILENAME);
         $finish;
      end
   end

   logic signed [BIT_DEPTH-1:0] pcm_sample; // Temporary storage for PCM data
   logic                        pcm_valid;

   initial begin
      pcm_sample = 0;
      pcm_valid  = 0;

      wait(~rst); // Wait for reset to de-assert

      while (!$feof(input_file)) begin
         scan_file = $fscanf(input_file, "%d\n", pcm_sample); // Read PCM sample
         pcm_valid = 1;

         @(posedge clk); // Synchronize with clock
      end
   end

   assign data = pcm_sample;
   assign data_valid = pcm_valid;

endmodule
