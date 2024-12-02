
module audio_fifo #(
    parameter DEPTH = 1024,
    parameter WIDTH = 8,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  logic                clk,
    input  logic                rst_n,
    input  logic                write_en,
    input  logic                read_en,
    input  logic [WIDTH-1:0]    data_in,
    output logic [31:0]         data_out,
    output logic                empty,
    output logic                full
);
    // Instantiate Xilinx FIFO IP Core
    fifo_generator_0 fifo_inst (
        .clk        (clk),
        .srst       (!rst_n),
        .din        (data_in),
        .wr_en      (write_en),
        .rd_en      (read_en),
        .dout       (data_out),
        .full       (full),
        .empty      (empty)
    );

endmodule