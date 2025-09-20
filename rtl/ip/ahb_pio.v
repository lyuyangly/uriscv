module ahb_pio (
    input   wire                hclk,
	input   wire                hreset_n,
	input   wire                hsel,
	input   wire    [1:0]       htrans,
	input   wire    [2:0]       hsize,
	input   wire                hwrite,
	input   wire    [31:0]      haddr,
	input   wire    [31:0]      hwdata,
	output  reg     [31:0]      hrdata,
	output  wire                hresp,
	input   wire                hready_in,
	output  wire                hready_out,
    output  wire    [31:0]      pio
);

// Registers
reg     [31:0]  pio_reg;
reg		        ram_wr, ram_rd;

always @(posedge hclk or negedge hreset_n)
begin
	if (~hreset_n)
		ram_wr <= 1'b0;
	else begin
		if (hsel && (htrans[1] == 1'b1) && hwrite)
			ram_wr <= 1'b1;
		else
			ram_wr <= 1'b0;
	end
end

always @(*)
begin
	if (hsel && (htrans[1] == 1'b1) && !hwrite)
		ram_rd = 1'b1;
	else
		ram_rd = 1'b0;
end

always @(posedge hclk or negedge hreset_n)
begin
	if (!hreset_n) begin
        pio_reg <= 'h0;
		hrdata  <= 'h0;
    end
	else begin
		if (ram_wr)
			pio_reg <= hwdata;
		else if (ram_rd)
			hrdata <= pio_reg;
        else
            hrdata <= 'h0;
	end
end

assign hready_out = 1'b1;
assign hresp      = 1'b0;
assign pio        = pio_reg;

endmodule

