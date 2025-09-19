module uriscv_ahb_top (
    input   logic               hclk,
    input   logic               hreset_n,
    input   logic               intr_i,
    output  logic   [1:0]       htrans,
    output  logic   [2:0]       hsize,
    output  logic   [2:0]       hburst,
    output  logic               hwrite,
    output  logic   [31:0]      haddr,
    output  logic   [31:0]      hwdata,
    input   logic   [31:0]      hrdata,
    input   logic               hready_in,
    input   logic               hresp
);

logic           mem_out_rd_w;
logic   [3:0]   mem_out_wr_w;
logic           mem_out_ack_w;
logic           htrans_in_process;

uriscv_top u_riscv_top (
    .clk                    (hclk               ),
    .rst_n                  (hreset_n           ),
    .intr_i                 (intr_i             ),
    .ext_rd_i               (1'b0               ),
    .ext_wr_i               (4'h0               ),
    .ext_addr_i             (32'h0              ),
    .ext_read_data_o        (                   ),
    .ext_write_data_i       (32'h0              ),
    .ext_accept_o           (                   ),
    .mem_out_rd_o           (mem_out_rd_w       ),
    .mem_out_wr_o           (mem_out_wr_w       ),
    .mem_out_addr_o         (haddr              ),
    .mem_out_data_rd_i      (hrdata             ),
    .mem_out_data_wr_o      (hwdata             ),
    .mem_out_req_tag_o      (),
    .mem_out_resp_accept_o  (),
    .mem_out_accept_i       (1'b1               ),
    .mem_out_ack_i          (mem_out_ack_w      ),
    .mem_out_resp_tag_i     (11'h0              )
);

always_ff @(posedge hclk, negedge hreset_n)
begin
    if (~hreset_n)
        htrans_in_process <= 1'b0;
    else if (mem_out_rd_w | (|mem_out_wr_w) & hready_in & htrans_in_process)
        htrans_in_process <= 1'b0;
    else if (mem_out_rd_w | (|mem_out_wr_w) & hready_in & (~htrans_in_process))
        htrans_in_process <= 1'b1;
end

always_comb
begin
    case (mem_out_wr_w)
        4'b0001: hsize = 3'h0;
        4'b0010: hsize = 3'h0;
        4'b0100: hsize = 3'h0;
        4'b1000: hsize = 3'h0;
        4'b0011: hsize = 3'h1;
        4'b1100: hsize = 3'h1;
        4'b1111: hsize = 3'h2;
        default: hsize = 3'h2;
    endcase
end

assign htrans       = {(mem_out_rd_w | (|mem_out_wr_w)) & (~htrans_in_process), 1'b0};
assign hburst       = 3'h0;
assign hwrite       = |mem_out_wr_w;
assign mem_out_ack_w = htrans_in_process & hready_in & (hresp == 1'b0);

endmodule

