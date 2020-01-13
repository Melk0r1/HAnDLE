----------------------------------------------------------------------------------------------
--
--      Input file         : scoreboard.vhd
--      Design name        : scoreboard
--      Author             : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--
--      Description        : Dependency Handler Unit unit (Scoreboard)
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.std_Pkg.all;

entity scoreboard is
    generic (
        n_bits : natural := 5
    );
    port (
        clk               : in  std_logic;
        rst               : in  std_logic;
        addr_a_i          : in  std_logic_vector(4 downto 0);
        addr_b_i          : in  std_logic_vector(4 downto 0);
        addr_d_i          : in  std_logic_vector(4 downto 0);
        addr_free_d_mem_i : in  std_logic_vector(4 downto 0);
        we_a_i            : in  std_logic;
        we_b_i            : in  std_logic;
        we_d_i            : in  std_logic;
        we_d_mem_i        : in  std_logic;
        free_d_mem_i      : in  std_logic;
        data_a_i          : in  std_logic_vector(4 downto 0);
        data_b_i          : in  std_logic_vector(4 downto 0);
        data_d_i          : in  std_logic_vector(4 downto 0);
        data_d_mem_i      : in  std_logic;
        we_mul_i          : in  std_logic;
        rst_mul_i         : in  std_logic;
        we_div_i          : in  std_logic;
        rst_div_i         : in  std_logic;
        hazard            : out std_logic --stall
    );
end scoreboard;

architecture structural of scoreboard is
    component sb_shiftregister is
        generic (
            n_bits : integer := 32
        );
        port (
            clk      : in  std_logic;
            rst      : in  std_logic;
            D        : in  std_logic_vector(n_bits-1 downto 0);
            D_mem    : in  std_logic;
            WE       : in  std_logic;
            WE_mem   : in  std_logic;
            FREE_mem : in  std_logic;
            Q        : out std_logic_vector(n_bits-1 downto 0);
            busy     : out std_logic
        );
    end component;

    component Decoder is
        port (
            A : in  std_logic_vector(4 downto 0);
            D : out std_logic_vector(31 downto 0)
        );
    end component;

    signal OH_A : std_logic_vector(31 downto 0);
    signal OH_B : std_logic_vector(31 downto 0);
    signal OH_D : std_logic_vector(31 downto 0);

    signal OH_FREE_D : std_logic_vector(31 downto 0);

    signal OH_Data_A : std_logic_vector(31 downto 0);
    signal OH_Data_B : std_logic_vector(31 downto 0);
    signal OH_Data_D : std_logic_vector(31 downto 0);

    signal WE, WE_mem, FREE_mem : std_logic_vector(31 downto 0);

    type reg_type is array(0 to 31) of std_logic_vector(n_bits - 1 downto 0);
    signal Q : reg_type;
    signal D : reg_type;

    signal busy : std_logic_vector(31 downto 0) := (others => '0');

    signal busy_a, busy_b, busy_d : std_logic;

    --Multiplier
    signal busy_mul_ex : std_logic;
    signal s_q_mul     : std_logic_vector(5 downto 0);

    --Divider
    signal busy_div_ex : std_logic;
    signal busy_div    : std_logic;
    signal s_q_div     : std_logic_vector(30 downto 0);

