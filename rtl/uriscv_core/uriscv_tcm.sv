module uriscv_tcm (
    input                   clk,
    input                   rst_n,
    input                   mem_i_rd_i,
    input       [31:0]      mem_i_pc_i,
    output                  mem_i_accept_o,
    output                  mem_i_valid_o,
    output      [31:0]      mem_i_inst_o,
    input                   mem_d_rd_i,
    input       [ 3:0]      mem_d_wr_i,
    input       [31:0]      mem_d_addr_i,
    input       [31:0]      mem_d_data_wr_i,
    output      [31:0]      mem_d_data_rd_o,
    input       [10:0]      mem_d_req_tag_i,
    output                  mem_d_accept_o,
    output                  mem_d_ack_o,
    output      [10:0]      mem_d_resp_tag_o,
    input                   ext_rd_i,
    input       [ 3:0]      ext_wr_i,
    input       [31:0]      ext_addr_i,
    output      [31:0]      ext_read_data_o,
    input       [31:0]      ext_write_data_i,
    output                  ext_accept_o,
    output                  mem_out_rd_o,
    output      [ 3:0]      mem_out_wr_o,
    output      [31:0]      mem_out_addr_o,
    input       [31:0]      mem_out_data_rd_i,
    output      [31:0]      mem_out_data_wr_o,
    output      [10:0]      mem_out_req_tag_o,
    output                  mem_out_resp_accept_o,
    input                   mem_out_accept_i,
    input                   mem_out_ack_i,
    input       [10:0]      mem_out_resp_tag_i
);

logic   [ 3:0]      wr0_w;
logic   [13:0]      addr0_w;
logic   [31:0]      data0_w;
logic   [ 3:0]      wr1_w;
logic   [13:0]      addr1_w;
logic   [31:0]      data1_w;
logic   [31:0]      ram_read0_q;
logic   [31:0]      ram_read1_q;

/* verilator lint_off MULTIDRIVEN */
reg     [31:0]      ram[1024:0];
/* verilator lint_on MULTIDRIVEN */

initial $readmemh("../app/app_test.txt", ram);

//-------------------------------------------------------------
// Dual Port RAM
//-------------------------------------------------------------
wire mem_d_external_w    = (mem_d_addr_i >= 32'h80000000);

// Mux access to the 2nd port between external access and CPU data access
wire [13:0] muxed_addr_w = ext_accept_o ? ext_addr_i[15:2] : mem_d_addr_i[15:2];
wire [31:0] muxed_data_w = ext_accept_o ? ext_write_data_i : mem_d_data_wr_i;
wire [3:0]  muxed_wr_w   = ext_accept_o ? ext_wr_i         : mem_d_wr_i & {4{!mem_d_external_w}};
wire [31:0] data_r_w     = ram_read1_q;

assign mem_i_inst_o    = ram_read0_q;
assign ext_read_data_o = data_r_w;

/* verilator lint_off WIDTH */
always_ff @(posedge clk)
begin
    if (wr0_w[0])
        ram[addr0_w][7:0]   <= data0_w[7:0];
    if (wr0_w[1])
        ram[addr0_w][15:8]  <= data0_w[15:8];
    if (wr0_w[2])
        ram[addr0_w][23:16] <= data0_w[23:16];
    if (wr0_w[3])
        ram[addr0_w][31:24] <= data0_w[31:24];

    ram_read0_q <= ram[addr0_w];

    if (wr1_w[0])
        ram[addr1_w][7:0]   <= data1_w[7:0];
    if (wr1_w[1])
        ram[addr1_w][15:8]  <= data1_w[15:8];
    if (wr1_w[2])
        ram[addr1_w][23:16] <= data1_w[23:16];
    if (wr1_w[3])
        ram[addr1_w][31:24] <= data1_w[31:24];

    ram_read1_q <= ram[addr1_w];
end
/* verilator lint_on WIDTH */

assign wr0_w    = 4'h0;
assign addr0_w  = mem_i_pc_i[15:2];
assign data0_w  = 32'h0;

assign wr1_w    = muxed_wr_w;
assign addr1_w  = muxed_addr_w;
assign data1_w  = muxed_data_w;

//-------------------------------------------------------------
// Instruction Fetch
//-------------------------------------------------------------
logic   mem_i_valid_q;

always_ff @(posedge clk, negedge rst_n)
begin
    if (~rst_n)
        mem_i_valid_q <= 1'b0;
    else
        mem_i_valid_q <= mem_i_rd_i;
end

assign mem_i_accept_o  = 1'b1;
assign mem_i_valid_o   = mem_i_valid_q;

//-------------------------------------------------------------
// Data Access / Incoming external access
//-------------------------------------------------------------
logic           mem_d_accept_q;
logic   [10:0]  mem_d_tag_q;
logic           mem_d_ack_q;

always_ff @(posedge clk, negedge rst_n)
begin
    if (~rst_n)
        mem_d_accept_q <= 1'b1;
    // External request, do not accept internal requests in next cycle
    else if (ext_rd_i || ext_wr_i != 4'b0)
        mem_d_accept_q <= 1'b0;
    else
        mem_d_accept_q <= 1'b1;
end

always_ff @(posedge clk, negedge rst_n)
begin
    if (~rst_n)
    begin
        mem_d_ack_q    <= 1'b0;
        mem_d_tag_q    <= 11'b0;
    end
    else if ((mem_d_rd_i || mem_d_wr_i != 4'b0) && !mem_d_external_w && mem_d_accept_o)
    begin
        mem_d_ack_q    <= 1'b1;
        mem_d_tag_q    <= mem_d_req_tag_i;
    end
    else
        mem_d_ack_q    <= 1'b0;
end

// Back-pressure external responses if internal response in-progress
assign mem_out_resp_accept_o = ~mem_d_ack_q;
assign mem_d_ack_o           = mem_out_ack_i | mem_d_ack_q;
assign mem_d_resp_tag_o      = mem_d_ack_q ? mem_d_tag_q : mem_out_resp_tag_i;
assign mem_d_data_rd_o       = mem_d_ack_q ? data_r_w    : mem_out_data_rd_i;
assign mem_d_accept_o        = mem_d_external_w ? mem_out_accept_i : mem_d_accept_q;
assign ext_accept_o          = !mem_d_accept_q;

// Internal -> External
assign mem_out_addr_o        = mem_d_addr_i;
assign mem_out_data_wr_o     = mem_d_data_wr_i;
assign mem_out_rd_o          = mem_d_external_w ? mem_d_rd_i : 1'b0;
assign mem_out_wr_o          = mem_d_external_w ? mem_d_wr_i : 4'b0;
assign mem_out_req_tag_o     = mem_d_req_tag_i;

endmodule
