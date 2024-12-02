module wav_header_parser (
    input  logic clk,
    input  logic rst_n,
    
    // Data Interface
    input  logic [7:0] data_in,
    input  logic data_valid,
    output logic data_ready,
    
    // Header Information
    output logic [31:0] sample_rate,
    output logic [15:0] bit_depth,
    output logic [15:0] num_channels,
    output logic data_start,      // Indicates start of audio data
    output logic header_valid,    // Header successfully parsed
    output logic format_error     // Invalid format detected
);

    // Header field offsets
    localparam RIFF_OFFSET = 0;
    localparam FORMAT_OFFSET = 8;
    localparam SUBCHUNK1_OFFSET = 12;
    localparam AUDIO_FORMAT_OFFSET = 20;
    localparam NUM_CHANNELS_OFFSET = 22;
    localparam SAMPLE_RATE_OFFSET = 24;
    localparam BITS_PER_SAMPLE_OFFSET = 34;
    localparam DATA_CHUNK_OFFSET = 36;
    
    // State machine
    typedef enum logic [3:0] {
        CHECK_RIFF,
        CHECK_WAVE,
        CHECK_FMT,
        READ_FORMAT,
        READ_CHANNELS,
        READ_SAMPLE_RATE,
        READ_BIT_DEPTH,
        FIND_DATA,
        COMPLETE,
        ERROR
    } state_t;
    
    state_t current_state, next_state;
    
    // Byte counter and accumulator
    logic [7:0] byte_count;
    logic [31:0] accumulator;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= CHECK_RIFF;
            byte_count <= 0;
            accumulator <= 0;
            sample_rate <= 0;
            bit_depth <= 0;
            num_channels <= 0;
            header_valid <= 0;
            format_error <= 0;
            data_start <= 0;
        end else begin
            current_state <= next_state;
            
            if (data_valid && data_ready) begin
                accumulator <= {accumulator[23:0], data_in};
                byte_count <= byte_count + 1;
                
                case (current_state)
                    CHECK_RIFF: begin
                        if (byte_count == 3) begin
                            if (accumulator[23:0] != 24'h524946) begin // "RIF"
                                format_error <= 1;
                                next_state <= ERROR;
                            end
                        end
                    end
                    
                    CHECK_WAVE: begin
                        if (byte_count == 3) begin
                            if (accumulator[23:0] != 24'h574156) begin // "WAV"
                                format_error <= 1;
                                next_state <= ERROR;
                            end
                        end
                    end
                    
                    READ_FORMAT: begin
                        if (byte_count == 1) begin
                            if (accumulator[15:0] != 16'h0001) begin // PCM = 1
                                format_error <= 1;
                                next_state <= ERROR;
                            end
                        end
                    end
                    
                    READ_CHANNELS: begin
                        if (byte_count == 1) begin
                            num_channels <= accumulator[15:0];
                        end
                    end
                    
                    READ_SAMPLE_RATE: begin
                        if (byte_count == 3) begin
                            sample_rate <= accumulator;
                        end
                    end
                    
                    READ_BIT_DEPTH: begin
                        if (byte_count == 1) begin
                            bit_depth <= accumulator[15:0];
                        end
                    end
                    
                    FIND_DATA: begin
                        if (byte_count == 3) begin
                            if (accumulator[23:0] == 24'h646174) begin // "dat"
                                data_start <= 1;
                                header_valid <= 1;
                                next_state <= COMPLETE;
                            end
                        end
                    end
                endcase
            end
        end
    end
    
    // Next state and control signals
    always_comb begin
        next_state = current_state;
        data_ready = 1;
        
        case (current_state)
            CHECK_RIFF: begin
                if (byte_count == 4) next_state = CHECK_WAVE;
            end
            
            CHECK_WAVE: begin
                if (byte_count == 4) next_state = READ_FORMAT;
            end
            
            READ_FORMAT: begin
                if (byte_count == 2) next_state = READ_CHANNELS;
            end
            
            READ_CHANNELS: begin
                if (byte_count == 2) next_state = READ_SAMPLE_RATE;
            end
            
            READ_SAMPLE_RATE: begin
                if (byte_count == 4) next_state = READ_BIT_DEPTH;
            end
            
            READ_BIT_DEPTH: begin
                if (byte_count == 2) next_state = FIND_DATA;
            end
            
            COMPLETE, ERROR: begin
                data_ready = 0;
            end
        endcase
    end

endmodule