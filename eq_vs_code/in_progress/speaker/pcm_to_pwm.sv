
// This and the speaker will run on the 100Mhz clock
//this needs to count from 0- 2^bit_depth for every clock cycle of the input frequency
//this will recieve a pcm on the audio_clk timescale and output 1 bit signal on the pwm_clk timescale
// so, smells like clocking problems, tbd


//1. recieve pcm
//a. pcm = values 
//b. pcm_in_process = 1 
//2.loop - while pcm_valid = 1 - on device clock
//count up to 2^bit_depth. pwm_valid = 1
//if count < pcm, pwm_out = 1
//if  count == 2^bit_depth,  pwm_valid=0, pcm_in_proceess = 0
//wait to be reset by the next time pcm sends a signal - should be done on audio_clk

module pcm_to_pwm #(
    parameter BIT_DEPTH = 8
) (


    input logic audio_clk,  // 
    input logic pwm_clk,  // device_clk  -- much faster than audio_clk
    input logic rst,
    input logic [BIT_DEPTH-1:0] pcm_data,  //8 bit audio output
    input logic pcm_data_valid,
    output logic pwm_out,  // 1 bit output
    output logic pwm_valid  // 1 bit output
);


  logic pcm_in_process;
  logic [BIT_DEPTH-1:0] count;



  always_ff @(posedge pwm_clk or posedge rst) begin
    if (rst) begin
      pcm_in_process <= 1'b0;
      count <= 0;
      pwm_valid <= 0;
    end else begin
      if (pcm_data_valid) begin
        pcm_in_process <= 1'b1;
      end

      if (pcm_in_process) begin
        if (count < pcm_data) begin
          pwm_out <= 1;
        end else begin
          pwm_out <= 0;
        end
        if (count == 2 ** BIT_DEPTH) begin
          pcm_in_process <= 1'b0;
          count <= 0;
          pwm_valid <= 0;
          pwm_out <= 0;
        end
        count <= count + 1;
      end
    end
  end




endmodule
