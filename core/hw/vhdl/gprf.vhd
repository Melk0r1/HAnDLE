----------------------------------------------------------------------------------------------
--
--      Input file         : gprf.vhd
--      Design name        : gprf
--      Author             : Tamar Kranenburg
--      Modified by        : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--
--      Description        : Register file
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.config_Pkg.all;
use work.core_Pkg.all;
use work.std_Pkg.all;

entity gprf is
    port (
        gprf_o : out gprf_out_type;
        gprf_i : in gprf_in_type;
        ena_i  : in std_logic;
        clk_i  : in std_logic
    );
end gprf;

architecture arch of gprf is
    component register32b is
        generic (
            WIDTH : positive := CFG_DMEM_WIDTH
        );
        port (
            clk_i       : in  std_logic;
            ena_i       : in  std_logic;
            dat_w_mem_i : in  std_logic_vector(WIDTH - 1 downto 0);
            wre_mem_i   : in  std_logic;
            dat_w_ex_i  : in  std_logic_vector(WIDTH - 1 downto 0);
            wre_ex_i    : in  std_logic;
            dat_o       : out std_logic_vector(WIDTH - 1 downto 0)
        );
    end component;

    -- outputs of 32 registers
    signal R0_out, R1_out, R2_out, R3_out : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    signal R4_out, R5_out, R6_out, R7_out : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    signal R8_out, R9_out, R10_out, R11_out : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    signal R12_out, R13_out, R14_out, R15_out : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    signal R16_out, R17_out, R18_out, R19_out : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    signal R20_out, R21_out, R22_out, R23_out : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    signal R24_out, R25_out, R26_out, R27_out : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    signal R28_out, R29_out, R30_out, R31_out : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    -- other internal signals
    -- write enable vector (of 32 bits) to activate register load
    -- one bit per register
    signal wr_reg_mem, wr_reg_ex : std_logic_vector(31 downto 0);

    signal dat_w_mem_i, dat_w_ex_i, A_out, B_out, reg_a_out, reg_B_out : std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);

    signal reg_d_mem, reg_d_ex : std_logic_vector(4 downto 0);

    signal s_wre_mem_i : std_logic;

