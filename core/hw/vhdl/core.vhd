----------------------------------------------------------------------------------------------
--
--      Input file         : core.vhd
--      Design name        : core
--      Author             : Tamar Kranenburg
--      Modified by        : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--      Description        : Connections between the core stages
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.config_Pkg.all;
use work.core_Pkg.all;
use work.std_Pkg.all;

entity core is
    generic (
        G_INTERRUPT  : boolean := CFG_INTERRUPT;
        G_USE_HW_MUL : boolean := CFG_USE_HW_MUL;
        G_USE_BARREL : boolean := CFG_USE_BARREL;
        G_DEBUG      : boolean := CFG_DEBUG
    );
    port (
        imem_o : out imem_out_type;
        dmem_o : out dmem_out_type;
        imem_i : in imem_in_type;
        dmem_i : in dmem_in_type;
        int_i  : in std_logic;
        rst_i  : in std_logic;
        clk_i  : in std_logic;
        ena_i  : in std_logic;
        end_execution : out std_logic
    );
end core;

architecture arch of core is
    -- IF
    signal fetch_i : fetch_in_type;
    signal fetch_o : fetch_out_type;

    -- ID
    signal decode_i : decode_in_type;
    signal decode_o : decode_out_type;
    signal stall : std_logic;

    -- Register File
    signal gprf_o : gprf_out_type;

    -- EX
    signal exec_i : execute_in_type;
    signal exec_o : execute_out_type;

    -- MEM
    signal mem_i : mem_in_type;
    signal mem_o : mem_out_type;
    signal addr_free_d_mem : std_logic_vector(4 downto 0) := (others => '0');
    signal free_d_mem      : std_logic := '0';
    signal stall_mem       : std_logic := '0';

begin
    fetch_i.hazard        <= decode_o.hazard;
    fetch_i.branch        <= exec_o.branch;
    fetch_i.branch_target <= exec_o.branch_target;

    fetch0 : fetch
    port map (
        fetch_o => fetch_o,
        imem_o  => imem_o,
        fetch_i => fetch_i,
        stall   => stall,
        rst_i   => rst_i,
        ena_i   => ena_i,
        clk_i   => clk_i
    );

    decode_i.program_counter <= fetch_o.program_counter;
    decode_i.pc_plus_four    <= fetch_o.pc_plus_four;
    decode_i.instruction     <= imem_i.dat_i;
    decode_i.ctrl_wrb_mem    <= mem_o.ctrl_wrb;
    decode_i.ctrl_wrb_ex     <= exec_o.ctrl_wrb_ex;
    decode_i.ctrl_mem_wrb    <= mem_o.ctrl_mem_wrb;
    decode_i.mem_result      <= dmem_i.dat_i;
    decode_i.alu_result_mem  <= mem_o.alu_result;
    decode_i.alu_result_ex   <= exec_o.alu_result;
    decode_i.interrupt       <= int_i;
    decode_i.flush_id        <= exec_o.flush_id;

    decode0: decode
    generic map (
        G_INTERRUPT  => G_INTERRUPT,
        G_USE_HW_MUL => G_USE_HW_MUL,
        G_USE_BARREL => G_USE_BARREL,
        G_DEBUG      => G_DEBUG
    )
    port map (
        decode_o          => decode_o,
        decode_i          => decode_i,
        addr_free_d_mem_i => addr_free_d_mem,
        free_d_mem_i      => free_d_mem,
        stall_mem         => stall_mem,
        gprf_o            => gprf_o,
        stall             => stall,
        ena_i             => ena_i,
        rst_i             => rst_i,
        clk_i             => clk_i
    );

    exec_i.fwd_dec_mem        <= decode_o.fwd_dec_mem;
    exec_i.fwd_dec_ex         <= decode_o.fwd_dec_ex;
    exec_i.fwd_dec_mem_result <= decode_o.fwd_dec_mem_result;
    exec_i.fwd_dec_ex_result  <= decode_o.fwd_dec_ex_result;

    exec_i.dat_a              <= gprf_o.dat_a_o;
    exec_i.dat_b              <= gprf_o.dat_b_o;
    exec_i.reg_a              <= decode_o.reg_a;
    exec_i.reg_b              <= decode_o.reg_b;

    exec_i.imm                <= decode_o.imm;
    exec_i.program_counter    <= decode_o.program_counter;
    exec_i.pc_plus_four       <= decode_o.pc_plus_four;
    exec_i.ctrl_wrb           <= decode_o.ctrl_wrb;
    exec_i.ctrl_mem           <= decode_o.ctrl_mem;
    exec_i.ctrl_ex            <= decode_o.ctrl_ex;

    exec_i.fwd_mem            <= mem_o.ctrl_wrb;
    exec_i.mem_result         <= dmem_i.dat_i;
    exec_i.alu_result         <= mem_o.alu_result;
    exec_i.ctrl_mem_wrb       <= mem_o.ctrl_mem_wrb;

    exec_i.end_execution      <= decode_o.end_execution;

    execute0 : execute
    generic map (
        G_USE_HW_MUL => G_USE_HW_MUL,
        G_USE_BARREL => G_USE_BARREL
    )
    port map (
        exec_o => exec_o,
        exec_i => exec_i,
        ena_i  => ena_i,
        rst_i  => rst_i,
        clk_i  => clk_i
    );

    mem_i.alu_result    <= exec_o.alu_result;
    mem_i.dat_d         <= exec_o.dat_d;
    mem_i.ctrl_wrb      <= exec_o.ctrl_wrb_mem;
    mem_i.ctrl_mem      <= exec_o.ctrl_mem;
    mem_i.mem_result    <= dmem_i.dat_i;
    mem_i.hit           <= dmem_i.ena_i;

    mem_i.end_execution <= exec_o.end_execution;

    mem0 : mem
    port map (
        mem_o             => mem_o,
        dmem_o            => dmem_o,
        addr_free_d_mem_o => addr_free_d_mem,
        free_d_mem_o      => free_d_mem,
        stall_mem         => stall_mem,
        mem_i             => mem_i,
        ena_i             => ena_i,
        rst_i             => rst_i,
        clk_i             => clk_i
    );

    end_execution <= mem_o.end_execution;

end arch;
