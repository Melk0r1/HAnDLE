----------------------------------------------------------------------------------------------
--
--      Input file         : decode.vhd
--      Design name        : decode
--      Author             : Tamar Kranenburg
--      Modified by        : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--      Description        : ID stage
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.config_Pkg.all;
use work.core_Pkg.all;
use work.std_Pkg.all;

entity decode is
    generic(
        G_INTERRUPT  : boolean := CFG_INTERRUPT;
        G_USE_HW_MUL : boolean := CFG_USE_HW_MUL;
        G_USE_HW_DIV : boolean := CFG_USE_HW_DIV;
        G_USE_BARREL : boolean := CFG_USE_BARREL;
        G_DEBUG      : boolean := CFG_DEBUG
    );
    port (
        decode_o          : out decode_out_type;
        gprf_o            : out gprf_out_type;
        addr_free_d_mem_i : in std_logic_vector(4 downto 0);
        free_d_mem_i      : in std_logic;
        stall_mem         : in std_logic;
        decode_i          : in decode_in_type;
        stall             : out std_logic;
        ena_i             : in std_logic;
        rst_i             : in std_logic;
        clk_i             : in std_logic
    );
end decode;

architecture arch of decode is
    component scoreboard is
        generic (
            n_bits : natural := 5
        );
            port (
            clk               : in  std_logic;
            rst               : in  std_logic;
            addr_a_i          : in  std_logic_vector(4 downto 0);
            addr_b_i          : in  std_logic_vector(4 downto 0);
            addr_d_i          : in  std_logic_vector(4 downto 0);
            addr_free_d_mem_i : in std_logic_vector(4 downto 0);
            we_a_i            : in  std_logic;
            we_b_i            : in  std_logic;
            we_d_i            : in  std_logic;
            we_d_mem_i        : in  std_logic;
            free_d_mem_i      : in std_logic;
            data_a_i          : in  std_logic_vector(4 downto 0);
            data_b_i          : in  std_logic_vector(4 downto 0);
            data_d_i          : in  std_logic_vector(4 downto 0);
            data_d_mem_i      : in std_logic;
            we_mul_i          : in  std_logic;
            rst_mul_i         : in  std_logic;
            we_div_i          : in  std_logic;
            rst_div_i         : in  std_logic;
            hazard            : out std_logic  --stall
        );
    end component;

    type decode_reg_type is record
        instruction          : std_logic_vector(CFG_IMEM_WIDTH - 1 downto 0);
        program_counter      : std_logic_vector(CFG_IMEM_SIZE - 1 downto 0);
        pc_plus_four         : std_logic_vector(CFG_IMEM_SIZE - 1 downto 0);
        msr_interrupt_enable : std_logic;
        interrupt            : std_logic;
        delay_interrupt      : std_logic;
        alu_op               : alu_operation;
        reg_d                : std_logic_vector(4 downto 0);
        mem_read             : std_logic;
    end record;

	type riscv_instr_type is (R_TYPE, B_TYPE, I_TYPE, S_TYPE, U_TYPE, J_TYPE, INVALID);
    type riscv_instr is record
        inst_type : riscv_instr_type;
        funct7    : std_logic_vector(6 downto 0);
        funct3    : std_logic_vector(2 downto 0);
        opcode    : std_logic_vector(6 downto 0);
    end record;

    signal r, rin     : decode_out_type;
    signal reg, regin : decode_reg_type;

    -- WB signals to RF
    signal wb_dat_d_mem, wb_dat_d_ex : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);

    -- Scoreboard
    signal s_addr_a_i, s_addr_b_i, s_addr_d_i, s_addr_free_d_mem_i : std_logic_vector(4 downto 0) := (others => '0');
    signal s_data_a_i, s_data_b_i, s_data_d_i : std_logic_vector(4 downto 0);
    signal s_we_a_i, s_we_b_i, s_we_d_i, s_we_d_mem_i, s_free_d_mem_i : std_logic := '0';
    signal s_data_d_mem_i : std_logic := '0';
    signal s_we_mul_i     : std_logic;
    signal s_rst_mul_i    : std_logic;
    signal s_we_div_i     : std_logic;
    signal s_rst_div_i    : std_logic;
    signal sb_hazard      : std_logic;

