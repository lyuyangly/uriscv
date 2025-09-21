`timescale 1ns / 1ps
module tb_top;

logic           clk;
logic           rst_n;
logic           intr_w;

top u_dut (
    .clk        (clk        ),
    .rst_n      (rst_n      ),
    .intr_i     (intr_w     ),    
    .pio        ()
);

initial forever #5 clk = ~clk;

initial
begin
    clk    = 0;
    rst_n  = 0;
    intr_w = 0;
    repeat(100) @(posedge clk);
    rst_n  = 1;
    #50us;
    $finish;
end

endmodule
