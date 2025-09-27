module uriscv_top (
    input                   clk,
    input                   rst_n,
    input                   intr_i,
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

uriscv_tcm u_riscv_tcm (
    .clk                    (clk                    ),
    .rst_n                  (rst_n                  ),
    .mem_i_rd_i             (mem_i_rd_w             ),
    .mem_i_pc_i             (mem_i_pc_w             ),
    .mem_i_inst_o           (mem_i_inst_w           ),
    .mem_i_accept_o         (mem_i_accept_w         ),
    .mem_i_valid_o          (mem_i_valid_w          ),
    .mem_d_rd_i             (mem_d_rd_w             ),
    .mem_d_wr_i             (mem_d_wr_w             ),
    .mem_d_addr_i           (mem_d_addr_w           ),
    .mem_d_data_wr_i        (mem_d_data_wr_w        ),
    .mem_d_data_rd_o        (mem_d_data_rd_w        ),
    .mem_d_req_tag_i        (11'h0                  ),
    .mem_d_accept_o         (mem_d_accept_w         ),
    .mem_d_ack_o            (mem_d_ack_w            ),
    .mem_d_resp_tag_o       (                       ),
    .ext_rd_i               (ext_rd_i               ),
    .ext_wr_i               (ext_wr_i               ),
    .ext_addr_i             (ext_addr_i             ),
    .ext_read_data_o        (ext_read_data_o        ),
    .ext_write_data_i       (ext_write_data_i       ),
    .ext_accept_o           (ext_accept_o           ),
    .mem_out_rd_o           (mem_out_rd_o           ),
    .mem_out_wr_o           (mem_out_wr_o           ),
    .mem_out_addr_o         (mem_out_addr_o         ),
    .mem_out_data_rd_i      (mem_out_data_rd_i      ),
    .mem_out_data_wr_o      (mem_out_data_wr_o      ),
    .mem_out_req_tag_o      (mem_out_req_tag_o      ),
    .mem_out_resp_accept_o  (mem_out_resp_accept_o  ),
    .mem_out_accept_i       (mem_out_accept_i       ),
    .mem_out_ack_i          (mem_out_ack_i          ),
    .mem_out_resp_tag_i     (mem_out_resp_tag_i     )
);

endmodule

