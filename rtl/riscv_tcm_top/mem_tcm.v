module mem_tcm (
    input           clk_i,
    input           rst_i,
    input   [ 31:0] mem_d_addr_i,
    input   [ 31:0] mem_d_data_wr_i,
    input           mem_d_rd_i,
    input   [  3:0] mem_d_wr_i,
    input           mem_d_cacheable_i,
    input   [ 10:0] mem_d_req_tag_i,
    input           mem_d_invalidate_i,
    input           mem_d_flush_i,
    input           mem_i_rd_i,
    input           mem_i_flush_i,
    input           mem_i_invalidate_i,
    input   [ 31:0] mem_i_pc_i,
    input   [  3:0] ext_wr_i,
    input           ext_rd_i,
    input   [ 31:0] ext_addr_i,
    input   [ 31:0] ext_write_data_i,
    input   [ 31:0] mem_out_data_rd_i,
    input           mem_out_accept_i,
    input           mem_out_ack_i,
    input   [ 10:0] mem_out_resp_tag_i,
    output  [ 31:0] mem_d_data_rd_o,
    output          mem_d_accept_o,
    output          mem_d_ack_o,
    output  [ 10:0] mem_d_resp_tag_o,
    output          mem_i_accept_o,
    output          mem_i_valid_o,
    output  [ 31:0] mem_i_inst_o,
    output  [ 31:0] ext_read_data_o,
    output          ext_accept_o,
    output  [ 31:0] mem_out_addr_o,
    output  [ 31:0] mem_out_data_wr_o,
    output          mem_out_rd_o,
    output  [  3:0] mem_out_wr_o,
    output          mem_out_cacheable_o,
    output  [ 10:0] mem_out_req_tag_o,
    output          mem_out_invalidate_o,
    output          mem_out_flush_o,
    output          mem_out_resp_accept_o
);

//-------------------------------------------------------------
// Dual Port RAM
//-------------------------------------------------------------
wire mem_d_external_w    = (mem_d_addr_i >= 32'h80000000);

// Mux access to the 2nd port between external access and CPU data access
wire [13:0] muxed_addr_w = ext_accept_o ? ext_addr_i[15:2] : mem_d_addr_i[15:2];
wire [31:0] muxed_data_w = ext_accept_o ? ext_write_data_i : mem_d_data_wr_i;
wire [3:0]  muxed_wr_w   = ext_accept_o ? ext_wr_i         : mem_d_wr_i & {4{!mem_d_external_w}};
wire [31:0] data_r_w;

ram_dp_4k u_ram
(
    // Instruction fetch
     .clk0_i(clk_i)
    ,.rst0_i(rst_i)
    ,.addr0_i(mem_i_pc_i[15:2])
    ,.data0_i(32'b0)
    ,.wr0_i(4'b0)

    // External access / Data access
    ,.clk1_i(clk_i)
    ,.rst1_i(rst_i)
    ,.addr1_i(muxed_addr_w)
    ,.data1_i(muxed_data_w)
    ,.wr1_i(muxed_wr_w)

    // Outputs
    ,.data0_o(mem_i_inst_o)
    ,.data1_o(data_r_w)
);

assign ext_read_data_o = data_r_w;

//-------------------------------------------------------------
// Instruction Fetch
//-------------------------------------------------------------
reg        mem_i_valid_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    mem_i_valid_q <= 1'b0;
else
    mem_i_valid_q <= mem_i_rd_i;

assign mem_i_accept_o  = 1'b1;
assign mem_i_valid_o   = mem_i_valid_q;

//-------------------------------------------------------------
// Data Access / Incoming external access
//-------------------------------------------------------------
reg        mem_d_accept_q;
reg [10:0] mem_d_tag_q;
reg        mem_d_ack_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    mem_d_accept_q <= 1'b1;
// External request, do not accept internal requests in next cycle
else if (ext_rd_i || ext_wr_i != 4'b0)
    mem_d_accept_q <= 1'b0;
else
    mem_d_accept_q <= 1'b1;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
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


// Back-pressure external responses if internal response in-progress
assign mem_out_resp_accept_o = ~mem_d_ack_q;

assign mem_d_ack_o          = mem_out_ack_i | mem_d_ack_q;
assign mem_d_resp_tag_o     = mem_d_ack_q ? mem_d_tag_q : mem_out_resp_tag_i;
assign mem_d_data_rd_o      = mem_d_ack_q ? data_r_w    : mem_out_data_rd_i;

assign mem_d_accept_o       = mem_d_external_w ? mem_out_accept_i : mem_d_accept_q;
assign ext_accept_o         = !mem_d_accept_q;

// Internal -> External
assign mem_out_addr_o       = mem_d_addr_i;
assign mem_out_data_wr_o    = mem_d_data_wr_i;
assign mem_out_rd_o         = mem_d_external_w ? mem_d_rd_i : 1'b0;
assign mem_out_wr_o         = mem_d_external_w ? mem_d_wr_i : 4'b0;
assign mem_out_req_tag_o    = mem_d_req_tag_i;

assign mem_out_cacheable_o  = 1'b0;
assign mem_out_invalidate_o = 1'b0;
assign mem_out_flush_o      = 1'b0;

endmodule