begin
    sb : scoreboard
    generic map (
        n_bits => 32
    )
    port map (
        clk => clk_i,
        rst => rst_i,
        addr_a_i => s_addr_a_i,
        addr_b_i => s_addr_b_i,
        addr_d_i => s_addr_d_i,

        addr_free_d_mem_i => s_addr_free_d_mem_i,

        we_a_i => s_we_a_i,
        we_b_i => s_we_b_i,
        we_d_i => s_we_d_i,

        we_d_mem_i => s_we_d_mem_i,

        free_d_mem_i => s_free_d_mem_i,

        data_a_i => s_data_a_i,
        data_b_i => s_data_b_i,
        data_d_i => s_data_d_i,
        data_d_mem_i => s_data_d_mem_i,

        we_mul_i => s_we_mul_i,
        rst_mul_i => s_rst_mul_i,

        we_div_i => s_we_div_i,
        rst_div_i => s_rst_div_i,

        hazard => sb_hazard
    );

    stall <= rin.hazard;

    decode_o.imm <= r.imm;

    decode_o.ctrl_ex <= r.ctrl_ex;
    decode_o.ctrl_mem <= r.ctrl_mem;
    decode_o.ctrl_wrb <= r.ctrl_wrb;

    decode_o.reg_a <= r.reg_a;
    decode_o.reg_b <= r.reg_b;
    decode_o.hazard <= r.hazard;
    decode_o.program_counter <= r.program_counter;
    decode_o.pc_plus_four <= r.pc_plus_four;

    decode_o.fwd_dec_mem_result <= r.fwd_dec_mem_result;
    decode_o.fwd_dec_ex_result <= r.fwd_dec_ex_result;

    decode_o.fwd_dec_mem <= r.fwd_dec_mem;
    decode_o.fwd_dec_ex <= r.fwd_dec_ex;

    decode_o.end_execution <= r.end_execution;

    s_addr_free_d_mem_i <= addr_free_d_mem_i;
    s_free_d_mem_i <= free_d_mem_i;

    decode_comb: process(decode_i,decode_i.ctrl_wrb_mem,decode_i.ctrl_wrb_ex,
                         decode_i.ctrl_mem_wrb,
                         decode_i.instruction,
                         decode_i.ctrl_mem_wrb.transfer_size,
                         r,r.ctrl_ex,r.ctrl_mem,
                         r.ctrl_mem.transfer_size,r.ctrl_wrb,
                         r.ctrl_wrb.reg_d,
                         r.fwd_dec_mem,r.fwd_dec_ex,reg,sb_hazard,stall_mem,addr_free_d_mem_i,free_d_mem_i,s_data_d_mem_i,s_we_d_mem_i)

        variable v               : decode_out_type;
        variable v_reg           : decode_reg_type;
        variable riscv           : riscv_instr;
        variable instruction     : std_logic_vector(CFG_IMEM_WIDTH - 1 downto 0);
        variable program_counter : std_logic_vector(CFG_IMEM_SIZE - 1 downto 0);
        variable pc_plus_four    : std_logic_vector(CFG_IMEM_SIZE - 1 downto 0);
        variable mem_result      : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);

    begin
        v := r;
        v_reg := reg;

        -- Default register values
        v_reg.program_counter := decode_i.program_counter;
        v_reg.pc_plus_four    := decode_i.pc_plus_four;
        v_reg.instruction     := decode_i.instruction;

        -- Memory result
        mem_result := align_mem_load_neo(decode_i.mem_result, decode_i.ctrl_mem_wrb.transfer_size, decode_i.alu_result_mem(1 downto 0), decode_i.ctrl_mem_wrb.sign_extended);

        -- WB data from MEM or EX to be written on the RF
        wb_dat_d_mem <= mem_result;
        wb_dat_d_ex <= decode_i.alu_result_ex;

        if G_INTERRUPT = true then
            v_reg.delay_interrupt := '0';
        end if;

        -- Forwarding paths
        if CFG_REG_FWD_WRB = true then
            if decode_i.ctrl_mem_wrb.mem_read = '1' then
                v.fwd_dec_mem_result    := mem_result;
                v.fwd_dec_mem           := decode_i.ctrl_wrb_mem;
            else
                v.fwd_dec_mem_result := (others => '0');
                v.fwd_dec_mem.reg_d      := (others => '0');
                v.fwd_dec_mem.reg_write  := '0';
            end if;
            if decode_i.ctrl_wrb_ex.reg_write = '1' then
                v.fwd_dec_ex_result    := decode_i.alu_result_ex;
                v.fwd_dec_ex           := decode_i.ctrl_wrb_ex;
            else
                v.fwd_dec_ex_result    := (others => '0');
                v.fwd_dec_ex.reg_d     := (others => '0');
                v.fwd_dec_ex.reg_write := '0';
            end if;
        else
            v.fwd_dec_mem_result    := (others => '0');
            v.fwd_dec_mem.reg_d     := (others => '0');
            v.fwd_dec_mem.reg_write := '0';
            v.fwd_dec_ex_result     := (others => '0');
            v.fwd_dec_ex.reg_d      := (others => '0');
            v.fwd_dec_ex.reg_write  := '0';
        end if;

        -- Instruction, PC and PC + 4 received from IF
        instruction     := decode_i.instruction;
        program_counter := decode_i.program_counter;
        pc_plus_four    := decode_i.pc_plus_four;

        -- Scoreboard signals
        s_addr_a_i     <= instruction(19 downto 15);
        s_addr_b_i     <= instruction(24 downto 20);
        s_addr_d_i     <= instruction(11 downto 7);
        s_we_a_i       <= '0';
        s_we_b_i       <= '0';
        s_we_d_i       <= '0';
        s_we_d_mem_i   <= '0';
        s_data_a_i     <= (others => '0');
        s_data_b_i     <= (others => '0');
        s_data_d_i     <= (others => '0');
        s_data_d_mem_i <= '0';
        s_we_mul_i     <= '0';
        s_rst_mul_i    <= '0';
        s_we_div_i     <= '0';
        s_rst_div_i    <= '0';

        -- Check data hazards
        if sb_hazard = '1' or stall_mem = '1' then
            v.hazard := '1';
        elsif (not decode_i.flush_id and r.ctrl_mem.mem_read and (compare(decode_i.instruction(19 downto 15), r.ctrl_wrb.reg_d) or compare(decode_i.instruction(24 downto 20), r.ctrl_wrb.reg_d))) = '1' then
            v.hazard := '1';
        elsif CFG_MEM_FWD_WRB = false and (not decode_i.flush_id and r.ctrl_mem.mem_read and compare(decode_i.instruction(24 downto 20), r.ctrl_wrb.reg_d)) = '1' then
            v.hazard := '1';
        else
            v.hazard := '0';
        end if;

        -- Send a NOP or send the right instruction
        if v.hazard = '1' then
            v.program_counter := (others => '0');
            v.pc_plus_four := (others => '0');
            v.imm := (others => '0');
            v.ctrl_wrb.reg_d := (others => '0');
            v.reg_a := (others => '0');
            v.reg_b := (others => '0');
            riscv.opcode := (others => '0');
            riscv.funct3 := (others => '0');
            riscv.funct7 := (others => '0');
        else
            -- PC and PC + 4
            v.program_counter := program_counter;
            v.pc_plus_four := pc_plus_four;

            -- Decode Registers
            v.ctrl_wrb.reg_d := instruction(11 downto 7);
            v.reg_a := instruction(19 downto 15);
            v.reg_b := instruction(24 downto 20);

            -- RISC-V DECODE
            riscv.opcode := instruction(6 downto 0);
            riscv.funct3 := instruction(14 downto 12);
            riscv.funct7 := instruction(31 downto 25);

            -- INSTR_TYPE
            case riscv.opcode is
                when "0110011" => riscv.inst_type := R_TYPE;
                when "1100011" => riscv.inst_type := B_TYPE;
                when "0100011" => riscv.inst_type := S_TYPE;
                when "1101111" => riscv.inst_type := J_TYPE;
                when "0000011" => riscv.inst_type := I_TYPE;
                when "1100111" => riscv.inst_type := I_TYPE;
                when "0010111" => riscv.inst_type := U_TYPE;
                when "0110111" => riscv.inst_type := U_TYPE;
                when others    => riscv.inst_type := INVALID;
            end case;

            -- Detect R or I types
            if compare(riscv.opcode, "0010011") = '1' then
                case riscv.funct3(1 downto 0) is
                    when "01"   => riscv.inst_type := R_TYPE;
                    when others => riscv.inst_type := I_TYPE;
                end case;
            end if;

            -- IMM value
            if riscv.inst_type = R_TYPE then
                v.imm(0)            := instruction(20);
                v.imm(4 downto 1)   := instruction(24 downto 21);
                v.imm(10 downto 5)  := instruction(30 downto 25);
                v.imm(11)           := instruction(31);
                v.imm(19 downto 12) := instruction(19 downto 12);
                v.imm(30 downto 20) := (others => instruction(31));
                v.imm(31)           := instruction(31);
            elsif riscv.inst_type = B_TYPE then
                v.imm(0)            := '0';
                v.imm(4 downto 1)   := instruction(11 downto 8);
                v.imm(10 downto 5)  := instruction(30 downto 25);
                v.imm(11)           := instruction(7);
                v.imm(19 downto 12) := (others => instruction(31));
                v.imm(30 downto 20) := (others => instruction(31));
                v.imm(31)           := instruction(31);
            elsif riscv.inst_type = S_TYPE then
                v.imm(0)            := instruction(7);
                v.imm(4 downto 1)   := instruction(11 downto 8);
                v.imm(10 downto 5)  := instruction(30 downto 25);
                v.imm(11)           := instruction(31);
                v.imm(19 downto 12) := (others => instruction(31));
                v.imm(30 downto 20) := (others => instruction(31));
                v.imm(31)           := instruction(31);
            elsif riscv.inst_type = J_TYPE then
                v.imm(0)            := '0';
                v.imm(4 downto 1)   := instruction(24 downto 21);
                v.imm(10 downto 5)  := instruction(30 downto 25);
                v.imm(11)           := instruction(20);
                v.imm(19 downto 12) := instruction(19 downto 12);
                v.imm(30 downto 20) := (others => instruction(31));
                v.imm(31)           := instruction(31);
            elsif riscv.inst_type = I_TYPE then
                v.imm(0)            := instruction(20);
                v.imm(4 downto 1)   := instruction(24 downto 21);
                v.imm(10 downto 5)  := instruction(30 downto 25);
                v.imm(11)           := instruction(31);
                v.imm(19 downto 12) := (others => instruction(31));
                v.imm(30 downto 20) := (others => instruction(31));
                v.imm(31)           := instruction(31);
            elsif riscv.inst_type = U_TYPE then
                v.imm(0)            := '0';
                v.imm(4 downto 1)   := (others => '0');
                v.imm(10 downto 5)  := (others => '0');
                v.imm(11)           := '0';
                v.imm(19 downto 12) := instruction(19 downto 12);
                v.imm(30 downto 20) := instruction(30 downto 20);
                v.imm(31)           := instruction(31);
            else
                v.imm(31 downto 0)  := (others => '0');
            end if;

        end if;

        -- Register if an interrupt occurs
        if G_INTERRUPT = true then
            if v_reg.msr_interrupt_enable = '1' and decode_i.interrupt = '1' then
                v_reg.interrupt := '1';
                v_reg.msr_interrupt_enable := '0';
            end if;
        end if;

        -- Default EX and MEM control signals
        v.ctrl_ex.alu_op         := ALU_ADD;
        v.ctrl_ex.alu_src_a      := ALU_SRC_REGA;
        v.ctrl_ex.alu_src_b      := ALU_SRC_REGB;
        v.ctrl_ex.operation      := "00";
        v.ctrl_ex.carry          := CARRY_ZERO;
        v.ctrl_ex.branch_cond    := NOP;
        v.ctrl_mem.mem_write     := '0';
        v.ctrl_mem.mem_read      := '0';
        v.ctrl_mem.transfer_size := WORD;
        v.ctrl_mem.sign_extended := '0';
        v.ctrl_wrb.reg_write     := '0';

        if G_INTERRUPT = true and (v_reg.interrupt = '1' and reg.delay_interrupt = '0' and decode_i.flush_id = '0' and v.hazard = '0') then
        -- IF an interrupt occured
        --    AND the current instruction is not a branch or return instruction,
        --    AND the current instruction is not in a delay slot,
        --    AND this is instruction is not preceded by an IMM instruction, than handle the interrupt.
            v_reg.msr_interrupt_enable := '0';
            v_reg.interrupt := '0';

            v.reg_a := (others => '0');
            v.reg_b := (others => '0');

            v.imm   := X"00000010";
            v.ctrl_wrb.reg_d := "01110";

            v.ctrl_ex.branch_cond := BNC;
            v.ctrl_ex.alu_src_a := ALU_SRC_ZERO;
            v.ctrl_ex.alu_src_b := ALU_SRC_IMM;
            v.ctrl_wrb.reg_write := '1';

        elsif (decode_i.flush_id or v.hazard) = '1' then
            -- clearing these registers is not necessary, but facilitates debugging.
            -- On the other hand performance improves when disabled.
            --if G_DEBUG = true then
            --    v.program_counter := (others => '0');
            --    v.ctrl_wrb.reg_d  := (others => '0');
            --    v.reg_a           := (others => '0');
            --    v.reg_b           := (others => '0');
            --    v.imm             := (others => '0');
            --end if;

            if decode_i.flush_id = '1' then
                if reg.alu_op = ALU_MUL then
                    s_we_d_i <= '1';
                    s_data_d_i <= (others => '0');
                    s_addr_d_i <= reg.reg_d;
                    s_rst_mul_i <= '1';
                end if;
                if reg.alu_op = ALU_DIV then
                    s_we_d_i <= '1';
                    s_data_d_i <= (others => '0');
                    s_addr_d_i <= reg.reg_d;
                    s_rst_div_i <= '1';
                end if;
                if (reg.alu_op = ALU_ADD and reg.mem_read = '1') then
                    s_data_d_mem_i <= '0';
                    s_we_d_mem_i <= '1';
                    s_addr_d_i <= reg.reg_d;
                end if;
            end if;

