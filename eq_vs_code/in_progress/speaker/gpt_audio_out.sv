//------------------------------------------------------------------------------
// Module: pdm_speaker_driver
//------------------------------------------------------------------------------
// Controls PDM speaker output with proper timing and signal conditioning.
// Includes output drive strength control and protection features.
//------------------------------------------------------------------------------

module pdm_speaker_driver #(
    parameter OUTPUT_STRENGTH = 2'b11    // Output drive strength (00=min, 11=max)
)(
    input  logic clk,           // System clock
    input  logic pdm_clk,       // PDM clock input
    input  logic rst_n,         // Active low reset
    input  logic pdm_in,        // PDM input signal
    input  logic pdm_valid,     // PDM valid signal
    input  logic enable,        // Speaker enable
    
    // Speaker Interface
    output logic spk_pdm,       // Speaker PDM output
    output logic spk_en,        // Speaker enable
    
    // Status Interface
    output logic overload,      // Speaker overload detection
    output logic active         // Speaker actively playing
);

    // Internal signals
    logic [7:0] pulse_counter;  // Counter for overload protection
    logic [1:0] drive_strength; // Current drive strength setting
    
    // Synchronize PDM input to PDM clock domain
    logic pdm_sync1, pdm_sync2;
    always_ff @(posedge pdm_clk or negedge rst_n) begin
        if (!rst_n) begin
            pdm_sync1 <= 1'b0;
            pdm_sync2 <= 1'b0;
        end else begin
            pdm_sync1 <= pdm_in;
            pdm_sync2 <= pdm_sync1;
        end
    end
    
    // Overload protection - count consecutive high pulses
    always_ff @(posedge pdm_clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_counter <= 8'h0;
            overload <= 1'b0;
        end else if (pdm_sync2 && pdm_valid) begin
            if (pulse_counter < 8'hFF) begin
                pulse_counter <= pulse_counter + 1'b1;
            end
            overload <= (pulse_counter > 8'hF0);
        end else begin
            pulse_counter <= 8'h0;
            overload <= 1'b0;
        end
    end
    
    // Drive strength control
    always_ff @(posedge pdm_clk or negedge rst_n) begin
        if (!rst_n) begin
            drive_strength <= OUTPUT_STRENGTH;
        end else if (overload) begin
            drive_strength <= 2'b01; // Reduce strength on overload
        end else begin
            drive_strength <= OUTPUT_STRENGTH;
        end
    end
    
    // Speaker output control
    always_ff @(posedge pdm_clk or negedge rst_n) begin
        if (!rst_n) begin
            spk_pdm <= 1'b0;
            spk_en <= 1'b0;
            active <= 1'b0;
        end else begin
            spk_pdm <= pdm_sync2 && !overload && enable;
            spk_en <= enable && pdm_valid && !overload;
            active <= enable && pdm_valid;
        end
    end

endmodule