module uriscv_core #(
    parameter   SUPPORT_BRAM_REGFILE = 1,
    parameter   RST_VECTOR           = 32'h00000000
) (
    input           clk,
    input           rst_n,
    input           intr_i,
    // Instruction Fetch
    output          mem_i_rd_o,
    output  [31:0]  mem_i_pc_o,
    input   [31:0]  mem_i_inst_i,
    input           mem_i_accept_i,
    input           mem_i_valid_i,
    // Data Access
    output          mem_d_rd_o,
    output  [3:0]   mem_d_wr_o,
    output  [31:0]  mem_d_addr_o,
    input   [31:0]  mem_d_data_rd_i,
    output  [31:0]  mem_d_data_wr_o,
    input           mem_d_accept_i,
    input           mem_d_ack_i
);

// Current State
localparam  STATE_RESET    = 3'h0;
localparam  STATE_FETCH_WB = 3'h1;
localparam  STATE_EXEC     = 3'h2;
localparam  STATE_MEM      = 3'h3;
localparam  STATE_DECODE   = 3'h4; // Only if SUPPORT_BRAM_REGFILE = 1

// Current state
logic   [2:0]   state_q;

// Executing PC
logic   [31:0]  pc_q;

// Destination register
logic   [4:0]   rd_q;

// Destination writeback enable
logic           rd_wr_en_q;

// ALU inputs
logic   [31:0]  alu_a_q;
logic   [31:0]  alu_b_q;

// ALU operation selection
logic   [3:0]   alu_func_q;

// CSR read data
logic   [31:0]  csr_data_w;

// Instruction decode fault
logic           invalid_inst_r;

// Register indexes
logic   [4:0]   rd_w;

// Operand values
logic   [31:0]  rs1_val_w;
logic   [31:0]  rs2_val_w;

// Opcode (memory bus)
logic   [31:0]  opcode_w;

logic           opcode_valid_w;
logic           opcode_fetch_w;

// Execute exception (or interrupt)
logic           exception_w;
logic   [5:0]   exception_type_w;
logic   [31:0]  exception_target_w;

logic   [31:0]  csr_mepc_w;

// Load result (formatted based on load type)
logic   [31:0]  load_result_r;

// Writeback enable / value
logic           rd_writeen_w;
logic   [31:0]  rd_val_w;

// Memory interface
logic           mem_misaligned_w;
logic   [31:0]  mem_addr_q;
logic   [31:0]  mem_data_q;
logic   [3:0]   mem_wr_q;
logic           mem_rd_q;

// Load type / byte / half index
logic   [1:0]   load_offset_q;
logic           load_signed_q;
logic           load_byte_q;
logic           load_half_q;

logic   [31:0]  muldiv_result_w;
logic           muldiv_ready_w;
logic           muldiv_inst_w;

//-----------------------------------------------------------------
// ALU
//-----------------------------------------------------------------
uriscv_alu u_alu (
    .op_i   (alu_func_q ),
    .a_i    (alu_a_q    ),
    .b_i    (alu_b_q    ),
    .p_o    (rd_val_w   )
);

//-----------------------------------------------------------------
// Register file
//-----------------------------------------------------------------
logic   [31:0]  reg_file[0:31];
logic   [31:0]  rs1_val_gpr_w;
logic   [31:0]  rs2_val_gpr_w;
logic   [31:0]  rs1_val_gpr_q;
logic   [31:0]  rs2_val_gpr_q;

always_ff @(posedge clk)
begin
    reg_file[rd_q] <= rd_writeen_w ? rd_val_w : reg_file[rd_q];
end

assign rs1_val_gpr_w = reg_file[mem_i_inst_i[19:15]];
assign rs2_val_gpr_w = reg_file[mem_i_inst_i[24:20]];

always_ff @(posedge clk)
begin
    rs1_val_gpr_q <= rs1_val_gpr_w;
    rs2_val_gpr_q <= rs2_val_gpr_w;
end

assign rs1_val_w = SUPPORT_BRAM_REGFILE ? rs1_val_gpr_q : rs1_val_gpr_w;
assign rs2_val_w = SUPPORT_BRAM_REGFILE ? rs2_val_gpr_q : rs2_val_gpr_w;

// Writeback enable
assign rd_writeen_w  = rd_wr_en_q & (state_q == STATE_FETCH_WB);

