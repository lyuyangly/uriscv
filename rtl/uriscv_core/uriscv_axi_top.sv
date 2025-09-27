module uriscv_axi_top (
    input   logic               clk,
    input   logic               rst_n,
    input   logic               intr_i,
    output  logic   [3:0]       awlen,
    output  logic   [2:0]       awsize,
    output  logic   [1:0]       awburst,
    output  logic   [31:0]      awaddr,
    output  logic               awvalid,
    input   logic               awready,
    output  logic   [31:0]      wdata,
    output  logic   [3:0]       wstrb,
    output  logic               wlast,
    output  logic               wvalid,
    input   logic               wready,
    input   logic   [1:0]       bresp,
    input   logic               bvalid,
    output  logic               bready,
    output  logic   [3:0]       arlen,
    output  logic   [2:0]       arsize,
    output  logic   [1:0]       arburst,
    output  logic   [31:0]      araddr,
    output  logic               arvalid,
    input   logic               arready,
    input   logic   [31:0]      rdata,
    input   logic               rlast,
    input   logic   [1:0]       rresp,
    input   logic               rvalid,
    output  logic               rready
);

wire                mem_i_rd_w;
wire    [31:0]      mem_i_pc_w;
wire    [31:0]      mem_i_inst_w;
wire                mem_i_accept_w;
wire                mem_i_valid_w;
wire                mem_d_rd_w;
wire    [ 3:0]      mem_d_wr_w;
wire    [31:0]      mem_d_addr_w;
wire    [31:0]      mem_d_data_wr_w;
wire    [31:0]      mem_d_data_rd_w;
wire                mem_d_accept_w;
wire                mem_d_ack_w;

uriscv_core #(
    .SUPPORT_BRAM_REGFILE (1),
    .RST_VECTOR           (32'h00000000)
) u_uriscv_core (
    .clk                    (clk                    ),
    .rst_n                  (rst_n                  ),
    .intr_i                 (intr_i                 ),
    .mem_i_rd_o             (mem_i_rd_w		        ),
    .mem_i_pc_o             (mem_i_pc_w		        ),
    .mem_i_inst_i           (mem_i_inst_w	        ),
    .mem_i_accept_i         (mem_i_accept_w	        ),
    .mem_i_valid_i          (mem_i_valid_w	        ),
    .mem_d_rd_o             (mem_d_rd_w		        ),
    .mem_d_wr_o             (mem_d_wr_w		        ),
    .mem_d_addr_o           (mem_d_addr_w	        ),
    .mem_d_data_rd_i        (mem_d_data_rd_w        ),
    .mem_d_data_wr_o        (mem_d_data_wr_w        ),
    .mem_d_accept_i         (mem_d_accept_w	        ),
    .mem_d_ack_i            (mem_d_ack_w	        )
);

assign mem_d_accept_w = awvalid & awready;
assign mem_d_ack_i    = wvalid & wready;

assign awlen   = 4'h0;
assign awsize  = (mem_d_wr_w == 4'hF) ? 3'h2 : ((mem_d_wr_w == 4'h3 || mem_d_wr_w == 4'hC) ? 3'h1 : 3'h0);
assign awburst = 2'h0;
assign awvalid = |mem_d_wr_w;
assign wdata   = mem_d_data_wr_w;
assign wstrb   = mem_d_wr_w;
assign wlast   = 1'b1;
assign wvalid  = 1'b1;
assign bready  = 1'b1;

assign arlen   = 4'h0;
assign arburst = 2'h0;
assign arsize  = 3'h2;

endmodule