begin
    -- give preference to the EX data when both stages (EX and MEM) are trying to write on the same destination register
    s_wre_mem_i <= '0' when gprf_i.wre_mem_i = '0' or (gprf_i.wre_mem_i = '1' and gprf_i.wre_ex_i = '1' and gprf_i.adr_w_mem_i = gprf_i.adr_w_ex_i) else
                   '1';

    -- Data from MEM and from EX
    dat_w_mem_i <= gprf_i.dat_w_mem_i;
    dat_w_ex_i <= gprf_i.dat_w_ex_i;

    -- Reg D selection for both ports
    with s_wre_mem_i select
    reg_d_mem <= gprf_i.adr_w_mem_i when '1',
                 "00000" when others;

    with gprf_i.wre_ex_i select
    reg_d_ex <= gprf_i.adr_w_ex_i when '1',
                 "00000" when others;

    -- WE mem decoder 5x32
    with reg_d_mem select
    wr_reg_mem <= "00000000000000000000000000000010" when "00001",
                  "00000000000000000000000000000100" when "00010",
                  "00000000000000000000000000001000" when "00011",
                  "00000000000000000000000000010000" when "00100",
                  "00000000000000000000000000100000" when "00101",
                  "00000000000000000000000001000000" when "00110",
                  "00000000000000000000000010000000" when "00111",
                  "00000000000000000000000100000000" when "01000",
                  "00000000000000000000001000000000" when "01001",
                  "00000000000000000000010000000000" when "01010",
                  "00000000000000000000100000000000" when "01011",
                  "00000000000000000001000000000000" when "01100",
                  "00000000000000000010000000000000" when "01101",
                  "00000000000000000100000000000000" when "01110",
                  "00000000000000001000000000000000" when "01111",
                  "00000000000000010000000000000000" when "10000",
                  "00000000000000100000000000000000" when "10001",
                  "00000000000001000000000000000000" when "10010",
                  "00000000000010000000000000000000" when "10011",
                  "00000000000100000000000000000000" when "10100",
                  "00000000001000000000000000000000" when "10101",
                  "00000000010000000000000000000000" when "10110",
                  "00000000100000000000000000000000" when "10111",
                  "00000001000000000000000000000000" when "11000",
                  "00000010000000000000000000000000" when "11001",
                  "00000100000000000000000000000000" when "11010",
                  "00001000000000000000000000000000" when "11011",
                  "00010000000000000000000000000000" when "11100",
                  "00100000000000000000000000000000" when "11101",
                  "01000000000000000000000000000000" when "11110",
                  "10000000000000000000000000000000" when "11111",
                  "00000000000000000000000000000000" when others;

    -- WE ex decoder 5x32
    with reg_d_ex select
    wr_reg_ex <= "00000000000000000000000000000010" when "00001",
                 "00000000000000000000000000000100" when "00010",
                 "00000000000000000000000000001000" when "00011",
                 "00000000000000000000000000010000" when "00100",
                 "00000000000000000000000000100000" when "00101",
                 "00000000000000000000000001000000" when "00110",
                 "00000000000000000000000010000000" when "00111",
                 "00000000000000000000000100000000" when "01000",
                 "00000000000000000000001000000000" when "01001",
                 "00000000000000000000010000000000" when "01010",
                 "00000000000000000000100000000000" when "01011",
                 "00000000000000000001000000000000" when "01100",
                 "00000000000000000010000000000000" when "01101",
                 "00000000000000000100000000000000" when "01110",
                 "00000000000000001000000000000000" when "01111",
                 "00000000000000010000000000000000" when "10000",
                 "00000000000000100000000000000000" when "10001",
                 "00000000000001000000000000000000" when "10010",
                 "00000000000010000000000000000000" when "10011",
                 "00000000000100000000000000000000" when "10100",
                 "00000000001000000000000000000000" when "10101",
                 "00000000010000000000000000000000" when "10110",
                 "00000000100000000000000000000000" when "10111",
                 "00000001000000000000000000000000" when "11000",
                 "00000010000000000000000000000000" when "11001",
                 "00000100000000000000000000000000" when "11010",
                 "00001000000000000000000000000000" when "11011",
                 "00010000000000000000000000000000" when "11100",
                 "00100000000000000000000000000000" when "11101",
                 "01000000000000000000000000000000" when "11110",
                 "10000000000000000000000000000000" when "11111",
                 "00000000000000000000000000000000" when others;

    -- instances of 32 x 32-bit Registers
    R0 : register32b port map (
            clk_i => clk_i, ena_i => '1',
            dat_w_mem_i => x"00000000", wre_mem_i => '1',
            dat_w_ex_i => x"00000000", wre_ex_i => '1',
            dat_o => R0_out);

    R1 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(1),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(1),
            dat_o => R1_out);

    R2 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(2),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(2),
            dat_o => R2_out);

    R3 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(3),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(3),
            dat_o => R3_out);

    R4 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(4),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(4),
            dat_o => R4_out);

    R5 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(5),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(5),
            dat_o => R5_out);

    R6 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(6),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(6),
            dat_o => R6_out);

    R7 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(7),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(7),
            dat_o => R7_out);

    R8 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(8),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(8),
            dat_o => R8_out);

    R9 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(9),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(9),
            dat_o => R9_out);

    R10 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(10),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(10),
            dat_o => R10_out);

    R11 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(11),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(11),
            dat_o => R11_out);

    R12 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(12),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(12),
            dat_o => R12_out);

    R13 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(13),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(13),
            dat_o => R13_out);

    R14 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(14),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(14),
            dat_o => R14_out);

    R15 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(15),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(15),
            dat_o => R15_out);

    R16 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(16),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(16),
            dat_o => R16_out);

    R17 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(17),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(17),
            dat_o => R17_out);

    R18 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(18),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(18),
            dat_o => R18_out);

    R19 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(19),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(19),
            dat_o => R19_out);

    R20 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(20),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(20),
            dat_o => R20_out);

    R21 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(21),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(21),
            dat_o => R21_out);


    R22 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(22),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(22),
            dat_o => R22_out);

    R23 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(23),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(23),
            dat_o => R23_out);

    R24 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(24),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(24),
            dat_o => R24_out);

    R25 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(25),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(25),
            dat_o => R25_out);

    R26 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(26),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(26),
            dat_o => R26_out);

    R27 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(27),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(27),
            dat_o => R27_out);

    R28 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(28),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(28),
            dat_o => R28_out);

    R29 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(29),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(29),
            dat_o => R29_out);

    R30 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(30),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(30),
            dat_o => R30_out);

    R31 : register32b port map (
            clk_i => clk_i, ena_i => ena_i,
            dat_w_mem_i => dat_w_mem_i, wre_mem_i => wr_reg_mem(31),
            dat_w_ex_i => dat_w_ex_i, wre_ex_i => wr_reg_ex(31),
            dat_o => R31_out);

    -- MUX32x1 for A output
    with gprf_i.adr_a_i select
    A_out <= R0_out  when "00000",
             R1_out  when "00001",
             R2_out  when "00010",
             R3_out  when "00011",
             R4_out  when "00100",
             R5_out  when "00101",
             R6_out  when "00110",
             R7_out  when "00111",
             R8_out  when "01000",
             R9_out  when "01001",
             R10_out when "01010",
             R11_out when "01011",
             R12_out when "01100",
             R13_out when "01101",
             R14_out when "01110",
             R15_out when "01111",
             R16_out when "10000",
             R17_out when "10001",
             R18_out when "10010",
             R19_out when "10011",
             R20_out when "10100",
             R21_out when "10101",
             R22_out when "10110",
             R23_out when "10111",
             R24_out when "11000",
             R25_out when "11001",
             R26_out when "11010",
             R27_out when "11011",
             R28_out when "11100",
             R29_out when "11101",
             R30_out when "11110",
             R31_out when others;

    gprf_o.dat_a_o <= reg_A_out;

    -- MUX32x1 for B output
    with gprf_i.adr_b_i select
    B_out <= R0_out  when "00000",
             R1_out  when "00001",
             R2_out  when "00010",
             R3_out  when "00011",
             R4_out  when "00100",
             R5_out  when "00101",
             R6_out  when "00110",
             R7_out  when "00111",
             R8_out  when "01000",
             R9_out  when "01001",
             R10_out when "01010",
             R11_out when "01011",
             R12_out when "01100",
             R13_out when "01101",
             R14_out when "01110",
             R15_out when "01111",
             R16_out when "10000",
             R17_out when "10001",
             R18_out when "10010",
             R19_out when "10011",
             R20_out when "10100",
             R21_out when "10101",
             R22_out when "10110",
             R23_out when "10111",
             R24_out when "11000",
             R25_out when "11001",
             R26_out when "11010",
             R27_out when "11011",
             R28_out when "11100",
             R29_out when "11101",
             R30_out when "11110",
             R31_out when others;

    gprf_o.dat_b_o <= reg_B_out;

    process(clk_i)
    begin
        if (rising_edge(clk_i)) then
            reg_A_out <= A_out;
            reg_B_out <= B_out;
        end if;
    end process;

end arch;
