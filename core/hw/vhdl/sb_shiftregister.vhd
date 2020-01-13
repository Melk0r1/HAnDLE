----------------------------------------------------------------------------------------------
--
--      Input file         : sb_shiftregister.vhd
--      Design name        : sb_shiftregister
--      Author             : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--
--      Description        : Shift register
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.std_Pkg.all;

entity sb_shiftregister is
    generic (
        n_bits : natural := 32
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
end sb_shiftregister;

architecture structural of sb_shiftregister is
    signal s_q : std_logic_vector(n_bits - 1 downto 0);
    signal s_busy, s_busy_mem: std_logic;

begin
    busy <= s_busy or s_busy_mem;
    Q <= s_q;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                s_busy <= '0';
                s_busy_mem <= '0';
                s_q <= (others => '1');
            else
                if WE_mem = '1' then
                    s_busy_mem <= D_mem;
                end if;
                if FREE_mem = '1' then
                    s_busy_mem <= '0';
                end if;
                if WE = '1' and s_busy = '0' then
                    s_q <= '0' & D(31 downto 1);
                    s_busy <= '1';
                else
                    s_q(31) <= '0';
                    s_q(30) <= s_q(31);
                    s_q(29) <= s_q(30);
                    s_q(28) <= s_q(29);
                    s_q(27) <= s_q(28);
                    s_q(26) <= s_q(27);
                    s_q(25) <= s_q(26);
                    s_q(24) <= s_q(25);
                    s_q(23) <= s_q(24);
                    s_q(22) <= s_q(23);
                    s_q(21) <= s_q(22);
                    s_q(20) <= s_q(21);
                    s_q(19) <= s_q(20);
                    s_q(18) <= s_q(19);
                    s_q(17) <= s_q(18);
                    s_q(16) <= s_q(17);
                    s_q(15) <= s_q(16);
                    s_q(14) <= s_q(15);
                    s_q(13) <= s_q(14);
                    s_q(12) <= s_q(13);
                    s_q(11) <= s_q(12);
                    s_q(10) <= s_q(11);
                    s_q(9)  <= s_q(10);
                    s_q(8)  <= s_q(9);
                    s_q(7)  <= s_q(8);
                    s_q(6)  <= s_q(7);
                    s_q(5)  <= s_q(6);
                    s_q(4)  <= s_q(5);
                    s_q(3)  <= s_q(4);
                    s_q(2)  <= s_q(3);
                    s_q(1)  <= s_q(2);
                    s_q(0)  <= s_q(1);
                    if s_q(1) = '1' then
                        s_busy <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

end structural;
