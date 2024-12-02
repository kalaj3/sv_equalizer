`timescale 1ns/1ps

module testbench_pdm_mic();



    // Parameters
    parameter IN_FREQ = 100_000_000;   // 100 MHz clock frequency
    parameter OUT_FREQ = 480_000;   // 480 khz PDM clock frequency
    parameter FILENAME = "text_input.txt";
    parameter LENGTH = 32;//fixed from the python i gen

    // Clock and reset signals
    logic clk;
    logic rst;

    // Outputs from modules
    logic [31:0] pcm_data;
    logic pcm_data_valid;
//entirely handled by cic init
//    logic decimation_rate = 10;// 480k/decimation rate = new frequency - options: 44.1k, 48k, 16k etc.
//    integer bit_depth = 8;  //must be less than 33 for cic filter if modified must be changed in IP
    logic MIC_CLK;
    logic m_clk_rising;
    logic  data;
    logic data_valid;

    // Input to modules
    logic MIC_DATA;

    initial begin

        clk = 0;
        rst= 0;
      end


always begin : CLOCK_GENERATION
#1 clk = ~clk;
end

initial begin: CLOCK_INITIALIZATION
    clk = 0;
end

    // DUT Instantiation
    pdm_clk_gen #(
        .INPUT_FREQ(IN_FREQ),
        .OUTPUT_FREQ(OUT_FREQ)
    ) pdm_clk_gen_inst (
        .clk(clk),
        .rst(rst),
        .M_CLK(MIC_CLK),
        .m_clk_rising(m_clk_rising)
    );


read_file #(.FILENAME(FILENAME),
            .FILE_LENGTH(LENGTH)
) reader(
    .clk(MIC_CLK), //should be MIC_CLK for real sim
    .rst(rst),
    .data_bit(data),
    .data_bit_valid(data_valid)
    );

    pdm_mic #(
        .IN_FREQ(IN_FREQ),
        .OUT_FREQ(OUT_FREQ)
    ) pdm_mic_inst (
        .clk(clk),
        .rst(rst),
        .pcm_data(pcm_data),
        .m_clk_rising(m_clk_rising),
//        .bit_depth(bit_depth),
        .MIC_CLK(MIC_CLK),
        .MIC_DATA(data)
    );

//    // Testbench logic
//    initial begin
//        // Wait for reset to deassert
//        @(negedge rst);

//        // Simulate the process
//        $display("Starting simulation...");

//        // Monitor signals
//        $monitor($time, " MIC_CLK=%b, MIC_DATA=%b, PCM Data=%d, Data Valid=%b", MIC_CLK, data, pdc_data, pdc_data_valid);

//        // Run for a specific amount of time
//        #100_000_000; // Simulate for 100ms

//        $display("Simulation finished.");
//        $stop;
//    end

endmodule