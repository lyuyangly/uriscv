module uriscv_muldiv (
    input           clk,
    input           rst_n,
    input           valid_i,
    input           inst_mul_i,
    input           inst_mulh_i,
    input           inst_mulhsu_i,
    input           inst_mulhu_i,
    input           inst_div_i,
    input           inst_divu_i,
    input           inst_rem_i,
    input           inst_remu_i,
    input   [31:0]  operand_ra_i,
    input   [31:0]  operand_rb_i,
    output          ready_o,
    output  [31:0]  result_o
);

logic   [32:0]      mul_operand_a_q;
logic   [32:0]      mul_operand_b_q;
logic               mulhi_sel_q;
logic   [64:0]      mult_result_w;
logic   [32:0]      operand_b_r;
logic   [32:0]      operand_a_r;
logic   [31:0]      mul_result_r;
logic               mul_busy_q;
logic   [31:0]      dividend_q;
logic   [62:0]      divisor_q;
logic   [31:0]      quotient_q;
logic   [31:0]      q_mask_q;
logic               div_inst_q;
logic               div_busy_q;
logic               invert_res_q;
logic   [31:0]      div_result_r;
logic   [31:0]      result_q;
logic               ready_q;
logic               stall_w;

//-------------------------------------------------------------
// Multiplier
//-------------------------------------------------------------
wire mult_inst_w    = inst_mul_i     |
                      inst_mulh_i    |
                      inst_mulhsu_i  |
                      inst_mulhu_i;


always_comb
begin
    if (inst_mulhsu_i)
        operand_a_r = {operand_ra_i[31], operand_ra_i[31:0]};
    else if (inst_mulh_i)
        operand_a_r = {operand_ra_i[31], operand_ra_i[31:0]};
    else // MULHU || MUL
        operand_a_r = {1'b0, operand_ra_i[31:0]};
end

always_comb
begin
    if (inst_mulhsu_i)
        operand_b_r = {1'b0, operand_rb_i[31:0]};
    else if (inst_mulh_i)
        operand_b_r = {operand_rb_i[31], operand_rb_i[31:0]};
    else // MULHU || MUL
        operand_b_r = {1'b0, operand_rb_i[31:0]};
end

// Pipeline flops for multiplier
always_ff @(posedge clk, negedge rst_n)
begin
    if (~rst_n)
    begin
        mul_operand_a_q <= 33'b0;
        mul_operand_b_q <= 33'b0;
        mulhi_sel_q     <= 1'b0;
    end
    else if (valid_i && mult_inst_w)
    begin
        mul_operand_a_q <= operand_a_r;
        mul_operand_b_q <= operand_b_r;
        mulhi_sel_q     <= ~inst_mul_i;
    end
    else
    begin
        mul_operand_a_q <= 33'b0;
        mul_operand_b_q <= 33'b0;
        mulhi_sel_q     <= 1'b0;
    end
end

assign mult_result_w = {{ 32 {mul_operand_a_q[32]}}, mul_operand_a_q}*{{ 32 {mul_operand_b_q[32]}}, mul_operand_b_q};

always_comb
begin
    mul_result_r = mulhi_sel_q ? mult_result_w[63:32] : mult_result_w[31:0];
end

always_ff @(posedge clk, negedge rst_n)
begin
    if (~rst_n)
        mul_busy_q <= 1'b0;
    else
        mul_busy_q <= valid_i & mult_inst_w;
end

//-------------------------------------------------------------
// Divider
//-------------------------------------------------------------
wire div_rem_inst_w     = inst_div_i  |
                          inst_divu_i |
                          inst_rem_i  |
                          inst_remu_i;

wire signed_operation_w = inst_div_i | inst_rem_i;
wire div_operation_w    = inst_div_i | inst_divu_i;

wire div_start_w    = valid_i & div_rem_inst_w & !stall_w;
wire div_complete_w = !(|q_mask_q) & div_busy_q;

always_ff @(posedge clk, negedge rst_n)
begin
    if (~rst_n)
    begin
        div_busy_q     <= 1'b0;
        dividend_q     <= 32'b0;
        divisor_q      <= 63'b0;
        invert_res_q   <= 1'b0;
        quotient_q     <= 32'b0;
        q_mask_q       <= 32'b0;
        div_inst_q     <= 1'b0;
    end
    else if (div_start_w)
    begin
        div_busy_q     <= 1'b1;
        div_inst_q     <= div_operation_w;
    
        if (signed_operation_w && operand_ra_i[31])
            dividend_q <= -operand_ra_i;
        else
            dividend_q <= operand_ra_i;
    
        if (signed_operation_w && operand_rb_i[31])
            divisor_q <= {-operand_rb_i, 31'b0};
        else
            divisor_q <= {operand_rb_i, 31'b0};
    
        invert_res_q  <= (inst_div_i && (operand_ra_i[31] != operand_rb_i[31]) && |operand_rb_i) ||
                         (inst_rem_i && operand_ra_i[31]);
    
        quotient_q     <= 32'b0;
        q_mask_q       <= 32'h80000000;
    end
    else if (div_complete_w)
    begin
        div_busy_q <= 1'b0;
    end
    else if (div_busy_q)
    begin
        if (divisor_q <= {31'b0, dividend_q})
        begin
            dividend_q <= dividend_q - divisor_q[31:0];
            quotient_q <= quotient_q | q_mask_q;
        end
    
        divisor_q <= {1'b0, divisor_q[62:1]};
        q_mask_q  <= {1'b0, q_mask_q[31:1]};
    end
end

always_comb
begin
    div_result_r = 32'b0;

    if (div_inst_q)
        div_result_r = invert_res_q ? -quotient_q : quotient_q;
    else
        div_result_r = invert_res_q ? -dividend_q : dividend_q;
end

//-------------------------------------------------------------
// Shared logic
//-------------------------------------------------------------
// Stall if divider logic is busy and new multiplier or divider op
assign stall_w = (div_busy_q & (mult_inst_w | div_rem_inst_w)) |
                 (mul_busy_q & div_rem_inst_w);

always_ff @(posedge clk, negedge rst_n)
begin
    if (~rst_n)
        ready_q <= 1'b0;
    else if (mul_busy_q)
        ready_q <= 1'b1;
    else if (div_complete_w)
        ready_q <= 1'b1;
    else
        ready_q <= 1'b0;
end

always_ff @(posedge clk, negedge rst_n)
begin
    if (~rst_n)
        result_q <= 32'b0;
    else if (div_complete_w)
        result_q <= div_result_r;
    else if (mul_busy_q)
        result_q <= mul_result_r;
end

assign result_o  = result_q;
assign ready_o   = ready_q;

endmodule
