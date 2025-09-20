module top (
    input           clk,
    input           rst_n,
    input           intr_i,
    output  [31:0]  pio
);

wire            hsel_ram;
wire            hsel_pio;
wire    [1:0]   htrans;
wire    [2:0]   hsize;
wire    [2:0]   hburst;
wire            hwrite;
wire    [31:0]  haddr;
wire    [31:0]  hwdata;
wire    [31:0]  hrdata;
wire            hready;
wire            hready_ram;
wire            hready_pio;
wire    [1:0]   hresp;

uriscv_ahb_top u_riscv (
    .hclk           (clk            ),
    .hreset_n       (rst_n          ),
    .intr_i         (intr_i         ),
    .htrans         (htrans         ),
    .hsize          (hsize          ),
    .hburst         (hburst         ),
    .hwrite         (hwrite         ),
    .haddr          (haddr          ),
    .hwdata         (hwdata         ),
    .hrdata         (hrdata         ),
    .hready_in      (hready         ),
    .hresp          (hresp          )
);

ahb_ram u_ram (
    .hclk           (clk            ),
    .hreset_n       (rst_n          ),
    .hsel           (hsel_ram       ),
    .htrans         (htrans         ),
    .hsize          (hsize          ),
    .hwrite         (hwrite         ),
    .haddr          (haddr[13:0]    ),
    .hwdata         (hwdata         ),
    .hrdata         (hrdata         ),
    .hready_in      (hready         ),
    .hready_out     (hready_ram     ),
    .hresp          ()
);

ahb_pio u_pio (
    .hclk           (clk            ),
    .hreset_n       (rst_n          ),
    .hsel           (hsel_pio       ),
    .htrans         (htrans         ),
    .hsize          (hsize          ),
    .hwrite         (hwrite         ),
    .haddr          (haddr          ),
    .hwdata         (hwdata         ),
    .hrdata         (),
    .hready_in      (hready         ),
    .hready_out     (hready_pio     ),
    .hresp          (),
    .pio            (pio            )
);

assign hready   = hready_ram | hready_pio;
assign hresp    = 2'h0;
assign hsel_ram = (haddr[31:28] == 4'h8);
assign hsel_pio = (haddr[31:28] == 4'hF);

endmodule

