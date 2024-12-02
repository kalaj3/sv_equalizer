`timescale 1ns / 1ps
module bram_wrapper #(
    parameter BIT_DEPTH = 8  // 8-bit audio output
) (
    input logic clk,
    input logic rst,
    input logic audio_clk,  // tied to received audio input frequency
    input logic [BIT_DEPTH-1:0] input_word,
    output logic [BIT_DEPTH-1:0] output_word,
    output logic output_valid  // rising edge detection for bram clk - 1 everytime new values appear (in theory)
);

  localparam BRAM_SIZE = 1024;  // Arbitrary size
  localparam BRAM_WRITE_HEADSTART = 16;  // Arbitrary headstart for write address
  logic bram_clk;
  logic bram_en;
  logic bram_write_en;  // Only for the microphone input
  assign bram_clk = audio_clk;
  assign bram_en = 1'b1;
  assign bram_write_en = 1'b1;

  logic [10:0] bram_addr_write, bram_addr_read;

  logic [31:0] extended_input, extended_output;

  // Registers for output_valid generation
  logic [10:0] addr_diff;  // Address difference for delay calculation

  always_comb begin
    // Potentially unnecessary
    // Interaction with 32-bit memory of BRAM
    extended_input = {{(32 - BIT_DEPTH) {1'b0}}, input_word};
    output_word = extended_output[BIT_DEPTH-1:0];

    // Address difference to ensure valid output
    addr_diff = bram_addr_write - bram_addr_read;
  end




  logic bram_clk_prev;  // Previous state of the BRAM clock
  //rising edge detection of the clock for output valid 
  always @(posedge bram_clk or posedge reset) begin
    if (rst) begin
      bram_clk_prev <= 1'b0;  // Reset the previous state
      output_valid  <= 1'b0;  // Reset the output
    end else begin

      output_valid  <= (bram_clk && !bram_clk_prev);

      bram_clk_prev <= bram_clk;
    end
  end




  always_ff @(negedge bram_clk or posedge rst) begin
    if (rst) begin
      bram_addr_write <= BRAM_WRITE_HEADSTART;
      bram_addr_read  <= 0;

    end else begin

      // Update write address
      if (bram_addr_write >= BRAM_SIZE) begin
        bram_addr_write <= 0;
      end else begin
        bram_addr_write <= bram_addr_write + 1;
      end

      // Update read address
      if (bram_addr_read >= BRAM_SIZE) begin
        bram_addr_read <= 0;
      end else begin
        bram_addr_read <= bram_addr_read + 1;
      end


    end
  end

  blk_mem_gen_0 blk_mem (
      // Connects to the microphone input
      .addra(bram_addr_write),
      .clka (bram_clk),
      .dina (extended_input),
      .douta(),
      .ena  (bram_en),
      .wea  (bram_write_en),

      // Connects to the speaker output
      .addrb(bram_addr_read),
      .clkb(bram_clk),
      .dinb(),
      .doutb(extended_output),
      .enb(bram_en),
      .web()  // Should never be on because this connects to a speaker
  );

endmodule
