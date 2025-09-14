`timescale 1ns / 1ns
module riscv_tcm_top (
    input           clk_i,
    input           rst_i,
    input           rst_cpu_i,
    input           intr_i,
    input           axi_i_awready_i,
    input           axi_i_wready_i,
    input           axi_i_bvalid_i,
    input   [  1:0] axi_i_bresp_i,
    input           axi_i_arready_i,
    input           axi_i_rvalid_i,
    input   [ 31:0] axi_i_rdata_i,
    input   [  1:0] axi_i_rresp_i,
    output          axi_i_awvalid_o,
    output  [ 31:0] axi_i_awaddr_o,
    output          axi_i_wvalid_o,
    output  [ 31:0] axi_i_wdata_o,
    output  [  3:0] axi_i_wstrb_o,
    output          axi_i_bready_o,
    output          axi_i_arvalid_o,
    output  [ 31:0] axi_i_araddr_o,
    output          axi_i_rready_o,
    input           axi_t_awvalid_i,
    input   [ 31:0] axi_t_awaddr_i,
    input   [  3:0] axi_t_awid_i,
    input   [  7:0] axi_t_awlen_i,
    input   [  1:0] axi_t_awburst_i,
    input           axi_t_wvalid_i,
    input   [ 31:0] axi_t_wdata_i,
    input   [  3:0] axi_t_wstrb_i,
    input           axi_t_wlast_i,
    input           axi_t_bready_i,
    input           axi_t_arvalid_i,
    input   [ 31:0] axi_t_araddr_i,
    input   [  3:0] axi_t_arid_i,
    input   [  7:0] axi_t_arlen_i,
    input   [  1:0] axi_t_arburst_i,
    input           axi_t_rready_i,
    output          axi_t_awready_o,
    output          axi_t_wready_o,
    output          axi_t_bvalid_o,
    output  [  1:0] axi_t_bresp_o,
    output  [  3:0] axi_t_bid_o,
    output          axi_t_arready_o,
    output          axi_t_rvalid_o,
    output  [ 31:0] axi_t_rdata_o,
    output  [  1:0] axi_t_rresp_o,
    output  [  3:0] axi_t_rid_o,
    output          axi_t_rlast_o
);

wire  [ 31:0]  conv_ram_write_data_w;
wire           ext_out_flush_w;
wire  [ 10:0]  ext_out_req_tag_w;
wire  [ 31:0]  conv_ram_addr_w;
wire           conv_ram_rd_w;
wire           mem_out_resp_accept_w;
wire           ext_out_cacheable_w;
wire  [  3:0]  ext_out_wr_w;
wire  [ 31:0]  conv_ram_read_data_w;
wire           dcache_ack_w;
wire  [ 31:0]  icache_inst_w;
wire           ext_out_accept_w;
wire           ext_out_invalidate_w;
wire           dcache_rd_w;
wire  [ 31:0]  dcache_addr_w;
wire  [ 31:0]  dcache_data_rd_w;
wire  [ 10:0]  ext_out_resp_tag_w;
wire           icache_valid_w;
wire  [ 31:0]  ext_out_data_wr_w;
wire           dcache_accept_w;
wire           icache_accept_w;
wire  [  3:0]  conv_ram_wr_w;
wire           conv_ram_accept_w;
wire  [ 31:0]  ext_out_addr_w;
wire           ext_out_rd_w;
wire           ext_out_ack_w;
wire  [  3:0]  dcache_wr_w;
wire  [ 31:0]  icache_pc_w;
wire           icache_rd_w;
wire  [ 31:0]  ext_out_data_rd_w;
wire  [ 31:0]  dcache_data_wr_w;

uriscv_core u_core (
    .clk_i(clk_i),
    .rst_i(rst_cpu_i),
    .cpu_id_i(32'b0),
    .intr_i(intr_i),
    .mem_i_rd_o(icache_rd_w),
    .mem_i_pc_o(icache_pc_w),
    .mem_i_inst_i(icache_inst_w),
    .mem_i_accept_i(icache_accept_w),
    .mem_i_valid_i(icache_valid_w),
    .mem_d_wr_o(dcache_wr_w),
    .mem_d_rd_o(dcache_rd_w),
    .mem_d_data_wr_o(dcache_data_wr_w),
    .mem_d_data_rd_i(dcache_data_rd_w),
    .mem_d_addr_o(dcache_addr_w),
    .mem_d_accept_i(dcache_accept_w),
    .mem_d_ack_i(dcache_ack_w)
);

axi4_ram_bridge u_axi_ram_bridge (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .axi_awvalid_i(axi_t_awvalid_i),
    .axi_awaddr_i(axi_t_awaddr_i),
    .axi_awid_i(axi_t_awid_i),
    .axi_awlen_i(axi_t_awlen_i),
    .axi_awburst_i(axi_t_awburst_i),
    .axi_wvalid_i(axi_t_wvalid_i),
    .axi_wdata_i(axi_t_wdata_i),
    .axi_wstrb_i(axi_t_wstrb_i),
    .axi_wlast_i(axi_t_wlast_i),
    .axi_bready_i(axi_t_bready_i),
    .axi_arvalid_i(axi_t_arvalid_i),
    .axi_araddr_i(axi_t_araddr_i),
    .axi_arid_i(axi_t_arid_i),
    .axi_arlen_i(axi_t_arlen_i),
    .axi_arburst_i(axi_t_arburst_i),
    .axi_rready_i(axi_t_rready_i),
    .ram_read_data_i(conv_ram_read_data_w),
    .ram_accept_i(conv_ram_accept_w),
    .axi_awready_o(axi_t_awready_o),
    .axi_wready_o(axi_t_wready_o),
    .axi_bvalid_o(axi_t_bvalid_o),
    .axi_bresp_o(axi_t_bresp_o),
    .axi_bid_o(axi_t_bid_o),
    .axi_arready_o(axi_t_arready_o),
    .axi_rvalid_o(axi_t_rvalid_o),
    .axi_rdata_o(axi_t_rdata_o),
    .axi_rresp_o(axi_t_rresp_o),
    .axi_rid_o(axi_t_rid_o),
    .axi_rlast_o(axi_t_rlast_o),
    .ram_wr_o(conv_ram_wr_w),
    .ram_rd_o(conv_ram_rd_w),
    .ram_addr_o(conv_ram_addr_w),
    .ram_write_data_o(conv_ram_write_data_w)
);

mem_axi u_mem_axi (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .mem_addr_i(ext_out_addr_w),
    .mem_data_wr_i(ext_out_data_wr_w),
    .mem_rd_i(ext_out_rd_w),
    .mem_wr_i(ext_out_wr_w),
    .mem_cacheable_i(ext_out_cacheable_w),
    .mem_req_tag_i(ext_out_req_tag_w),
    .mem_invalidate_i(ext_out_invalidate_w),
    .mem_flush_i(ext_out_flush_w),
    .mem_resp_accept_i(mem_out_resp_accept_w),
    .axi_awready_i(axi_i_awready_i),
    .axi_wready_i(axi_i_wready_i),
    .axi_bvalid_i(axi_i_bvalid_i),
    .axi_bresp_i(axi_i_bresp_i),
    .axi_arready_i(axi_i_arready_i),
    .axi_rvalid_i(axi_i_rvalid_i),
    .axi_rdata_i(axi_i_rdata_i),
    .axi_rresp_i(axi_i_rresp_i),
    .mem_data_rd_o(ext_out_data_rd_w),
    .mem_accept_o(ext_out_accept_w),
    .mem_ack_o(ext_out_ack_w),
    .mem_resp_tag_o(ext_out_resp_tag_w),
    .axi_awvalid_o(axi_i_awvalid_o),
    .axi_awaddr_o(axi_i_awaddr_o),
    .axi_wvalid_o(axi_i_wvalid_o),
    .axi_wdata_o(axi_i_wdata_o),
    .axi_wstrb_o(axi_i_wstrb_o),
    .axi_bready_o(axi_i_bready_o),
    .axi_arvalid_o(axi_i_arvalid_o),
    .axi_araddr_o(axi_i_araddr_o),
    .axi_rready_o(axi_i_rready_o)
);

mem_tcm u_mem_tcm (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .mem_d_addr_i(dcache_addr_w),
    .mem_d_data_wr_i(dcache_data_wr_w),
    .mem_d_rd_i(dcache_rd_w),
    .mem_d_wr_i(dcache_wr_w),
    .mem_d_cacheable_i(1'b0),
    .mem_d_req_tag_i(11'd0),
    .mem_d_invalidate_i(1'b0),
    .mem_d_flush_i(1'b0),
    .mem_i_rd_i(icache_rd_w),
    .mem_i_flush_i(1'b0),
    .mem_i_invalidate_i(1'b0),
    .mem_i_pc_i(icache_pc_w),
    .ext_wr_i(conv_ram_wr_w),
    .ext_rd_i(conv_ram_rd_w),
    .ext_addr_i(conv_ram_addr_w),
    .ext_write_data_i(conv_ram_write_data_w),
    .mem_out_data_rd_i(ext_out_data_rd_w),
    .mem_out_accept_i(ext_out_accept_w),
    .mem_out_ack_i(ext_out_ack_w),
    .mem_out_resp_tag_i(ext_out_resp_tag_w),
    .mem_d_data_rd_o(dcache_data_rd_w),
    .mem_d_accept_o(dcache_accept_w),
    .mem_d_ack_o(dcache_ack_w),
    .mem_d_resp_tag_o(),
    .mem_i_accept_o(icache_accept_w),
    .mem_i_valid_o(icache_valid_w),
    .mem_i_inst_o(icache_inst_w),
    .ext_read_data_o(conv_ram_read_data_w),
    .ext_accept_o(conv_ram_accept_w),
    .mem_out_addr_o(ext_out_addr_w),
    .mem_out_data_wr_o(ext_out_data_wr_w),
    .mem_out_rd_o(ext_out_rd_w),
    .mem_out_wr_o(ext_out_wr_w),
    .mem_out_cacheable_o(ext_out_cacheable_w),
    .mem_out_req_tag_o(ext_out_req_tag_w),
    .mem_out_invalidate_o(ext_out_invalidate_w),
    .mem_out_flush_o(ext_out_flush_w),
    .mem_out_resp_accept_o(mem_out_resp_accept_w)
);

endmodule
