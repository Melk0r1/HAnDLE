----------------------------------------------------------------------------------------------
--
--      Input file         : multiplier_unit.vhd
--      Design name        : multiplier_unit
--      Author             : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--
--      Description        : Multiplier unit
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.config_Pkg.all;
use work.core_Pkg.all;
use work.std_Pkg.all;

entity multiplier_unit is
    port (
        dat_d_i         : in  std_logic_vector(31 downto 0);
        alu_src_a_i     : in  std_logic_vector(31 downto 0);
        alu_src_b_i     : in  std_logic_vector(31 downto 0);
        ctrl_wrb_i      : in  forward_type;
        ctrl_mem_i      : in  ctrl_memory;
        rst_i           : in  std_logic;
        clk_i           : in  std_logic;
        ena_i           : in  std_logic;
        low_high        : in  std_logic;
        a_sign          : in  std_logic;
        b_sign          : in  std_logic;
        valid_inst_i    : in  std_logic;
        result_o        : out std_logic_vector(31 downto 0);
        dat_d_o         : out std_logic_vector(31 downto 0);
        branch_o        : out std_logic;
        branch_target_o : out std_logic_vector(31 downto 0);
        flush_id_o      : out std_logic;
        ctrl_wrb_o      : out forward_type;
        ctrl_mem_o      : out ctrl_memory;
        valid_inst_o    : out std_logic
    );
end multiplier_unit;

architecture arch of multiplier_unit is
    component multiplier
        port (
            CLK : in  std_logic;
            A   : in  std_logic_vector(32 downto 0);
            B   : in  std_logic_vector(32 downto 0);
            P   : out std_logic_vector(65 downto 0)
        );
    end component;

    type pass_type is record
        ctrl_wrb  : forward_type;
        ctrl_mem  : ctrl_memory;
        dat_d     : std_logic_vector(31 downto 0);
        low_high  : std_logic;
        valid_inst: std_logic;
    end record;
    signal r_reset : pass_type;
    type pass_type_array is array (0 to 5) of pass_type;
    signal r : pass_type_array;

    signal s_result : std_logic_vector(31 downto 0);

    signal aext, bext : std_logic_vector(32 downto 0);
    signal x          : std_logic_vector(32 + 32 + 1 downto 0);

begin
    mul : multiplier
    port map (
        CLK => clk_i,
        A => aext,
        B => bext,
        P => x
    );

    -- reset signals
    r_reset.ctrl_mem.mem_write     <= '0';
    r_reset.ctrl_mem.mem_read      <= '0';
    r_reset.ctrl_mem.transfer_size <= WORD;
    r_reset.ctrl_mem.sign_extended <= '0';
    r_reset.ctrl_wrb.reg_d         <= (others => '0');
    r_reset.ctrl_wrb.reg_write     <= '0';
    r_reset.low_high               <= '0';
    r_reset.valid_inst             <= '0';

    aext <= to_stdlogic(a_sign='1' and alu_src_a_i(31)='1') & alu_src_a_i(31 downto 0);
    bext <= to_stdlogic(b_sign='1' and alu_src_b_i(31)='1') & alu_src_b_i(31 downto 0);

    s_result <= x(31 downto 0) when r(5).low_high = '0' else
                x(32 + 32 - 1 downto 32);

    result_o        <= s_result;
    dat_d_o         <= r(5).dat_d;
    branch_o        <= '0';
    branch_target_o <= (others => '0');
    flush_id_o      <= '0';
    ctrl_wrb_o      <= r(5).ctrl_wrb;
    ctrl_mem_o      <= r(5).ctrl_mem;
    valid_inst_o    <= r(5).valid_inst;

    execute_seq: process(clk_i)
    procedure proc_execute_reset is
    begin
        r(0) <= r_reset;
        r(1) <= r_reset;
        r(2) <= r_reset;
        r(3) <= r_reset;
        r(4) <= r_reset;
        r(5) <= r_reset;
    end procedure proc_execute_reset;
    -- move the control signals to the next position
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                proc_execute_reset;
            elsif ena_i = '1' then
                r(0).ctrl_mem <= ctrl_mem_i;
                r(0).ctrl_wrb <= ctrl_wrb_i;
                r(0).dat_d <= dat_d_i;
                r(0).low_high <= low_high;
                r(0).valid_inst <= valid_inst_i;
                r(1) <= r(0);
                r(2) <= r(1);
                r(3) <= r(2);
                r(4) <= r(3);
                r(5) <= r(4);
            end if;
        end if;
    end process;

end arch;
