logic bram_or_pallette;// 0 = bram, 1= pallette
assign bram_or_pallette = axi_awaddr[13];
// Add user logic here

logic [15:0] palette[16];

logic [31:0] data_current;

logic bram_clk;
logic bram_en;
assign bram_clk = S_AXI_ACLK;
assign bram_en = 1'b1;


logic [10:0] bram_addr_a,bram_addr_b;
logic [31:0]  bram_din_b; //bram_din_a
logic [31:0]  bram_dout_b; //bram_dout_a
logic [3:0] bram_we_a, bram_we_b;
assign bram_we_b = 4'b0000;


logic [7:0] char_code;
assign rom_code = char_code;
logic [31:0] color_cmd;
assign cmd = color_cmd;

blk_mem_gen_0 blk_mem(
    .addra(bram_addr_a),
    .clka(bram_clk),
    .dina(bram_din_a),
    .douta(),
    .ena(bram_en),
    .wea(bram_we_a),
    
    .addrb(bram_addr_b),
    .clkb(bram_clk),
    .dinb(),
    .doutb(bram_dout_b),
    .enb(bram_en),
    .web(bram_we_b)
    
);
 