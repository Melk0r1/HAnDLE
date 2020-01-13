----------------------------------------------------------------------------------------------
--
--      Input file         : fetch.vhd
--      Design name        : fetch
--      Author             : Tamar Kranenburg
--      Modified by        : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--
--      Description        : Instruction Fetch Stage inserts instruction into the pipeline. It
--                           uses a BRAM component which holds
--                           the instructions. The next instruction is computed in the decode
--                           stage.
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.config_Pkg.all;
use work.core_Pkg.all;
use work.std_Pkg.all;

entity fetch is
    port (
        fetch_o : out fetch_out_type;
        imem_o  : out imem_out_type;
        fetch_i : in fetch_in_type;
        stall   : in std_logic;
        rst_i   : in std_logic;
        ena_i   : in std_logic;
        clk_i   : in std_logic
    );
end fetch;

architecture arch of fetch is
    signal r, rin  : fetch_out_type;
	signal imem_pc : std_logic_vector(CFG_IMEM_SIZE - 1 downto 0);
    signal r_stall : std_logic;

begin
    fetch_o.pc_plus_four    <= r.pc_plus_four;
	fetch_o.program_counter <= r.program_counter;

    imem_o.adr_o <= imem_pc; -- rin.pc_plus_four;
    imem_o.ena_o <= ena_i and (not stall or fetch_i.branch);

    fetch_comb: process(fetch_i, r, rst_i, stall, r_stall)
        variable v : fetch_out_type;
		variable v_inc_pc, v_pc_src : std_logic_vector(CFG_IMEM_SIZE - 1 downto 0);
    begin
        v := r;

		if fetch_i.branch = '1' then
			v_pc_src := fetch_i.branch_target;
		elsif stall = '1' and r_stall = '0' and fetch_i.branch = '0' then
            v_pc_src := r.program_counter;
        else
			v_pc_src := r.pc_plus_four;
		end if;

		v_inc_pc := increment(v_pc_src(CFG_IMEM_SIZE - 1 downto 2)) & "00";

        -- reset
        if rst_i = '1' then
			v.pc_plus_four    := (others => '0');
			v.program_counter := (others => '0');
        -- stall
		elsif stall = '1' and r_stall = '0' and fetch_i.branch = '0' then
			v.pc_plus_four    := r.pc_plus_four;
			v.program_counter := r.program_counter;
        -- branch
        elsif fetch_i.branch = '1' then
			v.pc_plus_four    := v_inc_pc;
            v.program_counter := fetch_i.branch_target;
        -- next PC
        else
            v.pc_plus_four    := v_inc_pc;
			v.program_counter := r.pc_plus_four;
        end if;

        -- instruction memory address
        imem_pc <= v_pc_src; -- registered next program counter OR branch target

        rin <= v;
    end process;

    fetch_seq: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                r.program_counter <= (others => '0');
				r.pc_plus_four    <= (others => '0');
            elsif ena_i = '1' and (stall = '0' or fetch_i.branch = '1') then
                r <= rin;
            end if;
            if ena_i = '1' then
                r_stall <= stall;
            end if;
        end if;
    end process;

end arch;