// synthesis translate_off
wire [31:0] x0_zero_w = reg_file[0];
wire [31:0] x1_ra_w   = reg_file[1];
wire [31:0] x2_sp_w   = reg_file[2];
wire [31:0] x3_gp_w   = reg_file[3];
wire [31:0] x4_tp_w   = reg_file[4];
wire [31:0] x5_t0_w   = reg_file[5];
wire [31:0] x6_t1_w   = reg_file[6];
wire [31:0] x7_t2_w   = reg_file[7];
wire [31:0] x8_s0_w   = reg_file[8];
wire [31:0] x9_s1_w   = reg_file[9];
wire [31:0] x10_a0_w  = reg_file[10];
wire [31:0] x11_a1_w  = reg_file[11];
wire [31:0] x12_a2_w  = reg_file[12];
wire [31:0] x13_a3_w  = reg_file[13];
wire [31:0] x14_a4_w  = reg_file[14];
wire [31:0] x15_a5_w  = reg_file[15];
wire [31:0] x16_a6_w  = reg_file[16];
wire [31:0] x17_a7_w  = reg_file[17];
wire [31:0] x18_s2_w  = reg_file[18];
wire [31:0] x19_s3_w  = reg_file[19];
wire [31:0] x20_s4_w  = reg_file[20];
wire [31:0] x21_s5_w  = reg_file[21];
wire [31:0] x22_s6_w  = reg_file[22];
wire [31:0] x23_s7_w  = reg_file[23];
wire [31:0] x24_s8_w  = reg_file[24];
wire [31:0] x25_s9_w  = reg_file[25];
wire [31:0] x26_s10_w = reg_file[26];
wire [31:0] x27_s11_w = reg_file[27];
wire [31:0] x28_t3_w  = reg_file[28];
wire [31:0] x29_t4_w  = reg_file[29];
wire [31:0] x30_t5_w  = reg_file[30];
wire [31:0] x31_t6_w  = reg_file[31];
// synthesis translate_on

