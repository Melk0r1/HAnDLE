----------------------------------------------------------------------------------------------
--
--      Input file         : Decoder.vhd
--      Design name        : Decoder
--      Author             : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--      Description        : 32-bit decoder
--
----------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Decoder is
    port(
        A : in  std_logic_vector(4 downto 0);
        D : out std_logic_vector(31 downto 0)
    );
end Decoder;

architecture Behavioral of Decoder is
begin
    D(0)  <= not A(4) and not A(3) and not A(2) and not A(1) and not A(0);
    D(1)  <= not A(4) and not A(3) and not A(2) and not A(1) and     A(0);
    D(2)  <= not A(4) and not A(3) and not A(2) and     A(1) and not A(0);
    D(3)  <= not A(4) and not A(3) and not A(2) and     A(1) and     A(0);
    D(4)  <= not A(4) and not A(3) and     A(2) and not A(1) and not A(0);
    D(5)  <= not A(4) and not A(3) and     A(2) and not A(1) and     A(0);
    D(6)  <= not A(4) and not A(3) and     A(2) and     A(1) and not A(0);
    D(7)  <= not A(4) and not A(3) and     A(2) and     A(1) and     A(0);
    D(8)  <= not A(4) and     A(3) and not A(2) and not A(1) and not A(0);
    D(9)  <= not A(4) and     A(3) and not A(2) and not A(1) and     A(0);
    D(10) <= not A(4) and     A(3) and not A(2) and     A(1) and not A(0);
    D(11) <= not A(4) and     A(3) and not A(2) and     A(1) and     A(0);
    D(12) <= not A(4) and     A(3) and     A(2) and not A(1) and not A(0);
    D(13) <= not A(4) and     A(3) and     A(2) and not A(1) and     A(0);
    D(14) <= not A(4) and     A(3) and     A(2) and     A(1) and not A(0);
    D(15) <= not A(4) and     A(3) and     A(2) and     A(1) and     A(0);
    D(16) <=     A(4) and not A(3) and not A(2) and not A(1) and not A(0);
    D(17) <=     A(4) and not A(3) and not A(2) and not A(1) and     A(0);
    D(18) <=     A(4) and not A(3) and not A(2) and     A(1) and not A(0);
    D(19) <=     A(4) and not A(3) and not A(2) and     A(1) and     A(0);
    D(20) <=     A(4) and not A(3) and     A(2) and not A(1) and not A(0);
    D(21) <=     A(4) and not A(3) and     A(2) and not A(1) and     A(0);
    D(22) <=     A(4) and not A(3) and     A(2) and     A(1) and not A(0);
    D(23) <=     A(4) and not A(3) and     A(2) and     A(1) and     A(0);
    D(24) <=     A(4) and     A(3) and not A(2) and not A(1) and not A(0);
    D(25) <=     A(4) and     A(3) and not A(2) and not A(1) and     A(0);
    D(26) <=     A(4) and     A(3) and not A(2) and     A(1) and not A(0);
    D(27) <=     A(4) and     A(3) and not A(2) and     A(1) and     A(0);
    D(28) <=     A(4) and     A(3) and     A(2) and not A(1) and not A(0);
    D(29) <=     A(4) and     A(3) and     A(2) and not A(1) and     A(0);
    D(30) <=     A(4) and     A(3) and     A(2) and     A(1) and not A(0);
    D(31) <=     A(4) and     A(3) and     A(2) and     A(1) and     A(0);

end Behavioral;