-----------------
-------SUB-------
----SLT-SLTIU----
----SLTI-SLTU----
-----------------
        elsif (compare(riscv.opcode, "0110011")='1' and is_zero(riscv.funct3)='1' and compare(riscv.funct7, "0100000")='1') or ((compare(riscv.opcode, "0010011")='1' or compare(riscv.opcode, "0110011")='1') and (riscv.funct3(1) and not riscv.funct3(2))='1') then

            -- ALU operation
            v.ctrl_ex.alu_op := ALU_ADD;

            -- Source operand A
            v.ctrl_ex.alu_src_a := ALU_SRC_REGA;

            -- Source operand B
            if riscv.opcode(5) = '0' then
                v.ctrl_ex.alu_src_b := ALU_SRC_NOT_IMM;
            else
                v.ctrl_ex.alu_src_b := ALU_SRC_NOT_REGB;
            end if;

            -- Carry
            v.ctrl_ex.carry := CARRY_ONE;

            -- Writeback
            v.ctrl_wrb.reg_write := is_not_zero(v.ctrl_wrb.reg_d);

            -- Comparisons
            v.ctrl_ex.operation := riscv.funct3(1 downto 0);

-----------------
----LUI-AUIPC----
-----------------
        elsif compare(riscv.opcode, "0110111") = '1' or compare(riscv.opcode, "0010111") = '1' then

            -- ALU operation
            v.ctrl_ex.alu_op := ALU_ADD;

            -- Source operand A
            if riscv.opcode(5) = '0' then
                v.ctrl_ex.alu_src_a := ALU_SRC_PC;
            else
                v.ctrl_ex.alu_src_a := ALU_SRC_ZERO;
            end if;

            -- Source operand B
            v.ctrl_ex.alu_src_b := ALU_SRC_IMM;

            -- Writeback
            v.ctrl_wrb.reg_write := is_not_zero(v.ctrl_wrb.reg_d);

