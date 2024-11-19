//------------------------------------------------------------------------------
// Module: pdm_clock_generator
//------------------------------------------------------------------------------
// Generates the PDM clock for speaker output from system clock.
// This module includes configurable frequency divider and duty cycle control.
//------------------------------------------------------------------------------

module spk_clock_gen #(
    parameter IN_FREQ = 100_000_000,  // 100MHz system clock
    parameter PDM_FREQ = 3_072_000     // 3MHz PDM clock -- default set to 3.072MHz same as input 
)(
    input  logic clk,           // System clock input
    input  logic rst_n,         // Active low reset
    input  logic enable,        // Clock enable
    output logic pdm_clk,       // PDM clock output
    output logic locked         // PLL/clock stable indicator
);

    // Calculate the division ratio
    localparam DIV_RATIO = IN_FREQ / (2 * PDM_FREQ);
    localparam COUNT_WIDTH = $clog2(DIV_RATIO);
    
    // Counter for clock division
    logic [COUNT_WIDTH-1:0] counter;
    logic pll_stable;
    
    // Counter for clock division
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= '0;
            pdm_clk <= 1'b0;
            pll_stable <= 1'b0;
        end else if (enable) begin
            if (counter == DIV_RATIO - 1) begin
                counter <= '0;
                pdm_clk <= ~pdm_clk;
            end else begin
                counter <= counter + 1'b1;
            end
            // Set stable after initial cycles
            if (counter > 10) begin
                pll_stable <= 1'b1;
            end
        end else begin
            pdm_clk <= 1'b0;
            pll_stable <= 1'b0;
        end
    end
    
    // Lock indication
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            locked <= 1'b0;
        end else begin
            locked <= pll_stable && enable;
        end
    end

endmodule