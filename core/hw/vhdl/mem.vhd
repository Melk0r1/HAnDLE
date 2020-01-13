----------------------------------------------------------------------------------------------
--
--      Input file         : mem.vhd
--      Design name        : mem
--      Author             : Tamar Kranenburg
--      Modified by        : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--
--      Description        : Memory stage
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.config_Pkg.all;
use work.core_Pkg.all;
use work.std_Pkg.all;

entity mem is
    port (
        mem_o  : out mem_out_type;
        dmem_o : out dmem_out_type;
        addr_free_d_mem_o : out std_logic_vector(4 downto 0);
        free_d_mem_o : out std_logic;
        stall_mem : out std_logic;
        mem_i  : in mem_in_type;
        ena_i  : in std_logic;
        rst_i  : in std_logic;
        clk_i  : in std_logic
);
end mem;

architecture arch of mem is
    component mem_buffer is
        generic (
            depth : integer := 10
        );
        port (
            clk_i   : in  std_logic;
            rst_i   : in  std_logic;
            rd_en_i : in  std_logic;
            wr_en_i : in  std_logic;
            data_i  : in  mem_in_type;
            data_o  : out mem_in_type;
            stall_o : out std_logic
        );
    end component;

    signal r, rin : mem_out_type;
    signal mem_result : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);

    signal stall : std_logic := '0';
    signal data_i, data_o : mem_in_type;
    signal wr_en, rd_en : std_logic := '0';
    signal valid : std_logic := '0';

    -- Control
    type ctrl_state is (
        IDLE,
        REQ
    );
    signal state, next_state : ctrl_state := IDLE;

    signal en_mem : std_logic := '0';
    signal hit : std_logic := '0';

    signal nop : mem_out_type;

begin
    -- connect pipeline signals

    addr_free_d_mem_o <= r.ctrl_wrb.reg_d;

    free_d_mem_o <= rd_en;

    stall_mem <= stall;

    data_i <= mem_i;

    wr_en <= '1' when mem_i.ctrl_mem.mem_read = '1' or mem_i.ctrl_mem.mem_write = '1' else
             '0';

    valid <= '1' when data_o.ctrl_mem.mem_read = '1' or data_o.ctrl_mem.mem_write = '1' else
             '0';

    hit <= mem_i.hit;

    nop.alu_result <= (others => '0');
    nop.ctrl_wrb.reg_d <= (others => '0');
    nop.ctrl_wrb.reg_write <= '0';
    nop.ctrl_mem_wrb.mem_read <= '0';
    nop.ctrl_mem_wrb.transfer_size <= WORD;
    nop.ctrl_mem_wrb.sign_extended <= '0';
    nop.end_execution <= '0';

    -- connect memory interface signals
    dmem_o.dat_o <= mem_result;
    dmem_o.sel_o <= decode_mem_store(data_o.alu_result(1 downto 0), data_o.ctrl_mem.transfer_size);
    dmem_o.we_o  <= data_o.ctrl_mem.mem_write;
    dmem_o.adr_o <= data_o.alu_result(CFG_DMEM_SIZE - 1 downto 0);
    dmem_o.ena_o <= en_mem;--data_o.ctrl_mem.mem_read or data_o.ctrl_mem.mem_write;

    mem_comb: process(data_o, data_o.ctrl_wrb, data_o.ctrl_mem, r, r.ctrl_wrb, r.ctrl_mem_wrb)
        variable v : mem_out_type;
        variable intermediate : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    begin
        v := r;
        v.ctrl_wrb := data_o.ctrl_wrb;

        v.alu_result := data_o.alu_result;

        v.end_execution := data_o.end_execution;

        -- Forward memory result
        if CFG_MEM_FWD_WRB = true and ( r.ctrl_mem_wrb.mem_read and compare(data_o.ctrl_wrb.reg_d, r.ctrl_wrb.reg_d)) = '1' then
            intermediate := align_mem_load(data_o.mem_result, r.ctrl_mem_wrb.transfer_size, r.alu_result(1 downto 0));
            mem_result <= align_mem_store(intermediate, data_o.ctrl_mem.transfer_size);
        else
            mem_result <= data_o.dat_d;
        end if;

        v.ctrl_mem_wrb.mem_read      := data_o.ctrl_mem.mem_read;
        v.ctrl_mem_wrb.transfer_size := data_o.ctrl_mem.transfer_size;
        v.ctrl_mem_wrb.sign_extended := data_o.ctrl_mem.sign_extended;

        rin <= v;
    end process;

    mem_seq: process(clk_i)
    procedure proc_mem_reset is
    begin
        r.alu_result  <= (others => '0');
        r.ctrl_wrb.reg_d <= (others => '0');
        r.ctrl_wrb.reg_write <= '0';
        r.ctrl_mem_wrb.mem_read <= '0';
        r.ctrl_mem_wrb.transfer_size <= WORD;
        r.ctrl_mem_wrb.sign_extended <= '0';
        r.end_execution <= '0';
        state <= IDLE;
    end procedure proc_mem_reset;
    begin
        if rising_edge(clk_i) then
            state <= next_state;--
            if rst_i = '1' then
                proc_mem_reset;
            elsif ena_i = '1' then
                r <= rin;
            end if;
        end if;
    end process;

    COMB_PROC : process(state, valid, hit, r, nop) is
    begin
        en_mem <= '0';
        rd_en <= '0';
        mem_o <= nop;

        case state is
            -- wait for a valid memory request
            when IDLE =>
                if (valid = '0') then
                    next_state <= IDLE;
                else
                    next_state <= REQ;
                    en_mem <= '1';
                end if;

            -- wait for a cache hit
            when REQ =>
                if (hit = '0') then
                    next_state <= REQ;
                else
                    next_state <= IDLE;
                    rd_en <= '1';
                    mem_o <= r;
                end if;

        end case;
    end process;

    buffer_4 : mem_buffer
    generic map (
        depth => 10
    )
    port map (
        clk_i   => clk_i,
        rst_i   => rst_i,
        rd_en_i => rd_en,
        wr_en_i => wr_en,
        data_i  => data_i,
        data_o  => data_o,
        stall_o => stall
    );

end arch;