-----------------
---AND-OR-XOR----
--ANDI-ORI-XORI--
----ADDI--ADD----
----SLL--SLLI----
----SRLI-SRAI----
-----SRL-SRA-----
-----------------
        elsif ((compare(riscv.opcode, "0110011")='1' and is_zero(riscv.funct7(4 downto 0))='1') or compare(riscv.opcode, "0010011")='1') then
            -- COND opcode: 0010011 or 0110011
            --      funct7: 0000000 or 0100000

            -- ALU operation
            case riscv.funct3 is
                when "000" => v.ctrl_ex.alu_op := ALU_ADD;
                when "001" => v.ctrl_ex.alu_op := ALU_BS;
--              when "010" => v.ctrl_ex.alu_op := ALU_COMP_LT;
--              when "011" => v.ctrl_ex.alu_op := ALU_COMP_LTU;
                when "100" => v.ctrl_ex.alu_op := ALU_XOR;
                when "101" => v.ctrl_ex.alu_op := ALU_BS;
                when "110" => v.ctrl_ex.alu_op := ALU_OR;
                when others => v.ctrl_ex.alu_op := ALU_AND;
            end case;

            -- Source operand A
            v.ctrl_ex.alu_src_a := ALU_SRC_REGA;

            -- Source operand B
            if riscv.opcode(5) = '0' then
                v.ctrl_ex.alu_src_b := ALU_SRC_IMM;
            else
                v.ctrl_ex.alu_src_b := ALU_SRC_REGB;
            end if;

            -- Writeback
            v.ctrl_wrb.reg_write := is_not_zero(v.ctrl_wrb.reg_d);

