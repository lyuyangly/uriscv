module uriscv_alu (
    input       [3:0]   op_i,
    input       [31:0]  a_i,
    input       [31:0]  b_i,
    output      [31:0]  p_o
);

//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
logic   [31:0]      result_r;
logic   [31:16]     shift_right_fill_r;
logic   [31:0]      shift_right_1_r;
logic   [31:0]      shift_right_2_r;
logic   [31:0]      shift_right_4_r;
logic   [31:0]      shift_right_8_r;
logic   [31:0]      shift_left_1_r;
logic   [31:0]      shift_left_2_r;
logic   [31:0]      shift_left_4_r;
logic   [31:0]      shift_left_8_r;
logic   [31:0]      sub_res_w;

assign sub_res_w = a_i - b_i;

//-----------------------------------------------------------------
// ALU
//-----------------------------------------------------------------
always_comb
begin
    shift_right_fill_r = 'h0;
    shift_right_1_r    = 'h0;
    shift_right_2_r    = 'h0;
    shift_right_4_r    = 'h0;
    shift_right_8_r    = 'h0;
    shift_left_1_r     = 'h0;
    shift_left_2_r     = 'h0;
    shift_left_4_r     = 'h0;
    shift_left_8_r     = 'h0;
    case (op_i)
        //----------------------------------------------
        // Shift Left
        //----------------------------------------------
        `RV_ALU_SHIFTL :
        begin
             if (b_i[0] == 1'b1)
                 shift_left_1_r = {a_i[30:0],1'b0};
             else
                 shift_left_1_r = a_i;

             if (b_i[1] == 1'b1)
                 shift_left_2_r = {shift_left_1_r[29:0],2'b00};
             else
                 shift_left_2_r = shift_left_1_r;

             if (b_i[2] == 1'b1)
                 shift_left_4_r = {shift_left_2_r[27:0],4'b0000};
             else
                 shift_left_4_r = shift_left_2_r;

             if (b_i[3] == 1'b1)
                 shift_left_8_r = {shift_left_4_r[23:0],8'b00000000};
             else
                 shift_left_8_r = shift_left_4_r;

             if (b_i[4] == 1'b1)
                 result_r = {shift_left_8_r[15:0],16'b0000000000000000};
             else
                 result_r = shift_left_8_r;
        end
        //----------------------------------------------
        // Shift Right
        //----------------------------------------------
        `RV_ALU_SHIFTR, `RV_ALU_SHIFTR_ARITH:
        begin
             // Arithmetic shift? Fill with 1's if MSB set
             if (a_i[31] == 1'b1 && op_i == `RV_ALU_SHIFTR_ARITH)
                 shift_right_fill_r = 16'b1111111111111111;
             else
                 shift_right_fill_r = 16'b0000000000000000;

             if (b_i[0] == 1'b1)
                 shift_right_1_r = {shift_right_fill_r[31], a_i[31:1]};
             else
                 shift_right_1_r = a_i;

             if (b_i[1] == 1'b1)
                 shift_right_2_r = {shift_right_fill_r[31:30], shift_right_1_r[31:2]};
             else
                 shift_right_2_r = shift_right_1_r;

             if (b_i[2] == 1'b1)
                 shift_right_4_r = {shift_right_fill_r[31:28], shift_right_2_r[31:4]};
             else
                 shift_right_4_r = shift_right_2_r;

             if (b_i[3] == 1'b1)
                 shift_right_8_r = {shift_right_fill_r[31:24], shift_right_4_r[31:8]};
             else
                 shift_right_8_r = shift_right_4_r;

             if (b_i[4] == 1'b1)
                 result_r = {shift_right_fill_r[31:16], shift_right_8_r[31:16]};
             else
                 result_r = shift_right_8_r;
        end
        //----------------------------------------------
        // Arithmetic
        //----------------------------------------------
        `RV_ALU_ADD :
        begin
             result_r      = (a_i + b_i);
        end
        `RV_ALU_SUB :
        begin
             result_r      = sub_res_w;
        end
        //----------------------------------------------
        // Logical
        //----------------------------------------------
        `RV_ALU_AND :
        begin
             result_r      = (a_i & b_i);
        end
        `RV_ALU_OR  :
        begin
             result_r      = (a_i | b_i);
        end
        `RV_ALU_XOR :
        begin
             result_r      = (a_i ^ b_i);
        end
        //----------------------------------------------
        // Comparision
        //----------------------------------------------
        `RV_ALU_LESS_THAN :
        begin
             result_r      = (a_i < b_i) ? 32'h1 : 32'h0;
        end
        `RV_ALU_LESS_THAN_SIGNED :
        begin
             if (a_i[31] != b_i[31])
                 result_r  = a_i[31] ? 32'h1 : 32'h0;
             else
                 result_r  = sub_res_w[31] ? 32'h1 : 32'h0;
        end
        default :
        begin
             result_r      = a_i;
        end
    endcase
end

assign p_o = result_r;

endmodule
