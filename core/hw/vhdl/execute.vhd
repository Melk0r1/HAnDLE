----------------------------------------------------------------------------------------------
--
--      Input file         : execute.vhd
--      Design name        : execute
--      Author             : Tamar Kranenburg
--      Modified by        : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--
--      Description        : The Execution Unit performs all arithmetic operations and makes
--                           the branch decision. Furthermore the forwarding logic is located
--                           here.
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.config_Pkg.all;
use work.core_Pkg.all;
use work.std_Pkg.all;

entity execute is
    generic (
        G_USE_HW_MUL : boolean := CFG_USE_HW_MUL;
        G_USE_HW_DIV : boolean := CFG_USE_HW_DIV;
        G_USE_BARREL : boolean := CFG_USE_BARREL
    );
    port (
    exec_o : out execute_out_type;
    exec_i : in execute_in_type;
    ena_i  : in std_logic;
    rst_i  : in std_logic;
    clk_i  : in std_logic
);
end execute;

architecture arch of execute is
    component multiplier_unit is
        port (
            dat_d_i         : in std_logic_vector(31 downto 0);
            alu_src_a_i     : in std_logic_vector(31 downto 0);
            alu_src_b_i     : in std_logic_vector(31 downto 0);
            ctrl_wrb_i      : in forward_type;
            ctrl_mem_i      : in ctrl_memory;
            rst_i           : in std_logic;
            clk_i           : in std_logic;
            ena_i           : in std_logic;
            low_high        : in std_logic;
            a_sign          : in std_logic;
            b_sign          : in std_logic;
            valid_inst_i    : in std_logic;

            result_o        : out std_logic_vector(31 downto 0);
            dat_d_o         : out std_logic_vector(31 downto 0);
            branch_o        : out std_logic;
            branch_target_o : out std_logic_vector(31 downto 0);
            flush_id_o      : out std_logic;
            ctrl_wrb_o      : out forward_type;
            ctrl_mem_o      : out ctrl_memory;
            valid_inst_o    : out std_logic
        );
    end component;

    component divider_unit_0 is
        port (
            dat_d_i         : in std_logic_vector(31 downto 0);
            alu_src_a_i     : in std_logic_vector(31 downto 0);
            alu_src_b_i     : in std_logic_vector(31 downto 0);
            ctrl_wrb_i      : in forward_type;
            ctrl_mem_i      : in ctrl_memory;
            rst_i           : in std_logic;
            clk_i           : in std_logic;
            ena_i           : in std_logic;
            ena_div_i       : in std_logic;
            div_rem         : in std_logic;
            a_sign          : in std_logic;
            b_sign          : in std_logic;
            valid_inst_i    : in std_logic;

            result_o        : out std_logic_vector(31 downto 0);
            dat_d_o         : out std_logic_vector(31 downto 0);
            branch_o        : out std_logic;
            branch_target_o : out std_logic_vector(31 downto 0);
            flush_id_o      : out std_logic;
            ctrl_wrb_o      : out forward_type;
            ctrl_mem_o      : out ctrl_memory;
            valid_inst_o    : out std_logic
        );
    end component;

    type execute_reg_type is record
        flush_ex : std_logic;
    end record;

    signal r, rin     : execute_out_type;
    signal reg, regin : execute_reg_type;

    signal r_ctrl_wrb, rin_ctrl_wrb : forward_type;

    -- Multiplier Unit Signals
    signal mul_dat_d_i     : std_logic_vector(31 downto 0) := (others => '0');
    signal mul_alu_src_a_i : std_logic_vector(31 downto 0) := (others => '0');
    signal mul_alu_src_b_i : std_logic_vector(31 downto 0) := (others => '0');
    signal mul_ctrl_wrb_i  : forward_type;
    signal mul_ctrl_mem_i  : ctrl_memory;
    signal mul_result_o        : std_logic_vector(31 downto 0);
    signal mul_dat_d_o         : std_logic_vector(31 downto 0) := (others => '0');
    signal mul_branch_o        : std_logic;
    signal mul_branch_target_o : std_logic_vector(31 downto 0);
    signal mul_flush_id_o      : std_logic;
    signal mul_ctrl_wrb_o      : forward_type;
    signal mul_ctrl_mem_o      : ctrl_memory;
    signal mul_low_high, mul_a_sign, mul_b_sign : std_logic;
    signal mul_valid_inst_i, mul_valid_inst_o : std_logic;

    -- Divider Unit Signals
    signal div_dat_d_i     : std_logic_vector(31 downto 0) := (others => '0');
    signal div_alu_src_a_i : std_logic_vector(31 downto 0) := (others => '0');
    signal div_alu_src_b_i : std_logic_vector(31 downto 0) := (others => '0');
    signal div_ctrl_wrb_i  : forward_type;
    signal div_ctrl_mem_i  : ctrl_memory;
    signal div_ena_div_i       : std_logic;
    signal div_result_o        : std_logic_vector(31 downto 0);
    signal div_dat_d_o         : std_logic_vector(31 downto 0) := (others => '0');
    signal div_branch_o        : std_logic;
    signal div_branch_target_o : std_logic_vector(31 downto 0);
    signal div_flush_id_o      : std_logic;
    signal div_ctrl_wrb_o      : forward_type;
    signal div_ctrl_mem_o      : ctrl_memory;
    signal div_div_rem, div_a_sign, div_b_sign : std_logic;
    signal div_valid_inst_i, div_valid_inst_o : std_logic;