-----------------
-----JAL-JALR----
-----------------
        elsif compare(riscv.opcode, "1101111")='1' or (compare(riscv.opcode, "1100111")='1' and is_zero(riscv.funct3)='1') then

            v.ctrl_ex.branch_cond := BNC;

            -- ALU operation
            v.ctrl_ex.alu_op := ALU_ADD;

            -- ALU operand A
            if riscv.opcode(3) = '1' then
                v.ctrl_ex.alu_src_a := ALU_SRC_PC;
            else
                v.ctrl_ex.alu_src_a := ALU_SRC_REGA;
            end if;

            -- ALU operand B
            v.ctrl_ex.alu_src_b := ALU_SRC_IMM;

            -- Writeback
            v.ctrl_wrb.reg_write := is_not_zero(v.ctrl_wrb.reg_d);

            if G_INTERRUPT = true then
                v_reg.delay_interrupt := '1';
            end if;

            -- Check end of program
            if riscv.opcode(3) = '0' and v.imm = X"00000000" and v.ctrl_wrb.reg_d = "00000" and v.reg_a = "00000" then
                v.end_execution := '1';
            end if;

-----------------
---BEQ-BNE-BLT---
--BGE-BLTU-BGEU--
-----------------
        elsif compare(riscv.opcode, "1100011")='1' and (not riscv.funct3(1) or riscv.funct3(2)) = '1' then
            -- COND: opcode = "1100011"
            --       funct3 = 000 or 001 or 100 or 101 or 110 or 111

            -- ALU operation
            v.ctrl_ex.alu_op := ALU_ADD;

            -- Source operand A
            v.ctrl_ex.alu_src_a := ALU_SRC_REGA;

            -- Source operand B
            v.ctrl_ex.alu_src_b := ALU_SRC_NOT_REGB;

            -- Carry
            v.ctrl_ex.carry := CARRY_ONE;

            case riscv.funct3 is
                when "000"  => v.ctrl_ex.branch_cond := BEQ;
                when "001"  => v.ctrl_ex.branch_cond := BNE;
                when "100"  => v.ctrl_ex.branch_cond := BLT;
                when "101"  => v.ctrl_ex.branch_cond := BGE;
                when "110"  => v.ctrl_ex.branch_cond := BLTU;
                when others => v.ctrl_ex.branch_cond := BGEU;
            end case;

            if G_INTERRUPT = true then
                v_reg.delay_interrupt := '1';
            end if;

