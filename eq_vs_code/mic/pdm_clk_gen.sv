`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
//
// Create Date: 10/24/2024
// Design Name: PDM Clock Generator
// Module Name:  
// Description: 
// Dependencies: None
//
//////////////////////////////////////////////////////////////////////////////////

module pdm_clk_gen #(
    parameter IN_FREQ = 100_000_000,   // Input FPGA clock frequency (100 MHz)
    parameter OUT_FREQ = 3_072_000     // Desired PDM clock frequency (3.072 MHz)
)(
    input logic clk,      // 100 MHz clock input
    input logic rst,      // Reset signal
    output logic MIC_CLK,   // Generated 3.072 MHz clock output -- connects to PDM microphone
    output logic m_clk_rising  // Rising edge of 3.072 MHz clock
    
);

    // Clock divider calculation
    localparam  CLK_DIVIDE = IN_FREQ / OUT_FREQ;  // 100M / 3.072M = 32

    // Register declarations
    logic [$clog2(CLK_DIVIDE)-1:0] clk_counter = 0;
    logic m_clk_i = 0;             // Internal clock signal (3.072 MHz)
    
    logic m_clk_rising_i = 0;         // Rising edge of 3.072 MHz clock


    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_counter <= 0;
            m_clk_i <= 0;
            m_clk_rising_i <= 0;
            pcm_counter <= 0;
        end else begin
            m_clk_rising_i<=0;
            // Clock division logic
            if (clk_counter < (CLK_DIVIDE / 2) - 1) begin //50% duty cycle - square wave
                clk_counter <= clk_counter + 1;
            end else begin
                clk_counter <= 0;
                m_clk_i <= ~m_clk_i;  // Toggle the clock output
                m_clk_rising_i <= ~m_clk_i;  // Generate rising edge of 3.072 MHz clock
            end

        
        end
    end

    // Assign outputs
    assign M_CLK = m_clk_i; 
    assign m_clk_rising = m_clk_rising_i; // Rising edge of 3.072 MHz clock

endmodule