wire type_rvc_w     = (opcode_w[1:0] != 2'b11);
wire type_load_w    = (opcode_w[6:2] == 5'b00000);
wire type_opimm_w   = (opcode_w[6:2] == 5'b00100);
wire type_auipc_w   = (opcode_w[6:2] == 5'b00101);
wire type_store_w   = (opcode_w[6:2] == 5'b01000);
wire type_op_w      = (opcode_w[6:2] == 5'b01100);
wire type_lui_w     = (opcode_w[6:2] == 5'b01101);
wire type_branch_w  = (opcode_w[6:2] == 5'b11000);
wire type_jalr_w    = (opcode_w[6:2] == 5'b11001);
wire type_jal_w     = (opcode_w[6:2] == 5'b11011);
wire type_system_w  = (opcode_w[6:2] == 5'b11100);
wire type_miscm_w   = (opcode_w[6:2] == 5'b00011);

wire [2:0] func3_w  = opcode_w[14:12]; // R, I, S
wire [6:0] func7_w  = opcode_w[31:25]; // R

// ALU operations excluding mul/div
wire type_alu_op_w  = (type_op_w && (func7_w == 7'b0000000)) ||
                      (type_op_w && (func7_w == 7'b0100000));

// Loose decoding - gate with type_load_w on use
wire inst_lb_w       = (func3_w == 3'b000);
wire inst_lh_w       = (func3_w == 3'b001);
wire inst_lbu_w      = (func3_w == 3'b100);
wire inst_lhu_w      = (func3_w == 3'b101);

wire inst_ecall_w    = type_system_w && (opcode_w[31:7] == 25'h000000);
wire inst_ebreak_w   = type_system_w && (opcode_w[31:7] == 25'h002000);
wire inst_mret_w     = type_system_w && (opcode_w[31:7] == 25'h604000);
wire inst_csr_w      = type_system_w && (func3_w != 3'b000 && func3_w != 3'b100);
wire mul_inst_w      = type_op_w && (func7_w == 7'b0000001) && ~func3_w[2];
wire div_inst_w      = type_op_w && (func7_w == 7'b0000001) &&  func3_w[2];
wire inst_mul_w      = mul_inst_w && (func3_w == 3'b000);
wire inst_mulh_w     = mul_inst_w && (func3_w == 3'b001);
wire inst_mulhsu_w   = mul_inst_w && (func3_w == 3'b010);
wire inst_mulhu_w    = mul_inst_w && (func3_w == 3'b011);
wire inst_div_w      = div_inst_w && (func3_w == 3'b100);
wire inst_divu_w     = div_inst_w && (func3_w == 3'b101);
wire inst_rem_w      = div_inst_w && (func3_w == 3'b110);
wire inst_remu_w     = div_inst_w && (func3_w == 3'b111);
wire inst_nop_w      = (type_miscm_w && (func3_w == 3'b000)) | // fence
                       (type_miscm_w && (func3_w == 3'b001));  // fence.i

//-----------------------------------------------------------------
// Next State Logic
//-----------------------------------------------------------------
logic   [2:0]   next_state_r;

always_comb
begin
    next_state_r = state_q;

    case (state_q)
        // RESET - First cycle after reset
        STATE_RESET:
        begin
            next_state_r = STATE_FETCH_WB;
        end
        // FETCH_WB - Writeback / Fetch next isn
        STATE_FETCH_WB :
        begin
            if (opcode_fetch_w)
                next_state_r    = SUPPORT_BRAM_REGFILE ? STATE_DECODE : STATE_EXEC;
        end
        // DECODE - Used to access register file if SUPPORT_BRAM_REGFILE=1
        STATE_DECODE:
        begin
            if (mem_i_valid_i)
                next_state_r = STATE_EXEC;
        end
        // EXEC - Execute instruction (when ready)
        STATE_EXEC :
        begin
            // Instruction ready
            if (opcode_valid_w)
            begin
                if (exception_w)
                    next_state_r    = STATE_FETCH_WB;
                else if (type_load_w || type_store_w)
                    next_state_r    = STATE_MEM;
                // Multiplication / division - stay in exec state until result ready
                else if (muldiv_inst_w)
                    ;
                else
                    next_state_r    = STATE_FETCH_WB;
            end
            else if (muldiv_ready_w)
                next_state_r    = STATE_FETCH_WB;
        end
        // MEM - Perform load or store
        STATE_MEM :
        begin
            // Memory access complete
            if (mem_d_ack_i)
                next_state_r = STATE_FETCH_WB;
        end
        default : ;
    endcase
end

// Update State
always_ff @(posedge clk, negedge rst_n)
begin
    if (~rst_n)
        state_q   <= STATE_RESET;
    else
        state_q   <= next_state_r;
end

//-----------------------------------------------------------------
// Instruction Decode
//-----------------------------------------------------------------
logic   [31:0]  opcode_q;
logic           opcode_valid_q;

always_ff @(posedge clk, negedge rst_n)
begin
    if (~rst_n)
        opcode_q <= 32'h0;
    else if (state_q == STATE_DECODE)
        opcode_q <= mem_i_inst_i;
end

always_ff @(posedge clk, negedge rst_n)
begin
    if (~rst_n)
        opcode_valid_q <= 1'b0;
    else if (state_q == STATE_DECODE)
        opcode_valid_q <= mem_i_valid_i;
    else
        opcode_valid_q <= 1'b0;
end

assign opcode_fetch_w = mem_i_rd_o & mem_i_accept_i;
assign opcode_w       = SUPPORT_BRAM_REGFILE ? opcode_q : mem_i_inst_i;
assign opcode_valid_w = SUPPORT_BRAM_REGFILE ? opcode_valid_q : mem_i_valid_i;

assign rd_w  = opcode_w[11:7];

assign muldiv_inst_w = mul_inst_w | div_inst_w;

logic   [31:0]      imm20_r;
logic   [31:0]      imm12_r;

always_comb
begin
    imm20_r = {opcode_w[31:12], 12'b0};
    imm12_r = {{20{opcode_w[31]}}, opcode_w[31:20]};
end

//-----------------------------------------------------------------
// ALU inputs
//-----------------------------------------------------------------
// ALU operation selection
logic   [3:0]   alu_func_r;

// ALU operands
logic   [31:0]  alu_input_a_r;
logic   [31:0]  alu_input_b_r;
logic           write_rd_r;

always_comb
begin
    alu_func_r     = `RV_ALU_NONE;
    alu_input_a_r  = rs1_val_w;
    alu_input_b_r  = rs2_val_w;
    write_rd_r     = 1'b0;

    case (1'b1)
        type_alu_op_w:
        begin
            alu_input_a_r  = rs1_val_w;
            alu_input_b_r  = rs2_val_w;
        end
        type_opimm_w:
        begin
            alu_input_a_r  = rs1_val_w;
            alu_input_b_r  = imm12_r;
        end
        type_lui_w:
        begin
            alu_input_a_r  = 32'b0;
            alu_input_b_r  = imm20_r;
        end
        type_auipc_w:
        begin
            alu_input_a_r  = pc_q;
            alu_input_b_r  = imm20_r;
        end
        type_jal_w,
        type_jalr_w:
        begin
            alu_input_a_r  = pc_q;
            alu_input_b_r  = 32'd4;
        end
        default : ;
    endcase

    if (muldiv_inst_w)
        write_rd_r     = 1'b1;
    else if (type_opimm_w || type_alu_op_w)
    begin
        case (func3_w)
            3'b000:  alu_func_r =  (type_op_w & opcode_w[30]) ?
                                  `RV_ALU_SUB:              // SUB
                                  `RV_ALU_ADD;              // ADD  / ADDI
            3'b001:  alu_func_r = `RV_ALU_SHIFTL;           // SLL  / SLLI
            3'b010:  alu_func_r = `RV_ALU_LESS_THAN_SIGNED; // SLT  / SLTI
            3'b011:  alu_func_r = `RV_ALU_LESS_THAN;        // SLTU / SLTIU
            3'b100:  alu_func_r = `RV_ALU_XOR;              // XOR  / XORI
            3'b101:  alu_func_r = opcode_w[30] ?
                                  `RV_ALU_SHIFTR_ARITH:     // SRA  / SRAI
                                  `RV_ALU_SHIFTR;           // SRL  / SRLI
            3'b110:  alu_func_r = `RV_ALU_OR;               // OR   / ORI
            3'b111:  alu_func_r = `RV_ALU_AND;              // AND  / ANDI
        endcase

        write_rd_r = 1'b1;
    end
    else if (inst_csr_w)
    begin
        alu_func_r     = `RV_ALU_ADD;
        alu_input_a_r  = 32'b0;
        alu_input_b_r  = csr_data_w;
        write_rd_r     = 1'b1;
    end
    else if (type_auipc_w || type_lui_w || type_jalr_w || type_jal_w)
    begin
        write_rd_r     = 1'b1;
        alu_func_r     = `RV_ALU_ADD;
    end
    else if (type_load_w)
        write_rd_r     = 1'b1;
end

//-------------------------------------------------------------------
// Load result resolve
//-------------------------------------------------------------------
always_comb
begin
    load_result_r = 32'b0;

    if (load_byte_q)
    begin
        case (load_offset_q[1:0])
            2'h3:
                load_result_r = {24'b0, mem_d_data_rd_i[31:24]};
            2'h2:
                load_result_r = {24'b0, mem_d_data_rd_i[23:16]};
            2'h1:
                load_result_r = {24'b0, mem_d_data_rd_i[15:8]};
            2'h0:
                load_result_r = {24'b0, mem_d_data_rd_i[7:0]};
        endcase

        if (load_signed_q && load_result_r[7])
            load_result_r = {24'hFFFFFF, load_result_r[7:0]};
    end
    else if (load_half_q)
    begin
        if (load_offset_q[1])
            load_result_r = {16'b0, mem_d_data_rd_i[31:16]};
        else
            load_result_r = {16'b0, mem_d_data_rd_i[15:0]};

        if (load_signed_q && load_result_r[15])
            load_result_r = {16'hFFFF, load_result_r[15:0]};
    end
    else
        load_result_r = mem_d_data_rd_i;
end

//-----------------------------------------------------------------
// Branches
//-----------------------------------------------------------------
logic           branch_w;
logic   [31:0]  branch_target_w;

uriscv_branch u_branch (
    .pc_i               (pc_q               ),
    .opcode_i           (opcode_w           ),
    .rs1_val_i          (rs1_val_w          ),
    .rs2_val_i          (rs2_val_w          ),
    .branch_o           (branch_w           ),
    .branch_target_o    (branch_target_w    )
);

//-----------------------------------------------------------------
// Invalid instruction
//-----------------------------------------------------------------
always_comb
begin
    invalid_inst_r = 1'b1;

    if (   type_load_w
         | type_opimm_w
         | type_auipc_w
         | type_store_w
         | type_alu_op_w
         | type_lui_w
         | type_branch_w
         | type_jalr_w
         | type_jal_w
         | inst_ecall_w
         | inst_ebreak_w
         | inst_mret_w
         | inst_csr_w
         | inst_nop_w
         | muldiv_inst_w)
        invalid_inst_r = type_rvc_w;
end

//-----------------------------------------------------------------
// Execute: ALU control
//-----------------------------------------------------------------
always_ff @(posedge clk, negedge rst_n)
begin
    if (~rst_n)
    begin
        alu_func_q   <= `RV_ALU_NONE;
        alu_a_q      <= 32'h00000000;
        alu_b_q      <= 32'h00000000;
        rd_q         <= 5'b00000;
    
        // Reset x0 in-case of RAM
        rd_wr_en_q   <= 1'b1;
    end
    // Load result ready
    else if ((state_q == STATE_MEM) && mem_d_ack_i)
    begin
        // Update ALU input with load result
        alu_func_q   <= `RV_ALU_NONE;
        alu_a_q      <= load_result_r;
        alu_b_q      <= 32'b0;
    end
    // Multiplier / Divider result
    else if (muldiv_ready_w)
    begin
        // Update ALU input with load result
        alu_func_q   <= `RV_ALU_NONE;
        alu_a_q      <= muldiv_result_w;
        alu_b_q      <= 32'b0;
    end
    // Execute instruction
    else if (opcode_valid_w)
    begin
        // Update ALU input flops
        alu_func_q   <= alu_func_r;
        alu_a_q      <= alu_input_a_r;
        alu_b_q      <= alu_input_b_r;
    
        // Take exception
        if (exception_w)
        begin
            // No register writeback
            rd_q         <= 5'b0;
            rd_wr_en_q   <= 1'b0;
        end
        // Valid instruction
        else
        begin
            // Instruction with register writeback
            rd_q         <= rd_w;
            rd_wr_en_q   <= write_rd_r & (rd_w != 5'b0);
        end
    end
    else if (state_q == STATE_FETCH_WB)
       rd_wr_en_q   <= 1'b0;
end

//-----------------------------------------------------------------
// Execute: Branch / exceptions
//-----------------------------------------------------------------
always_ff @(posedge clk, negedge rst_n)
begin
    if (~rst_n)
        pc_q        <= RST_VECTOR;
    else if (state_q == STATE_RESET)
        pc_q        <= RST_VECTOR;
    else if (opcode_valid_w)
    begin
        // Exception / Break / ecall (branch to ISR)
        if (exception_w || inst_ebreak_w || inst_ecall_w)
            pc_q    <= exception_target_w;
        // MRET (branch to EPC)
        else if (inst_mret_w)
            pc_q    <= csr_mepc_w;
        // Branch
        else if (branch_w)
            pc_q    <= branch_target_w;
        else
            pc_q    <= pc_q + 'd4;
    end
end

//-----------------------------------------------------------------
// Writeback/Fetch: Instruction Fetch
//-----------------------------------------------------------------
assign mem_i_rd_o = (state_q == STATE_FETCH_WB);
assign mem_i_pc_o = pc_q;

//-----------------------------------------------------------------
// Execute: Memory operations
//-----------------------------------------------------------------
logic           mem_rd_w;
logic   [3:0]   mem_wr_w;
logic   [31:0]  mem_addr_w;
logic   [31:0]  mem_data_w;

uriscv_lsu u_lsu (
    .opcode_i           (opcode_w           ),
    .rs1_val_i          (rs1_val_w          ),
    .rs2_val_i          (rs2_val_w          ),
    .mem_rd_o           (mem_rd_w           ),
    .mem_wr_o           (mem_wr_w           ),
    .mem_addr_o         (mem_addr_w         ),
    .mem_data_o         (mem_data_w         ),
    .mem_misaligned_o   (mem_misaligned_w   )
);

always_ff @(posedge clk, negedge rst_n)
begin
    if (~rst_n)
    begin
        mem_addr_q  <= 32'h00000000;
        mem_data_q  <= 32'h00000000;
        mem_wr_q    <= 4'b0000;
        mem_rd_q    <= 1'b0;
    end
    // Valid instruction to execute
    else if (opcode_valid_w && !exception_w)
    begin
        mem_addr_q  <= {mem_addr_w[31:2], 2'b0};
        mem_data_q  <= mem_data_w;
        mem_wr_q    <= mem_wr_w;
        mem_rd_q    <= mem_rd_w;
    end
    // No instruction, clear memory request
    else if (mem_d_accept_i)
    begin
        mem_wr_q    <= 4'b0000;
        mem_rd_q    <= 1'b0;
    end
end

always_ff @(posedge clk, negedge rst_n)
begin
    if (~rst_n)
    begin
        load_signed_q  <= 1'b0;
        load_byte_q    <= 1'b0;
        load_half_q    <= 1'b0;
        load_offset_q  <= 2'b0;
    end
    // Valid instruction to execute
    else if (opcode_valid_w)
    begin
        load_signed_q  <= inst_lh_w | inst_lb_w;
        load_byte_q    <= inst_lb_w | inst_lbu_w;
        load_half_q    <= inst_lh_w | inst_lhu_w;
        load_offset_q  <= mem_addr_w[1:0];
    end
end

assign mem_d_addr_o    = mem_addr_q;
assign mem_d_data_wr_o = mem_data_q;
assign mem_d_wr_o      = mem_wr_q;
assign mem_d_rd_o      = mem_rd_q;

//-----------------------------------------------------------------
// Execute: CSR Access
//-----------------------------------------------------------------
uriscv_csr u_csr (
    .clk                    (clk                    ),
    .rst_n                  (rst_n                  ),
    // HartID
    .cpu_id_i               (32'h0                  ),
    // External interrupt
    .intr_i                 (intr_i                 ),
    // Executing instruction
    .valid_i                (opcode_valid_w         ),
    .opcode_i               (opcode_w               ),
    .pc_i                   (pc_q                   ),
    .rs1_val_i              (rs1_val_w              ),
    .rs2_val_i              (rs2_val_w              ),
    // CSR read result
    .csr_rdata_o            (csr_data_w             ),
    // Exception sources
    .excpn_invalid_inst_i   (invalid_inst_r         ),
    .excpn_lsu_align_i      (mem_misaligned_w       ),
    // Used on memory alignment errors
    .mem_addr_i             (mem_addr_w             ),
    // CSR registers
    .csr_mepc_o             (csr_mepc_w             ),
    // Exception entry
    .exception_o            (exception_w            ),
    .exception_type_o       (exception_type_w       ),
    .exception_pc_o         (exception_target_w     )
);

//-----------------------------------------------------------------
// Multiplier / Divider
//-----------------------------------------------------------------
uriscv_muldiv u_muldiv (
    .clk                    (clk                            ),
    .rst_n                  (rst_n                          ),
    // Operation select
    .valid_i                (opcode_valid_w & ~exception_w  ),
    .inst_mul_i             (inst_mul_w                     ),
    .inst_mulh_i            (inst_mulh_w                    ),
    .inst_mulhsu_i          (inst_mulhsu_w                  ),
    .inst_mulhu_i           (inst_mulhu_w                   ),
    .inst_div_i             (inst_div_w                     ),
    .inst_divu_i            (inst_divu_w                    ),
    .inst_rem_i             (inst_rem_w                     ),
    .inst_remu_i            (inst_remu_w                    ),
    // Operands
    .operand_ra_i           (rs1_val_w                      ),
    .operand_rb_i           (rs2_val_w                      ),
    // Result
    .ready_o                (muldiv_ready_w                 ),
    .result_o               (muldiv_result_w                )
);

//-------------------------------------------------------------------
// Hooks for debug
//-------------------------------------------------------------------
`ifdef verilator
reg        v_dbg_valid_q;
reg [31:0] v_dbg_pc_q;

always @ (posedge clk)
if (rst_n)
begin
    v_dbg_valid_q  <= 1'b0;
    v_dbg_pc_q     <= 32'b0;
end
else
begin
    v_dbg_valid_q  <= opcode_valid_w;
    v_dbg_pc_q     <= pc_q;
end

//-------------------------------------------------------------------
// get_valid: Instruction valid
//-------------------------------------------------------------------
function [0:0] get_valid; /*verilator public*/
begin
    get_valid = v_dbg_valid_q;
end
endfunction
//-------------------------------------------------------------------
// get_pc: Get executed instruction PC
//-------------------------------------------------------------------
function [31:0] get_pc; /*verilator public*/
begin
    get_pc = v_dbg_pc_q;
end
endfunction
//-------------------------------------------------------------------
// get_reg_valid: Register contents valid
//-------------------------------------------------------------------
function [0:0] get_reg_valid; /*verilator public*/
    input [4:0] r;
begin
    get_reg_valid = opcode_valid_w;
end
endfunction
//-------------------------------------------------------------------
// get_register: Read register file
//-------------------------------------------------------------------
function [31:0] get_register; /*verilator public*/
    input [4:0] r;
begin
    get_register = reg_file[r];
end
endfunction
`endif

endmodule