-----------------
------LW-SW------
---LB-SB-LH-SH---
-----LBU-LHU-----
-----------------
        elsif (compare(riscv.opcode, "0100011")='1' and (not riscv.funct3(2) and (not riscv.funct3(1) or not riscv.funct3(0)))='1') or (compare(riscv.opcode, "0000011")='1' and (not riscv.funct3(1) or (not riscv.funct3(2) and not riscv.funct3(0)))='1') then
            -- COND opcode = 0100011
            --      funct3 = 000 or 001 or 010
            --      opcode = 0000011
            --      funct3 = 000 or 001 or 010 or 100 or 101

            -- ALU operation
            v.ctrl_ex.alu_op := ALU_ADD;

            -- Source operand A
            v.ctrl_ex.alu_src_a := ALU_SRC_REGA;

            -- Source operand B
            v.ctrl_ex.alu_src_b := ALU_SRC_IMM;

            if riscv.opcode(5) = '1' then
                -- Store
                v.ctrl_mem.mem_write := '1';
                v.ctrl_mem.mem_read  := '0';
                v.ctrl_wrb.reg_write := '0';
            else
                -- Load
                v.ctrl_mem.mem_write     := '0';
                v.ctrl_mem.mem_read      := '1';
                v.ctrl_mem.sign_extended := not riscv.funct3(2);
                v.ctrl_wrb.reg_write     := is_not_zero(v.ctrl_wrb.reg_d);
            end if;

            case riscv.funct3(1 downto 0) is
                when "00" => v.ctrl_mem.transfer_size := BYTE;
                when "01" => v.ctrl_mem.transfer_size := HALFWORD;
                when others => v.ctrl_mem.transfer_size := WORD;
            end case;

            if sb_hazard = '0' and stall_mem = '0' then
                if riscv.opcode(5) = '0' then --load
                    s_we_d_mem_i <= '1';
                    s_data_d_mem_i <= '1';
                end if;
            end if;

