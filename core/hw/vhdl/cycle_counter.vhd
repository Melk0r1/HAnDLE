----------------------------------------------------------------------------------------------
--
--      Input file         : cycle_counter.vhd
--      Design name        : cycle_counter
--      Author             : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--      Description        : 64-bit Cycle counter
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity cycle_counter is
    port (
        dat_o : out std_logic_vector(31 downto 0);
        adr_i : in std_logic_vector(31 downto 0);
        clk_i : in std_logic;
        rst_i : in std_logic;
        ena_i : in std_logic
    );
end cycle_counter;

architecture Behavioral of cycle_counter is
    signal counter  : std_logic_vector(63 downto 0);
    signal prev_adr : std_logic_vector(31 downto 0);

begin

    -- select the result part based on the address received in the past clock cycle
    dat_o <= counter(31 downto 0) when prev_adr(2) = '0' else
             counter(63 downto 32);

    process (clk_i) is
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                counter <= (others => '0');
            else
                if ena_i = '1' then
                    counter <= counter + 1;
                end if;
            end if;
            prev_adr <= adr_i;
        end if;
    end process;

end Behavioral;
