module pcm_to_wav #(
    parameter SAMPLE_RATE    = 48000,     // Hz
    parameter BIT_DEPTH      = 32,        // Bits per sample
    parameter NUM_CHANNELS   = 1,         // 1 for mono, 2 for stereo
    parameter DATA_SIZE_IN_SECONDS = 30,  // Duration of data in seconds
    parameter FIFO_DEPTH     = 512        // Depth of FIFO buffer
)(
    // System Interface
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    
    // PCM Input Interface
    input  logic [BIT_DEPTH-1:0] pcm_data,
    input  logic        pcm_valid,
    output logic        pcm_ready,
    
    // WAV Output Interface
    output logic [7:0]  wav_data,
    output logic        wav_valid,
    input  logic        wav_ready,
    output logic        complete,
    
    // FIFO Status (optional, for debugging)
    output logic        fifo_full,
    output logic        fifo_empty,
    output logic [$clog2(FIFO_DEPTH):0] fifo_count
);

    // Calculate all constants
    localparam DATA_SIZE = SAMPLE_RATE * BIT_DEPTH/8 * NUM_CHANNELS * DATA_SIZE_IN_SECONDS;
    localparam BYTES_PER_SAMPLE = BIT_DEPTH/8;
    localparam BLOCK_ALIGN = NUM_CHANNELS * BYTES_PER_SAMPLE;
    localparam BYTE_RATE = SAMPLE_RATE * BLOCK_ALIGN;
    localparam FILE_SIZE = 36 + DATA_SIZE;  
    localparam RIFF_SIZE = FILE_SIZE - 8;   

    // Header ROM 
    logic [7:0] header [43:0];
    initial begin
        // RIFF Header
        header[0] = "R";  header[1] = "I";  header[2] = "F";  header[3] = "F";
        // Chunk Size
        {header[7], header[6], header[5], header[4]} = RIFF_SIZE;
        // WAVE Header
        header[8] = "W";  header[9] = "A";  header[10] = "V"; header[11] = "E";
        // fmt chunk
        header[12] = "f"; header[13] = "m"; header[14] = "t"; header[15] = " ";
        // Length of format data
        header[16] = 16;  header[17] = 0;   header[18] = 0;   header[19] = 0;
        // Audio format (1 = PCM)
        header[20] = 1;   header[21] = 0;
        // Number of channels
        {header[23], header[22]} = NUM_CHANNELS;
        // Sample Rate
        {header[27], header[26], header[25], header[24]} = SAMPLE_RATE;
        // Byte Rate
        {header[31], header[30], header[29], header[28]} = BYTE_RATE;
        // Block Align
        {header[33], header[32]} = BLOCK_ALIGN;
        // Bits per sample
        {header[35], header[34]} = BIT_DEPTH;
        // "data" chunk header
        header[36] = "d"; header[37] = "a"; header[38] = "t"; header[39] = "a";
        // data size
        {header[43], header[42], header[41], header[40]} = DATA_SIZE;
    end

    // Internal signals
    logic [5:0] byte_counter;
    logic [$clog2(BYTES_PER_SAMPLE)-1:0] byte_sel;
    logic [BIT_DEPTH-1:0] fifo_data_out;
    logic fifo_rd_en, fifo_wr_en;
    logic fifo_rd_valid;

    typedef enum logic [2:0] {
        IDLE,
        HEADER_OUTPUT,
        DATA_PROCESS,
        DONE
    } state_t;
    
    state_t current_state, next_state;

    // Instantiate FIFO IP
    fifo_generator_0 pcm_fifo (
        .clk(clk),
        .srst(!rst_n),
        
        // Write interface
        .din(pcm_data),
        .wr_en(fifo_wr_en),
        .full(fifo_full),
        
        // Read interface
        .dout(fifo_data_out),
        .rd_en(fifo_rd_en),
        .empty(fifo_empty),
        
        // Status
        .rd_data_count(fifo_count)
    );

    // FIFO control logic
    assign fifo_wr_en = pcm_valid && !fifo_full;
    assign pcm_ready = !fifo_full;

    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Next state logic
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (start) next_state = HEADER_OUTPUT;
            end
            
            HEADER_OUTPUT: begin
                if (wav_ready && byte_counter == 43) begin
                    next_state = DATA_PROCESS;
                end
            end
            
            DATA_PROCESS: begin
                if (byte_counter == DATA_SIZE-1 && byte_sel == BYTES_PER_SAMPLE-1 && wav_ready) begin
                    next_state = DONE;
                end
            end
            
            DONE: begin
                if (start) next_state = IDLE;
            end
        endcase
    end

    // Output and datapath logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_counter <= '0;
            byte_sel <= '0;
            wav_valid <= 1'b0;
            complete <= 1'b0;
            fifo_rd_en <= 1'b0;
            wav_data <= '0;
        end else begin
            case (current_state)
                IDLE: begin
                    byte_counter <= '0;
                    byte_sel <= '0;
                    wav_valid <= 1'b0;
                    complete <= 1'b0;
                    fifo_rd_en <= 1'b0;
                end

                HEADER_OUTPUT: begin
                    if (wav_ready) begin
                        wav_data <= header[byte_counter];
                        wav_valid <= 1'b1;
                        if (byte_counter != 43) begin
                            byte_counter <= byte_counter + 1;
                        end
                    end
                end

                DATA_PROCESS: begin
                    if (!fifo_empty && wav_ready) begin
                        // Read new sample from FIFO when starting new sample
                        if (byte_sel == 0) begin
                            fifo_rd_en <= 1'b1;
                        end else begin
                            fifo_rd_en <= 1'b0;
                        end

                        // Output current byte
                        wav_data <= fifo_data_out[byte_sel*8 +: 8];
                        wav_valid <= 1'b1;
                        
                        // Update counters
                        if (byte_sel == BYTES_PER_SAMPLE-1) begin
                            byte_sel <= '0;
                            if (byte_counter != DATA_SIZE-1) begin
                                byte_counter <= byte_counter + 1;
                            end
                        end else begin
                            byte_sel <= byte_sel + 1;
                        end
                    end else begin
                        wav_valid <= 1'b0;
                        fifo_rd_en <= 1'b0;
                    end
                end

                DONE: begin
                    complete <= 1'b1;
                    wav_valid <= 1'b0;
                    fifo_rd_en <= 1'b0;
                end
            endcase
        end
    end

endmodule