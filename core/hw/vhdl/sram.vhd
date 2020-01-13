----------------------------------------------------------------------------------------------
--
--      Input file         : sram.vhd
--      Design name        : sram
--      Author             : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--
--      Description        : True Dual-port BRAM
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.std_Pkg.all;

entity sram is
    generic (
        WIDTH : positive := 32;
        SIZE  : positive := 16
    );
    port (
        dat_o     : out std_logic_vector(31 downto 0);
        dat_o_pci : out std_logic_vector(WIDTH - 1 downto 0);
        dat_i     : in  std_logic_vector(31 downto 0);
        dat_i_pci : in  std_logic_vector(WIDTH - 1 downto 0);
        adr_i     : in  std_logic_vector(SIZE - 1 downto 0);
        adr_i_pci : in  std_logic_vector(8 downto 0);
        wre_i     : in  std_logic;
        wre_i_pci : in  std_logic;
        ena_i     : in  std_logic;
        ena_i_pci : in  std_logic;
        clk_i     : in  std_logic;
        clk_i_pci : in  std_logic
    );
end sram;

architecture arch of sram is
    component blk_mem_gen_0
        port (
            clka  : in  c;
            ena   : in  std_logic;
            wea   : in  std_logic_vector(0 downto 0);
            addra : in  std_logic_vector(8 downto 0);
            dina  : in  std_logic_vector(255 downto 0);
            douta : out std_logic_vector(255 downto 0);
            clkb  : in  std_logic;
            enb   : in  std_logic;
            web   : in  std_logic_vector(0 downto 0);
            addrb : in  std_logic_vector(11 downto 0);
            dinb  : in  std_logic_vector(31 downto 0);
            doutb : out std_logic_vector(31 downto 0)
        );
    end component;

begin
    blk_imem_o : blk_mem_gen_0
    port map (
        clka   => clk_i_pci,
        ena    => ena_i_pci,
        wea(0) => wre_i_pci,
        addra  => adr_i_pci,
        dina   => dat_i_pci,
        douta  => dat_o_pci,
        clkb   => clk_i,
        enb    => ena_i,
        web(0) => wre_i,
        addrb  => adr_i,
        dinb   => dat_i,
        doutb  => dat_o
    );

end arch;
