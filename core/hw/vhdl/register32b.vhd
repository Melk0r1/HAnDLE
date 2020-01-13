----------------------------------------------------------------------------------------------
--
--      Input file         : register32b.vhd
--      Design name        : register32b
--      Author             : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--
--      Description        : 32-bit register
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.std_Pkg.all;

entity register32b is
    generic (
        WIDTH : positive := 32
    );
    port (
        clk_i       : in  std_logic;
        ena_i       : in  std_logic;
        dat_w_mem_i : in  std_logic_vector(WIDTH - 1 downto 0);
        wre_mem_i   : in  std_logic;
        dat_w_ex_i  : in  std_logic_vector(WIDTH - 1 downto 0);
        wre_ex_i    : in  std_logic;
        dat_o       : out std_logic_vector(WIDTH - 1 downto 0) := (others => '0')
    );
end register32b;

architecture arch of register32b is
    begin
        process(clk_i)
        begin
            if rising_edge(clk_i) then
                if ena_i = '1' then
                    if wre_mem_i = '1' then
                        dat_o <= dat_w_mem_i;
                    elsif wre_ex_i = '1' then
                        dat_o <= dat_w_ex_i;
                    end if;
                end if;
            end if;
        end process;

end arch;