-----------------
----MUL-MULHU----
---MULH-MULHSU---
-----------------
        elsif G_USE_HW_MUL = true and (compare(riscv.opcode, "0110011")='1' and compare(riscv.funct7, "0000001")='1' and riscv.funct3(2) = '0') then
            -- ALU operation
            v.ctrl_ex.alu_op := ALU_MUL;

            -- Source operand A
            v.ctrl_ex.alu_src_a := ALU_SRC_REGA;

            -- Source operand B
            v.ctrl_ex.alu_src_b := ALU_SRC_REGB;

            -- Writeback
            v.ctrl_wrb.reg_write := is_not_zero(v.ctrl_wrb.reg_d);

            if sb_hazard = '0' and stall_mem = '0' then
                s_we_d_i <= '1';
                s_data_d_i <= "00111"; -- latency + 1
                s_we_mul_i <= '1';
            end if;

-----------------
----DIV--DIVU----
----REM--REMU----
-----------------
        elsif G_USE_HW_DIV = true and (compare(riscv.opcode, "0110011")='1' and compare(riscv.funct7, "0000001")='1' and riscv.funct3(2) = '1') then
            -- ALU operation
            v.ctrl_ex.alu_op := ALU_DIV;

            -- Source operand A
            v.ctrl_ex.alu_src_a := ALU_SRC_REGA;

            -- Source operand B
            v.ctrl_ex.alu_src_b := ALU_SRC_REGB;

            -- Writeback
            v.ctrl_wrb.reg_write := is_not_zero(v.ctrl_wrb.reg_d);

            if sb_hazard = '0' and stall_mem = '0' then
                s_we_d_i <= '1';
                s_data_d_i <= "11111"; -- latency + 1
                s_we_div_i <= '1';
            end if;

