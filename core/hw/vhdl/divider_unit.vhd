----------------------------------------------------------------------------------------------
--
--      Input file         : divider_unit.vhd
--      Design name        : divider_unit_0
--      Author             : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--      Description        : Divider unit
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.config_Pkg.all;
use work.core_Pkg.all;
use work.std_Pkg.all;

entity divider_unit_0 is
    port (
        dat_d_i         : in  std_logic_vector(31 downto 0);
        alu_src_a_i     : in  std_logic_vector(31 downto 0);
        alu_src_b_i     : in  std_logic_vector(31 downto 0);
        ctrl_wrb_i      : in  forward_type;
        ctrl_mem_i      : in  ctrl_memory;
        rst_i           : in  std_logic;
        clk_i           : in  std_logic;
        ena_i           : in  std_logic;
        ena_div_i       : in  std_logic;
        div_rem         : in  std_logic;
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
end divider_unit_0;

architecture arch of divider_unit_0 is
    component divider_0
        port (
            aclk                   : in  std_logic;
            aclken                 : in  std_logic;
            aresetn                : in  std_logic;
            s_axis_divisor_tvalid  : in  std_logic;
            s_axis_divisor_tdata   : in  std_logic_vector(39 downto 0);
            s_axis_dividend_tvalid : in  std_logic;
            s_axis_dividend_tdata  : in  std_logic_vector(39 downto 0);
            m_axis_dout_tvalid     : out std_logic;
            m_axis_dout_tuser      : out std_logic_vector(0 downto 0);
            m_axis_dout_tdata      : out std_logic_vector(79 downto 0)
        );
    end component;

    -- pipeline control signals
    type pass_type is record
        ctrl_wrb   : forward_type;
        ctrl_mem   : ctrl_memory;
        dat_d      : std_logic_vector(31 downto 0);
        div_rem    : std_logic;
        valid_inst : std_logic;
    end record;
    signal r_reset : pass_type;
    type pass_type_array is array (0 to 29) of pass_type;
    signal r : pass_type_array;

    signal s_aresetn : std_logic;
    signal s_divisor_tdata, s_dividend_tdata : std_logic_vector(39 downto 0);
    signal s_dout_tdata : std_logic_vector(79 downto 0);

    signal s_result : std_logic_vector(31 downto 0);
    signal s_quotient, s_remainder : std_logic_vector(31 downto 0);
    signal s_result_valid : std_logic;

    signal s_divisor_tready, s_dividend_tready : std_logic;

    signal div_0 : std_logic_vector(0 downto 0);

    signal aext, bext   : std_logic_vector(32 downto 0);

begin

    div : divider_0
    port map (
        aclk                   => clk_i,
        aclken                 => ena_i,
        aresetn                => s_aresetn,
        s_axis_divisor_tvalid  => valid_inst_i,
        s_axis_divisor_tdata   => s_divisor_tdata,
        s_axis_dividend_tvalid => valid_inst_i,
        s_axis_dividend_tdata  => s_dividend_tdata,
        m_axis_dout_tvalid     => s_result_valid,
        m_axis_dout_tuser      => div_0,
        m_axis_dout_tdata      => s_dout_tdata
    );

    -- reset signals
    r_reset.ctrl_mem.mem_write     <= '0';
    r_reset.ctrl_mem.mem_read      <= '0';
    r_reset.ctrl_mem.transfer_size <= WORD;
    r_reset.ctrl_mem.sign_extended <= '0';
    r_reset.ctrl_wrb.reg_d         <= (others => '0');
    r_reset.ctrl_wrb.reg_write     <= '0';
    r_reset.div_rem                <= '0';
    r_reset.valid_inst             <= '0';

    s_aresetn <= not rst_i;

    s_divisor_tdata <= "0000000" & bext;
    s_dividend_tdata <= "0000000" & aext;

    aext <= to_stdlogic(a_sign='1' and alu_src_a_i(31)='1') & alu_src_a_i(31 downto 0);
    bext <= to_stdlogic(b_sign='1' and alu_src_b_i(31)='1') & alu_src_b_i(31 downto 0);

    s_quotient <= s_dout_tdata(71 downto 40);
    s_remainder <= s_dout_tdata(31 downto 0);

    s_result <= s_quotient when r(29).div_rem = '0' else
                s_remainder;

    result_o        <= s_result;
    dat_d_o         <= r(29).dat_d;
    branch_o        <= '0';
    branch_target_o <= (others => '0');
    flush_id_o      <= '0';
    ctrl_wrb_o      <= r(29).ctrl_wrb;
    ctrl_mem_o      <= r(29).ctrl_mem;
    valid_inst_o    <= r(29).valid_inst;

    execute_seq : process(clk_i)
    procedure proc_execute_reset is
    begin
        r(0) <= r_reset;
        r(1) <= r_reset;
        r(2) <= r_reset;
        r(3) <= r_reset;
        r(4) <= r_reset;
        r(5) <= r_reset;
        r(6) <= r_reset;
        r(7) <= r_reset;
        r(8) <= r_reset;
        r(9) <= r_reset;
        r(10) <= r_reset;
        r(11) <= r_reset;
        r(12) <= r_reset;
        r(13) <= r_reset;
        r(14) <= r_reset;
        r(15) <= r_reset;
        r(16) <= r_reset;
        r(17) <= r_reset;
        r(18) <= r_reset;
        r(19) <= r_reset;
        r(20) <= r_reset;
        r(21) <= r_reset;
        r(22) <= r_reset;
        r(23) <= r_reset;
        r(24) <= r_reset;
        r(25) <= r_reset;
        r(26) <= r_reset;
        r(27) <= r_reset;
        r(28) <= r_reset;
        r(29) <= r_reset;
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
                r(0).div_rem <= div_rem;
                r(0).valid_inst <= valid_inst_i;
                r(1) <= r(0);
                r(2) <= r(1);
                r(3) <= r(2);
                r(4) <= r(3);
                r(5) <= r(4);
                r(6) <= r(5);
                r(7) <= r(6);
                r(8) <= r(7);
                r(9) <= r(8);
                r(10) <= r(9);
                r(11) <= r(10);
                r(12) <= r(11);
                r(13) <= r(12);
                r(14) <= r(13);
                r(15) <= r(14);
                r(16) <= r(15);
                r(17) <= r(16);
                r(18) <= r(17);
                r(19) <= r(18);
                r(20) <= r(19);
                r(21) <= r(20);
                r(22) <= r(21);
                r(23) <= r(22);
                r(24) <= r(23);
                r(25) <= r(24);
                r(26) <= r(25);
                r(27) <= r(26);
                r(28) <= r(27);
                r(29) <= r(28);
            end if;
        end if;
    end process;

end arch;