begin

    -- Decode: Binary (addr_a_i) to One-Hot_A (H0 to H31)
    Decoder_ADDR_A: Decoder
    port map (
        A => addr_a_i,
        D => OH_A
    );

    -- Decode: Binary (addr_b_i) to One-Hot_B (H0 to H31)
    Decoder_ADDR_B: Decoder
    port map (
        A => addr_b_i,
        D => OH_B
    );

    -- Decode: Binary (addr_d_i) to One-Hot_D (H0 to H31)
    Decoder_ADDR_D: Decoder
    port map (
        A => addr_d_i,
        D => OH_D
    );

    Decoder_ADDR_FREE_D : Decoder
    port map (
        A => addr_free_d_mem_i,
        D => OH_FREE_D
    );

    -- Decode: Binary (data_a) to One-Hot_Data_A (0 to 31)
    Decoder_DATA_A: Decoder
    port map (
        A => data_a_i,
        D => OH_Data_A
    );

    -- Decode: Binary (data_b) to One-Hot_Data_B (0 to 31)
    Decoder_DATA_B: Decoder
    port map (
        A => data_b_i,
        D => OH_Data_B
    );

    -- Decode: Binary (data_d) to One-Hot_Data_D (0 to 31)
    Decoder_DATA_D: Decoder
    port map (
        A => data_d_i,
        D => OH_Data_D
    );

    -- Generate Write-EN Signals (0 to 31) for each register (R0 to R31, respectively).
    GenEN: for i in 0 to 31 generate
        WE(i) <= (OH_A(i) and we_a_i) or (OH_B(i) and we_b_i) or (OH_D(i) and we_d_i);
        WE_mem(i) <= (OH_D(i) and we_d_mem_i);
        FREE_mem(i) <= (OH_FREE_D(i) and free_d_mem_i);
        D(i) <= OH_Data_A when (OH_A(i) = '1' and we_a_i = '1') else
                OH_Data_B when (OH_B(i) = '1' and we_b_i = '1') else
                OH_Data_D when (OH_D(i) = '1' and we_d_i = '1') else
                (others => '0');
    end generate;

    -- Instantiate the 32 registers... Register R0 is stuck at Q0=0
    Q(0) <= (others => '0');
    R1:  sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(1), D_mem => data_d_mem_i, WE => WE(1), WE_mem => WE_mem(1), FREE_mem => FREE_mem(1), clk => clk, Q => Q(1), busy => busy(1));
    R2:  sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(2), D_mem => data_d_mem_i, WE => WE(2), WE_mem => WE_mem(2), FREE_mem => FREE_mem(2), clk => clk, Q => Q(2), busy => busy(2));
    R3:  sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(3), D_mem => data_d_mem_i, WE => WE(3), WE_mem => WE_mem(3), FREE_mem => FREE_mem(3), clk => clk, Q => Q(3), busy => busy(3));
    R4:  sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(4), D_mem => data_d_mem_i, WE => WE(4), WE_mem => WE_mem(4), FREE_mem => FREE_mem(4), clk => clk, Q => Q(4), busy => busy(4));
    R5:  sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(5), D_mem => data_d_mem_i, WE => WE(5), WE_mem => WE_mem(5), FREE_mem => FREE_mem(5), clk => clk, Q => Q(5), busy => busy(5));
    R6:  sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(6), D_mem => data_d_mem_i, WE => WE(6), WE_mem => WE_mem(6), FREE_mem => FREE_mem(6), clk => clk, Q => Q(6), busy => busy(6));
    R7:  sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(7), D_mem => data_d_mem_i, WE => WE(7), WE_mem => WE_mem(7), FREE_mem => FREE_mem(7), clk => clk, Q => Q(7), busy => busy(7));
    R8:  sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(8), D_mem => data_d_mem_i, WE => WE(8), WE_mem => WE_mem(8), FREE_mem => FREE_mem(8), clk => clk, Q => Q(8), busy => busy(8));
    R9:  sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(9), D_mem => data_d_mem_i, WE => WE(9), WE_mem => WE_mem(9), FREE_mem => FREE_mem(9), clk => clk, Q => Q(9), busy => busy(9));
    R10: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(10), D_mem => data_d_mem_i, WE => WE(10), WE_mem => WE_mem(10), FREE_mem => FREE_mem(10), clk => clk, Q => Q(10), busy => busy(10));
    R11: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(11), D_mem => data_d_mem_i, WE => WE(11), WE_mem => WE_mem(11), FREE_mem => FREE_mem(11), clk => clk, Q => Q(11), busy => busy(11));
    R12: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(12), D_mem => data_d_mem_i, WE => WE(12), WE_mem => WE_mem(12), FREE_mem => FREE_mem(12), clk => clk, Q => Q(12), busy => busy(12));
    R13: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(13), D_mem => data_d_mem_i, WE => WE(13), WE_mem => WE_mem(13), FREE_mem => FREE_mem(13), clk => clk, Q => Q(13), busy => busy(13));
    R14: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(14), D_mem => data_d_mem_i, WE => WE(14), WE_mem => WE_mem(14), FREE_mem => FREE_mem(14), clk => clk, Q => Q(14), busy => busy(14));
    R15: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(15), D_mem => data_d_mem_i, WE => WE(15), WE_mem => WE_mem(15), FREE_mem => FREE_mem(15), clk => clk, Q => Q(15), busy => busy(15));
    R16: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(16), D_mem => data_d_mem_i, WE => WE(16), WE_mem => WE_mem(16), FREE_mem => FREE_mem(16), clk => clk, Q => Q(16), busy => busy(16));
    R17: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(17), D_mem => data_d_mem_i, WE => WE(17), WE_mem => WE_mem(17), FREE_mem => FREE_mem(17), clk => clk, Q => Q(17), busy => busy(17));
    R18: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(18), D_mem => data_d_mem_i, WE => WE(18), WE_mem => WE_mem(18), FREE_mem => FREE_mem(18), clk => clk, Q => Q(18), busy => busy(18));
    R19: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(19), D_mem => data_d_mem_i, WE => WE(19), WE_mem => WE_mem(19), FREE_mem => FREE_mem(19), clk => clk, Q => Q(19), busy => busy(19));
    R20: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(20), D_mem => data_d_mem_i, WE => WE(20), WE_mem => WE_mem(20), FREE_mem => FREE_mem(20), clk => clk, Q => Q(20), busy => busy(20));
    R21: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(21), D_mem => data_d_mem_i, WE => WE(21), WE_mem => WE_mem(21), FREE_mem => FREE_mem(21), clk => clk, Q => Q(21), busy => busy(21));
    R22: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(22), D_mem => data_d_mem_i, WE => WE(22), WE_mem => WE_mem(22), FREE_mem => FREE_mem(22), clk => clk, Q => Q(22), busy => busy(22));
    R23: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(23), D_mem => data_d_mem_i, WE => WE(23), WE_mem => WE_mem(23), FREE_mem => FREE_mem(23), clk => clk, Q => Q(23), busy => busy(23));
    R24: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(24), D_mem => data_d_mem_i, WE => WE(24), WE_mem => WE_mem(24), FREE_mem => FREE_mem(24), clk => clk, Q => Q(24), busy => busy(24));
    R25: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(25), D_mem => data_d_mem_i, WE => WE(25), WE_mem => WE_mem(25), FREE_mem => FREE_mem(25), clk => clk, Q => Q(25), busy => busy(25));
    R26: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(26), D_mem => data_d_mem_i, WE => WE(26), WE_mem => WE_mem(26), FREE_mem => FREE_mem(26), clk => clk, Q => Q(26), busy => busy(26));
    R27: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(27), D_mem => data_d_mem_i, WE => WE(27), WE_mem => WE_mem(27), FREE_mem => FREE_mem(27), clk => clk, Q => Q(27), busy => busy(27));
    R28: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(28), D_mem => data_d_mem_i, WE => WE(28), WE_mem => WE_mem(28), FREE_mem => FREE_mem(28), clk => clk, Q => Q(28), busy => busy(28));
    R29: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(29), D_mem => data_d_mem_i, WE => WE(29), WE_mem => WE_mem(29), FREE_mem => FREE_mem(29), clk => clk, Q => Q(29), busy => busy(29));
    R30: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(30), D_mem => data_d_mem_i, WE => WE(30), WE_mem => WE_mem(30), FREE_mem => FREE_mem(30), clk => clk, Q => Q(30), busy => busy(30));
    R31: sb_shiftregister generic map(n_bits=>n_bits) port map (rst => rst, D => D(31), D_mem => data_d_mem_i, WE => WE(31), WE_mem => WE_mem(31), FREE_mem => FREE_mem(31), clk => clk, Q => Q(31), busy => busy(31));

    -- hazard on one of each operand
    busy_a <= busy(my_conv_integer(addr_a_i));
    busy_b <= busy(my_conv_integer(addr_b_i));
    busy_d <= busy(my_conv_integer(addr_d_i));

    -- hazard signal when is detected on one of the operand registers or on the division or multiplication units
    hazard <= busy_a or busy_b or busy_d or busy_mul_ex or busy_div or busy_div_ex;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                s_q_mul <= (others => '0');
                busy_mul_ex <= '0';
                s_q_div <= (others => '0');
                busy_div <= '0';
                busy_div_ex <= '0';
            else
                if we_mul_i = '1' then
                    s_q_mul(5) <= '1';
                else
                    s_q_mul(5) <= '0';
                end if;
                if rst_mul_i = '1' then
                    s_q_mul(4) <= '0';
                else
                    s_q_mul(4) <= s_q_mul(5);
                end if;
                s_q_mul(3) <= s_q_mul(4);
                s_q_mul(2) <= s_q_mul(3);
                s_q_mul(1) <= s_q_mul(2);
                s_q_mul(0) <= s_q_mul(1);
                -- introduce a stall cycle to prevent collisions between the MUL and ALU values
                if s_q_mul(1) = '1' then
                    busy_mul_ex <= '1';
                else
                    busy_mul_ex <= '0';
                end if;

                if we_div_i = '1' then
                    s_q_div(29) <= '1';
                else
                    s_q_div(29) <= '0';
                end if;
                if rst_div_i = '1' then
                    s_q_div(28) <= '0';
                else
                    s_q_div(28) <= s_q_div(29);
                end if;
                s_q_div(27) <= s_q_div(28);
                s_q_div(26) <= s_q_div(27);
                s_q_div(25) <= s_q_div(26);
                s_q_div(24) <= s_q_div(25);
                s_q_div(23) <= s_q_div(24);
                s_q_div(22) <= s_q_div(23);
                s_q_div(21) <= s_q_div(22);
                s_q_div(20) <= s_q_div(21);
                s_q_div(19) <= s_q_div(20);
                s_q_div(18) <= s_q_div(19);
                s_q_div(17) <= s_q_div(18);
                s_q_div(16) <= s_q_div(17);
                s_q_div(15) <= s_q_div(16);
                s_q_div(14) <= s_q_div(15);
                s_q_div(13) <= s_q_div(14);
                s_q_div(12) <= s_q_div(13);
                s_q_div(11) <= s_q_div(12);
                s_q_div(10) <= s_q_div(11);
                s_q_div(9) <= s_q_div(10);
                s_q_div(8) <= s_q_div(9);
                s_q_div(7) <= s_q_div(8);
                s_q_div(6) <= s_q_div(7);
                s_q_div(5) <= s_q_div(6);
                s_q_div(4) <= s_q_div(5);
                s_q_div(3) <= s_q_div(4);
                s_q_div(2) <= s_q_div(3);
                s_q_div(1) <= s_q_div(2);
                s_q_div(0) <= s_q_div(1);
                -- when the divider has one result ready on the next clock cycle, the ID must stall to avoid structural hazards
                if s_q_div(1) = '1' then
                    busy_div_ex <= '1';
                else
                    busy_div_ex <= '0';
                end if;
                -- introduce a stall cycle to prevent structural hazards related with the multiplier latency
                if s_q_div(5) = '1' then
                    busy_div <= '1';
                else
                    busy_div <= '0';
                end if;
            end if;
        end if;
    end process;

end structural;