-----------------
-----------------
-----------------
        elsif is_zero(riscv.opcode) = '1' then
            -- NOP
            null;
        else
            -- UNKNOWN OPCODE
            null;
        end if;

        if sb_hazard = '1' or stall_mem = '1' then
            v.ctrl_ex.alu_op := ALU_ADD;
            v.ctrl_ex.alu_src_a := ALU_SRC_REGA;
            v.ctrl_ex.alu_src_b := ALU_SRC_REGB;
            v.ctrl_ex.operation := "00";
            v.ctrl_ex.carry := CARRY_ZERO;
            v.ctrl_ex.branch_cond := NOP;

            v.ctrl_mem.mem_write := '0';
            v.ctrl_mem.mem_read := '0';
            v.ctrl_mem.transfer_size := WORD;
            v.ctrl_mem.sign_extended := '0';

            v.ctrl_wrb.reg_d := "00000";
            v.ctrl_wrb.reg_write := '0';
        end if;

        rin <= v;
        v_reg.alu_op := v.ctrl_ex.alu_op;
        v_reg.reg_d := v.ctrl_wrb.reg_d;
        v_reg.mem_read := v.ctrl_mem.mem_read;
        regin <= v_reg;

    end process;

    decode_seq : process(clk_i)
    procedure proc_reset_decode is
    begin
        r.reg_a                  <= (others => '0');
        r.reg_b                  <= (others => '0');
        r.imm                    <= (others => '0');
        r.program_counter        <= (others => '0');
        r.pc_plus_four           <= (others => '0');
        r.hazard                 <= '0';
        r.ctrl_ex.alu_op         <= ALU_ADD;
        r.ctrl_ex.alu_src_a      <= ALU_SRC_REGA;
        r.ctrl_ex.alu_src_b      <= ALU_SRC_REGB;
        r.ctrl_ex.carry          <= CARRY_ZERO;
        r.ctrl_ex.operation      <= "00";
        r.ctrl_ex.branch_cond    <= NOP;
        r.ctrl_mem.mem_write     <= '0';
        r.ctrl_mem.transfer_size <= WORD;
        r.ctrl_mem.mem_read      <= '0';
        r.ctrl_mem.sign_extended <= '0';
        r.ctrl_wrb.reg_d         <= (others => '0');
        r.ctrl_wrb.reg_write     <= '0';
        r.fwd_dec_mem_result     <= (others => '0');
        r.fwd_dec_mem.reg_d      <= (others => '0');
        r.fwd_dec_mem.reg_write  <= '0';
        r.fwd_dec_ex_result      <= (others => '0');
        r.fwd_dec_ex.reg_d       <= (others => '0');
        r.fwd_dec_ex.reg_write   <= '0';
        r.end_execution          <= '0';
        reg.instruction          <= (others => '0');
        reg.program_counter      <= (others => '0');
        reg.pc_plus_four         <= (others => '0');
        reg.msr_interrupt_enable <= '1';
        reg.interrupt            <= '0';
        reg.delay_interrupt      <= '0';
        reg.alu_op               <= ALU_ADD;
        reg.reg_d                <= (others => '0');
        reg.mem_read             <= '0';
    end procedure proc_reset_decode;

    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                proc_reset_decode;
            elsif ena_i = '1' then
                r <= rin;
                reg <= regin;
            end if;
        end if;
    end process;

    gprf0 : gprf
    port map(
        gprf_o             => gprf_o,
        gprf_i.adr_a_i     => rin.reg_a,
        gprf_i.adr_b_i     => rin.reg_b,
        gprf_i.dat_w_mem_i => wb_dat_d_mem,
        gprf_i.adr_w_mem_i => decode_i.ctrl_wrb_mem.reg_d,
        gprf_i.wre_mem_i   => decode_i.ctrl_wrb_mem.reg_write,
        gprf_i.dat_w_ex_i  => wb_dat_d_ex,
        gprf_i.adr_w_ex_i  => decode_i.ctrl_wrb_ex.reg_d,
        gprf_i.wre_ex_i    => decode_i.ctrl_wrb_ex.reg_write,
        ena_i              => ena_i,
        clk_i              => clk_i
    );

end arch;