begin
    mul :  multiplier_unit
    port map (
        dat_d_i         => mul_dat_d_i,
        alu_src_a_i     => mul_alu_src_a_i,
        alu_src_b_i     => mul_alu_src_b_i,
        ctrl_wrb_i      => mul_ctrl_wrb_i,
        ctrl_mem_i      => mul_ctrl_mem_i,
        rst_i           => rst_i,
        clk_i           => clk_i,
        ena_i           => ena_i,
        low_high        => mul_low_high,
        a_sign          => mul_a_sign,
        b_sign          => mul_b_sign,
        valid_inst_i    => mul_valid_inst_i,

        result_o        => mul_result_o,
        dat_d_o         => mul_dat_d_o,
        branch_o        => mul_branch_o,
        branch_target_o => mul_branch_target_o,
        flush_id_o      => mul_flush_id_o,
        ctrl_wrb_o      => mul_ctrl_wrb_o,
        ctrl_mem_o      => mul_ctrl_mem_o,
        valid_inst_o    => mul_valid_inst_o
    );

    div :  divider_unit_0
    port map (
        dat_d_i         => div_dat_d_i,
        alu_src_a_i     => div_alu_src_a_i,
        alu_src_b_i     => div_alu_src_b_i,
        ctrl_wrb_i      => div_ctrl_wrb_i,
        ctrl_mem_i      => div_ctrl_mem_i,
        rst_i           => rst_i,
        clk_i           => clk_i,
        ena_i           => ena_i,
        ena_div_i       => div_ena_div_i,
        div_rem         => div_div_rem,
        a_sign          => div_a_sign,
        b_sign          => div_b_sign,
        valid_inst_i    => div_valid_inst_i,

        result_o        => div_result_o,
        dat_d_o         => div_dat_d_o,
        branch_o        => div_branch_o,
        branch_target_o => div_branch_target_o,
        flush_id_o      => div_flush_id_o,
        ctrl_wrb_o      => div_ctrl_wrb_o,
        ctrl_mem_o      => div_ctrl_mem_o,
        valid_inst_o    => div_valid_inst_o
    );

    exec_o <= r;

    mul_ctrl_wrb_i <= exec_i.ctrl_wrb;
    mul_ctrl_mem_i <= exec_i.ctrl_mem;

    div_ctrl_wrb_i <= exec_i.ctrl_wrb;
    div_ctrl_mem_i <= exec_i.ctrl_mem;

    execute_comb: process(exec_i,exec_i.fwd_mem,exec_i.ctrl_ex,
            exec_i.ctrl_wrb,exec_i.ctrl_mem,
            exec_i.ctrl_mem.transfer_size,
            exec_i.ctrl_mem_wrb,exec_i.fwd_dec_mem,exec_i.fwd_dec_ex,r_ctrl_wrb,
            r,r.ctrl_mem,r.ctrl_mem.transfer_size,
            r.ctrl_wrb_mem,r.ctrl_wrb_ex,reg,mul_valid_inst_o,mul_result_o,div_valid_inst_o,div_result_o,
            mul_dat_d_o,mul_branch_o,mul_branch_target_o,mul_flush_id_o,mul_ctrl_wrb_o,
            mul_ctrl_mem_o,div_dat_d_o,div_branch_o,div_branch_target_o,div_flush_id_o,
            div_ctrl_wrb_o,div_ctrl_mem_o)

        variable v : execute_out_type;
        variable v_reg : execute_reg_type;

        variable v_ctrl_wrb : forward_type;

        variable alu_src_a : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
        variable alu_src_b : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
        variable carry : std_logic;

        variable result : std_logic_vector(CFG_DMEM_WIDTH downto 0);
        variable pc_plus_imm : std_logic_vector(CFG_IMEM_SIZE downto 0);

        variable dat_a, dat_b : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
        variable sel_dat_a, sel_dat_b, sel_dat_a_mem, sel_dat_a_ex, sel_dat_b_mem, sel_dat_b_ex : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
        variable mem_result : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);

        variable cmp_aLTUb, cmp_aLTSb, cmp_zero : std_logic;

    begin
        v := r;

        v_ctrl_wrb := r_ctrl_wrb;

        -- Forwaring paths
        sel_dat_a_mem := select_register_data(exec_i.dat_a, exec_i.reg_a, exec_i.fwd_dec_mem_result, forward_condition(exec_i.fwd_dec_mem.reg_write, exec_i.fwd_dec_mem.reg_d, exec_i.reg_a));
        sel_dat_b_mem := select_register_data(exec_i.dat_b, exec_i.reg_b, exec_i.fwd_dec_mem_result, forward_condition(exec_i.fwd_dec_mem.reg_write, exec_i.fwd_dec_mem.reg_d, exec_i.reg_b));

        -- Forwaring paths
        sel_dat_a_ex := select_register_data(exec_i.dat_a, exec_i.reg_a, exec_i.fwd_dec_ex_result, forward_condition(exec_i.fwd_dec_ex.reg_write, exec_i.fwd_dec_ex.reg_d, exec_i.reg_a));
        sel_dat_b_ex := select_register_data(exec_i.dat_b, exec_i.reg_b, exec_i.fwd_dec_ex_result, forward_condition(exec_i.fwd_dec_ex.reg_write, exec_i.fwd_dec_ex.reg_d, exec_i.reg_b));

        sel_dat_a := select_fwd_data(sel_dat_a_ex, sel_dat_a_mem, forward_condition(exec_i.fwd_dec_ex.reg_write, exec_i.fwd_dec_ex.reg_d, exec_i.reg_a));
        sel_dat_b := select_fwd_data(sel_dat_b_ex, sel_dat_b_mem, forward_condition(exec_i.fwd_dec_ex.reg_write, exec_i.fwd_dec_ex.reg_d, exec_i.reg_b));

        -- detect flush signal
        if reg.flush_ex = '1' then
            v.ctrl_mem.mem_write := '0';
            v.ctrl_mem.mem_read := '0';
            v_ctrl_wrb.reg_write := '0';
            v_ctrl_wrb.reg_d := (others => '0');
        else
            v.ctrl_mem := exec_i.ctrl_mem;
            v_ctrl_wrb := exec_i.ctrl_wrb;
        end if;

        mem_result := align_mem_load_neo(exec_i.mem_result, exec_i.ctrl_mem_wrb.transfer_size, exec_i.alu_result(1 downto 0), exec_i.ctrl_mem_wrb.sign_extended);

        -- evaluate forwarding conditions
        if forward_condition(r_ctrl_wrb.reg_write, r_ctrl_wrb.reg_d, exec_i.reg_a) = '1' then
            -- Forward Execution Result to REG a
            dat_a := r.alu_result;
        elsif forward_condition(exec_i.fwd_mem.reg_write, exec_i.fwd_mem.reg_d, exec_i.reg_a) = '1' then
            -- Forward Memory Result to REG a
            dat_a := mem_result;
        else
            -- DEFAULT: value of REG a
            dat_a := sel_dat_a;
        end if;

        -- evaluate forwarding conditions
        if forward_condition(r_ctrl_wrb.reg_write, r_ctrl_wrb.reg_d, exec_i.reg_b) = '1' then
            -- Forward (latched) Execution Result to REG b
            dat_b := r.alu_result;
        elsif forward_condition(exec_i.fwd_mem.reg_write, exec_i.fwd_mem.reg_d, exec_i.reg_b) = '1' then
            -- Forward Memory Result to REG b
            dat_b := mem_result;
        else
            -- DEFAULT: value of REG b
            dat_b := sel_dat_b;
        end if;

        -- No forward anymore for REG D
        -- For Store instructions, the content of REG B is stored
        v.dat_d := dat_b;

        mul_dat_d_i <= dat_b;
        mul_alu_src_a_i <= (others => '0');
        mul_alu_src_b_i <= (others => '0');
        mul_low_high <= '0';
        mul_a_sign <= '0';
        mul_b_sign <= '0';
        mul_valid_inst_i <= '0';

        div_dat_d_i <= dat_b;
        div_alu_src_a_i <= (others => '0');
        div_alu_src_b_i <= (others => '0');
        div_div_rem <= '0';
        div_a_sign <= '0';
        div_b_sign <= '0';
        div_valid_inst_i <= '0';
        div_ena_div_i <= '0';

        -- Set the first operand of the ALU
        case exec_i.ctrl_ex.alu_src_a is
            when ALU_SRC_PC       => alu_src_a := sign_extend(exec_i.program_counter, '0', 32);
            when ALU_SRC_NOT_REGA => alu_src_a := not dat_a;
            when ALU_SRC_ZERO     => alu_src_a := (others => '0');
            when others           => alu_src_a := dat_a;
        end case;

        -- Set the second operand of the ALU
        case exec_i.ctrl_ex.alu_src_b is
            when ALU_SRC_IMM      => alu_src_b := exec_i.imm;
            when ALU_SRC_NOT_IMM  => alu_src_b := not exec_i.imm;
            when ALU_SRC_NOT_REGB => alu_src_b := not dat_b;
            when others           => alu_src_b := dat_b;
        end case;

        -- Determine value of carry in
        case exec_i.ctrl_ex.carry is
            when CARRY_ONE   => carry := '1';
            when others      => carry := '0';
        end case;

        result := (others => '0');
        case exec_i.ctrl_ex.alu_op is
            when NOP        => result := (others => '0');
            when ALU_ADD    => result := add(alu_src_a, alu_src_b, carry);
            when ALU_OR     => result := '0' & (alu_src_a or alu_src_b);
            when ALU_AND    => result := '0' & (alu_src_a and alu_src_b);
            when ALU_XOR    => result := '0' & (alu_src_a xor alu_src_b);
            when ALU_SHIFT  => result := alu_src_a(0) & carry & alu_src_a(CFG_DMEM_WIDTH - 1 downto 1);
            when ALU_SEXT8  => result := '0' & sign_extend(alu_src_a(7 downto 0), alu_src_a(7), 32);
            when ALU_SEXT16 => result := '0' & sign_extend(alu_src_a(15 downto 0), alu_src_a(15), 32);
            when ALU_MUL =>
                if reg.flush_ex = '0' then
                    mul_alu_src_a_i <= alu_src_a;
                    mul_alu_src_b_i <= alu_src_b;
                    mul_low_high <= exec_i.imm(13) or exec_i.imm(12);
                    mul_a_sign <= exec_i.imm(13) and exec_i.imm(12);
                    mul_b_sign <=  exec_i.imm(13);
                    mul_valid_inst_i <= '1';

                    v.dat_d := (others => '0');

                    v.ctrl_mem.mem_write := '0';
                    v.ctrl_mem.mem_read := '0';
                    v.ctrl_mem.transfer_size := WORD;
                    v.ctrl_mem.sign_extended := '0';

                    v_ctrl_wrb.reg_d := "00000";
                    v_ctrl_wrb.reg_write := '0';
                end if;

            when ALU_DIV =>
                if reg.flush_ex = '0' then
                    div_alu_src_a_i <= alu_src_a;
                    div_alu_src_b_i <= alu_src_b;
                    div_div_rem <= exec_i.imm(13);
                    div_a_sign <= not exec_i.imm(12);
                    div_b_sign <= not exec_i.imm(12);
                    div_valid_inst_i <= '1';
                    div_ena_div_i <= '1';

                    v.dat_d := (others => '0');

                    v.ctrl_mem.mem_write := '0';
                    v.ctrl_mem.mem_read := '0';
                    v.ctrl_mem.transfer_size := WORD;
                    v.ctrl_mem.sign_extended := '0';

                    v_ctrl_wrb.reg_d := "00000";
                    v_ctrl_wrb.reg_write := '0';
                end if;

            when ALU_BS =>
                if G_USE_BARREL = true then
                    result := '0' & shift(alu_src_a, alu_src_b(4 downto 0), exec_i.imm(14), exec_i.imm(10));
                else
                    result := (others => '0');
                end if;
            when others =>
                result := (others => '0');
        end case;

        -- Handle CMPU

        -- A <u B = B.!C + !A.C
        cmp_aLTUb := (not alu_src_b(CFG_DMEM_WIDTH - 1) and not result(CFG_DMEM_WIDTH - 1)) or (not alu_src_a(CFG_DMEM_WIDTH - 1) and result(CFG_DMEM_WIDTH - 1));
        -- A <s B = C
        cmp_aLTSb := result(CFG_DMEM_WIDTH - 1);
        -- A == B
        cmp_zero := is_zero(result(CFG_DMEM_WIDTH - 1 downto 0));

        -- Value storing into Rd
        v.alu_result := (others=>'0');
        case exec_i.ctrl_ex.operation is
            -- CMP signed
            when "10"   => v.alu_result(0) := not cmp_zero and cmp_aLTSb;
            -- CMP unsigned
            when "11"   => v.alu_result(0) := not cmp_zero and cmp_aLTUb;
            -- Use ALU result
            when others => v.alu_result := result(CFG_DMEM_WIDTH - 1 downto 0);
        end case;
        -- JAL and JALR: PC + 4 into Rd
        if exec_i.ctrl_ex.branch_cond = BNC then
            v.alu_result := sign_extend(exec_i.pc_plus_four, '0', CFG_DMEM_WIDTH);
        end if;

        pc_plus_imm := add(exec_i.program_counter, exec_i.imm(CFG_IMEM_SIZE - 1 downto 0), '0');

        -- Overwrite branch condition
        if reg.flush_ex = '1' then
            v.branch := '0';
            v.branch_target := (others=>'0');
        else
            if mul_valid_inst_o = '0' and div_valid_inst_o = '0' then
                -- Determine branch condition
                case exec_i.ctrl_ex.branch_cond is
                    when BNC =>  v.branch := '1';
                    when BEQ =>  v.branch := cmp_zero;
                    when BNE =>  v.branch := not cmp_zero;
                    when BLT =>  v.branch := not cmp_zero and cmp_aLTSb;
                    when BGE =>  v.branch := cmp_zero or not cmp_aLTSb;
                    when BLTU => v.branch := not cmp_zero and cmp_aLTUb;
                    when BGEU => v.branch := cmp_zero or not cmp_aLTUb;
                    when others => v.branch := '0';
                end case;

                -- Determine branch target
                case exec_i.ctrl_ex.branch_cond is
                    when NOP =>  v.branch_target := (others=>'0');
                    when BNC =>  v.branch_target := result(CFG_IMEM_SIZE - 1 downto 2) & "00";
                    when others => v.branch_target := pc_plus_imm(CFG_IMEM_SIZE - 1 downto 2) & "00";
                end case;
            end if;
        end if;

        if mul_valid_inst_o = '1' then
            result := '0' & mul_result_o;
            v.alu_result := result(CFG_DMEM_WIDTH - 1 downto 0);
            v.dat_d := mul_dat_d_o;
            v.branch := mul_branch_o;
            v.branch_target := mul_branch_target_o(15 downto 0);
            v.flush_id := mul_flush_id_o;
            v_ctrl_wrb := mul_ctrl_wrb_o;
            v.ctrl_mem := mul_ctrl_mem_o;
        elsif div_valid_inst_o = '1' then
            result := '0' & div_result_o;
            v.alu_result := result(CFG_DMEM_WIDTH - 1 downto 0);
            v.dat_d := div_dat_d_o;
            v.branch := div_branch_o;
            v.branch_target := div_branch_target_o(15 downto 0);
            v.flush_id := div_flush_id_o;
            v_ctrl_wrb := div_ctrl_wrb_o;
            v.ctrl_mem := div_ctrl_mem_o;
        end if;

        -- Determine flush signals
        v.flush_id := v.branch;
        v_reg.flush_ex := v.branch;

        v.end_execution := exec_i.end_execution;

        if exec_i.ctrl_mem.mem_write = '1' or exec_i.ctrl_mem.mem_read = '1' then
            v.ctrl_wrb_ex.reg_write := '0';
            v.ctrl_wrb_ex.reg_d := (others => '0');
            v.ctrl_wrb_mem := v_ctrl_wrb;
        else
            v.ctrl_wrb_mem.reg_write := '0';
            v.ctrl_wrb_mem.reg_d := (others => '0');
            v.ctrl_wrb_ex := v_ctrl_wrb;
        end if;

        rin   <= v;
        regin <= v_reg;

        rin_ctrl_wrb <= v_ctrl_wrb;
    end process;

    execute_seq: process(clk_i)
    procedure proc_execute_reset is
    begin
        r.alu_result             <= (others => '0');
        r.dat_d                  <= (others => '0');
        r.branch                 <= '0';
        r.branch_target          <= (others => '0');
        r.flush_id               <= '0';
        r.ctrl_mem.mem_write     <= '0';
        r.ctrl_mem.mem_read      <= '0';
        r.ctrl_mem.transfer_size <= WORD;
        r.ctrl_mem.sign_extended <= '0';
        reg.flush_ex             <= '0';
        r.end_execution          <= '0';
        r_ctrl_wrb.reg_d         <= (others => '0');
        r_ctrl_wrb.reg_write     <= '0';
    end procedure proc_execute_reset;

    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                proc_execute_reset;
            elsif ena_i = '1' then
                r   <= rin;
                reg <= regin;
                r_ctrl_wrb <= rin_ctrl_wrb;
            end if;
        end if;
    end process;

end arch;
