module uriscv_csr (
    input               clk,
    input               rst_n,
    input               intr_i,
    input   [31:0]      isr_vector_i,
    input   [31:0]      cpu_id_i,
    input               valid_i,
    input   [31:0]      pc_i,
    input   [31:0]      opcode_i,
    input   [31:0]      rs1_val_i,
    input   [31:0]      rs2_val_i,
    output  [31:0]      csr_rdata_o,
    input               excpn_invalid_inst_i,
    input               excpn_lsu_align_i,
    input   [31:0]      mem_addr_i,
    output  [31:0]      csr_mepc_o,
    output              exception_o,
    output  [5:0]       exception_type_o,
    output  [31:0]      exception_pc_o
);

logic   take_interrupt_w;
logic   exception_w;

//-----------------------------------------------------------------
// Instruction Decode
//-----------------------------------------------------------------
wire [2:0] func3_w     = opcode_i[14:12]; // R, I, S
wire [4:0] rs1_w       = opcode_i[19:15];

wire type_system_w     = (opcode_i[6:2] == 5'b11100);
wire type_store_w      = (opcode_i[6:2] == 5'b01000);

wire inst_csr_w        = type_system_w && (func3_w != 3'b000 && func3_w != 3'b100);
wire inst_csrrw_w      = inst_csr_w  && (func3_w == 3'b001);
wire inst_csrrs_w      = inst_csr_w  && (func3_w == 3'b010);
wire inst_csrrc_w      = inst_csr_w  && (func3_w == 3'b011);
wire inst_csrrwi_w     = inst_csr_w  && (func3_w == 3'b101);
wire inst_csrrsi_w     = inst_csr_w  && (func3_w == 3'b110);
wire inst_csrrci_w     = inst_csr_w  && (func3_w == 3'b111);

wire inst_ecall_w      = type_system_w && (opcode_i[31:7] == 25'h000000);
wire inst_ebreak_w     = type_system_w && (opcode_i[31:7] == 25'h002000);
wire inst_mret_w       = type_system_w && (opcode_i[31:7] == 25'h604000);

wire [11:0] csr_addr_w = valid_i ? opcode_i[31:20] : 12'b0;
wire [31:0] csr_data_w = (inst_csrrwi_w || inst_csrrsi_w || inst_csrrci_w) ? {27'b0, rs1_w} : rs1_val_i;
wire        csr_set_w  = (valid_i && !exception_w) ? (inst_csrrw_w || inst_csrrs_w || inst_csrrwi_w || inst_csrrsi_w): 1'b0;
wire        csr_clr_w  = (valid_i && !exception_w) ? (inst_csrrw_w || inst_csrrc_w || inst_csrrwi_w || inst_csrrci_w): 1'b0;

//-----------------------------------------------------------------
// Execute: CSR Access
//-----------------------------------------------------------------
reg [31:0] csr_mepc_q;
reg [31:0] csr_mepc_r;
reg [31:0] csr_mcause_q;
reg [31:0] csr_mcause_r;
reg [31:0] csr_sr_q;
reg [31:0] csr_sr_r;
reg [31:0] csr_mcycle_q;
reg [31:0] csr_mcycle_r;
reg [31:0] csr_mtimecmp_q;
reg [31:0] csr_mtimecmp_r;
reg [31:0] csr_mscratch_q;
reg [31:0] csr_mscratch_r;
reg [31:0] csr_mip_q;
reg [31:0] csr_mip_r;
reg [31:0] csr_mie_q;
reg [31:0] csr_mie_r;
reg [31:0] csr_mtvec_q;
reg [31:0] csr_mtvec_r;
reg [31:0] csr_mtval_q;
reg [31:0] csr_mtval_r;

always_comb
begin
    csr_mepc_r      = csr_mepc_q;
    csr_mcause_r    = csr_mcause_q;
    csr_sr_r        = csr_sr_q;

    csr_mcycle_r    = csr_mcycle_q + 32'd1;
    csr_mtimecmp_r  = csr_mtimecmp_q;
    csr_mscratch_r  = csr_mscratch_q;
    csr_mip_r       = csr_mip_q;
    csr_mie_r       = csr_mie_q;
    csr_mtvec_r     = csr_mtvec_q;
    csr_mtval_r     = csr_mtval_q;

    // External interrupt
    if (intr_i)
        csr_mip_r[`IRQ_M_EXT] = 1'b1;

    // Timer match - generate IRQ
    if (csr_mcycle_r == csr_mtimecmp_r)
        csr_mip_r[`SR_IP_MTIP_R] = 1'b1;

    // Execute instruction / exception
    if (valid_i)
    begin
        // Exception / break / ecall
        if (exception_w || inst_ebreak_w || inst_ecall_w)
        begin
            // Save interrupt / supervisor state
            csr_sr_r[`SR_MPIE_R] = csr_sr_q[`SR_MIE_R];
            csr_sr_r[`SR_MPP_R]  = `PRIV_MACHINE;

            // Disable interrupts and enter supervisor mode
            csr_sr_r[`SR_MIE_R]  = 1'b0;

            // Save PC of next instruction (not yet executed)
            csr_mepc_r           = pc_i;

            // Extra info (badaddr / fault opcode)
            csr_mtval_r          = 32'b0;

            // Exception source
            if (excpn_invalid_inst_i)
            begin
                csr_mcause_r   = `MCAUSE_ILLEGAL_INSTRUCTION;
                csr_mtval_r    = opcode_i;
            end
            else if (inst_ebreak_w)
                csr_mcause_r   = `MCAUSE_BREAKPOINT;
            else if (inst_ecall_w)
                csr_mcause_r   = `MCAUSE_ECALL_M;
            else if (excpn_lsu_align_i)
            begin
                csr_mcause_r   = type_store_w ? `MCAUSE_MISALIGNED_STORE : `MCAUSE_MISALIGNED_LOAD;
                csr_mtval_r    = mem_addr_i;
            end
            else if (take_interrupt_w)
                csr_mcause_r   = `MCAUSE_INTERRUPT;
        end
        // MRET
        else if (inst_mret_w)
        begin
            // Interrupt enable pop
            csr_sr_r[`SR_MIE_R]  = csr_sr_r[`SR_MPIE_R];
            csr_sr_r[`SR_MPIE_R] = 1'b1;

            // This CPU only supports machine mode
            csr_sr_r[`SR_MPP_R] = `PRIV_MACHINE;
        end
        else
        begin
            case (csr_addr_w)
                `CSR_MEPC:
                begin
                    if (csr_set_w && csr_clr_w)
                        csr_mepc_r = csr_data_w;
                    else if (csr_set_w)
                        csr_mepc_r = csr_mepc_r | csr_data_w;
                    else if (csr_clr_w)
                        csr_mepc_r = csr_mepc_r & ~csr_data_w;
                end
                `CSR_MCAUSE:
                begin
                    if (csr_set_w && csr_clr_w)
                        csr_mcause_r = csr_data_w;
                    else if (csr_set_w)
                        csr_mcause_r = csr_mcause_r | csr_data_w;
                    else if (csr_clr_w)
                        csr_mcause_r = csr_mcause_r & ~csr_data_w;
                end
                `CSR_MSTATUS:
                begin
                    if (csr_set_w && csr_clr_w)
                        csr_sr_r = csr_data_w;
                    else if (csr_set_w)
                        csr_sr_r = csr_sr_r | csr_data_w;
                    else if (csr_clr_w)
                        csr_sr_r = csr_sr_r & ~csr_data_w;
                end
                `CSR_MTIMECMP:
                begin
                    if (csr_set_w && csr_data_w != 32'b0)
                    begin
                        csr_mtimecmp_r = csr_data_w;

                        // Clear interrupt pending
                        csr_mip_r[`SR_IP_MTIP_R] = 1'b0;
                    end
                end
                `CSR_MSCRATCH:
                begin
                    if (csr_set_w && csr_clr_w)
                        csr_mscratch_r = csr_data_w;
                    else if (csr_set_w)
                        csr_mscratch_r = csr_mscratch_r | csr_data_w;
                    else if (csr_clr_w)
                        csr_mscratch_r = csr_mscratch_r & ~csr_data_w;
                end
                `CSR_MIP:
                begin
                    if (csr_set_w && csr_clr_w)
                        csr_mip_r = csr_data_w;
                    else if (csr_set_w)
                        csr_mip_r = csr_mip_r | csr_data_w;
                    else if (csr_clr_w)
                        csr_mip_r = csr_mip_r & ~csr_data_w;
                end
                `CSR_MIE:
                begin
                    if (csr_set_w && csr_clr_w)
                        csr_mie_r = csr_data_w;
                    else if (csr_set_w)
                        csr_mie_r = csr_mie_r | csr_data_w;
                    else if (csr_clr_w)
                        csr_mie_r = csr_mie_r & ~csr_data_w;
                end
                `CSR_MTVEC:
                begin
                    if (csr_set_w && csr_clr_w)
                        csr_mtvec_r = csr_data_w;
                    else if (csr_set_w)
                        csr_mtvec_r = csr_mtvec_r | csr_data_w;
                    else if (csr_clr_w)
                        csr_mtvec_r = csr_mtvec_r & ~csr_data_w;
                end
                `CSR_MTVAL:
                begin
                    if (csr_set_w && csr_clr_w)
                        csr_mtval_r = csr_data_w;
                    else if (csr_set_w)
                        csr_mtval_r = csr_mtval_r | csr_data_w;
                    else if (csr_clr_w)
                        csr_mtval_r = csr_mtval_r & ~csr_data_w;
                end
                default : ;
            endcase
        end
    end
end

always_ff @(posedge clk, negedge rst_n)
begin
    if (~rst_n)
    begin
        csr_mepc_q       <= 32'b0;
        csr_mcause_q     <= 32'b0;
        csr_sr_q         <= 32'b0;
        csr_mcycle_q     <= 32'b0;
        csr_mtimecmp_q   <= 32'b0;
        csr_mscratch_q   <= 32'b0;
        csr_mie_q        <= 32'b0;
        csr_mip_q        <= 32'b0;
        csr_mtvec_q      <= 32'b0;
        csr_mtval_q      <= 32'b0;
    end
    else
    begin
        csr_mepc_q       <= csr_mepc_r;
        csr_mcause_q     <= csr_mcause_r;
        csr_sr_q         <= csr_sr_r;
        csr_mcycle_q     <= csr_mcycle_r;
        csr_mtimecmp_q   <= csr_mtimecmp_r;
        csr_mscratch_q   <= csr_mscratch_r;
        csr_mie_q        <= csr_mie_r;
        csr_mip_q        <= csr_mip_r;
        csr_mtvec_q      <= csr_mtvec_r;
        csr_mtval_q      <= csr_mtval_r;
    end
end

//-----------------------------------------------------------------
// CSR Read Data MUX
//-----------------------------------------------------------------
reg [31:0] csr_data_r;

always_comb
begin
    csr_data_r = 32'b0;

    case (csr_addr_w)
        `CSR_MEPC:      csr_data_r = csr_mepc_q & `CSR_MEPC_MASK;
        `CSR_MCAUSE:    csr_data_r = csr_mcause_q & `CSR_MCAUSE_MASK;
        `CSR_MSTATUS:   csr_data_r = csr_sr_q & `CSR_MSTATUS_MASK;
        `CSR_MTVEC:     csr_data_r = csr_mtvec_q & `CSR_MTVEC_MASK;
        `CSR_MTVAL:     csr_data_r = csr_mtval_q & `CSR_MTVAL_MASK;
        `CSR_MTIME,
        `CSR_MCYCLE:    csr_data_r = csr_mcycle_q & `CSR_MTIME_MASK;
        `CSR_MTIMECMP:  csr_data_r = csr_mtimecmp_q & `CSR_MTIMECMP_MASK;
        `CSR_MSCRATCH:  csr_data_r = csr_mscratch_q & `CSR_MSCRATCH_MASK;
        `CSR_MIP:       csr_data_r = csr_mip_q & `CSR_MIP_MASK;
        `CSR_MIE:       csr_data_r = csr_mie_q & `CSR_MIE_MASK;
        `CSR_MISA:      csr_data_r = `MISA_RVM | `MISA_RV32 | `MISA_RVI;
        `CSR_MHARTID:   csr_data_r = cpu_id_i;
        default:        csr_data_r = 32'b0;
    endcase
end

assign csr_rdata_o       = csr_data_r;

// Interrupt request and interrupt enabled
assign take_interrupt_w  = (|(csr_mip_q & csr_mie_q)) & csr_sr_q[`SR_MIE_R];
assign exception_w       = valid_i && (take_interrupt_w || excpn_invalid_inst_i || excpn_lsu_align_i);

assign exception_o       = exception_w;
assign exception_pc_o    = csr_mtvec_q;
assign csr_mepc_o        = csr_mepc_q;

//-----------------------------------------------------------------
// Debug - exception type (checker use only)
//-----------------------------------------------------------------
reg [5:0] v_etype_r;

always_comb
begin
    v_etype_r = 6'b0;

    if (csr_mcause_r[`MCAUSE_INT])
        v_etype_r = `RV_EXCPN_INTERRUPT;
    else
        case (csr_mcause_r)
            `MCAUSE_MISALIGNED_FETCH   : v_etype_r = `RV_EXCPN_MISALIGNED_FETCH;
            `MCAUSE_FAULT_FETCH        : v_etype_r = `RV_EXCPN_FAULT_FETCH;
            `MCAUSE_ILLEGAL_INSTRUCTION: v_etype_r = `RV_EXCPN_ILLEGAL_INSTRUCTION;
            `MCAUSE_BREAKPOINT         : v_etype_r = `RV_EXCPN_BREAKPOINT;
            `MCAUSE_MISALIGNED_LOAD    : v_etype_r = `RV_EXCPN_MISALIGNED_LOAD;
            `MCAUSE_FAULT_LOAD         : v_etype_r = `RV_EXCPN_FAULT_LOAD;
            `MCAUSE_MISALIGNED_STORE   : v_etype_r = `RV_EXCPN_MISALIGNED_STORE;
            `MCAUSE_FAULT_STORE        : v_etype_r = `RV_EXCPN_FAULT_STORE;
            `MCAUSE_ECALL_U            : v_etype_r = `RV_EXCPN_ECALL_U;
            `MCAUSE_ECALL_S            : v_etype_r = `RV_EXCPN_ECALL_S;
            `MCAUSE_ECALL_H            : v_etype_r = `RV_EXCPN_ECALL_H;
            `MCAUSE_ECALL_M            : v_etype_r = `RV_EXCPN_ECALL_M;
            `MCAUSE_PAGE_FAULT_INST    : v_etype_r = `RV_EXCPN_PAGE_FAULT_INST;
            `MCAUSE_PAGE_FAULT_LOAD    : v_etype_r = `RV_EXCPN_PAGE_FAULT_LOAD;
            `MCAUSE_PAGE_FAULT_STORE   : v_etype_r = `RV_EXCPN_PAGE_FAULT_STORE;
            default                    : v_etype_r = 6'b0;
        endcase
end

assign exception_type_o = v_etype_r;

endmodule
