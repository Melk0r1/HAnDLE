----------------------------------------------------------------------------------------------
--
--      Input file         : mem_buffer.vhd
--      Design name        : mem_buffer
--      Author             : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--
--      Description        : Memory buffer
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.config_Pkg.all;
use work.core_Pkg.all;
use work.std_Pkg.all;

entity mem_buffer is
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
end mem_buffer;

architecture arch of mem_buffer is
    type buffer_type is array (0 to depth-1) of mem_in_type;
    signal s_buffer : buffer_type;
    signal buffer_reset : mem_in_type;

    signal write_ptr : natural range 0 to depth-1 := 0;
    signal read_ptr  : integer range 0 to depth-1 := 0;

    signal counter : integer range 0 to depth := 0;

    signal full, empty, stall : std_logic := '0';

begin
    buffer_reset.dat_d <= (others => '0');
    buffer_reset.alu_result <= (others => '0');
    buffer_reset.mem_result <= (others => '0');
    buffer_reset.ctrl_mem.mem_read <= '0';
    buffer_reset.ctrl_mem.mem_write <= '0';
    buffer_reset.ctrl_mem.transfer_size <= WORD;
    buffer_reset.ctrl_mem.sign_extended <= '0';
    buffer_reset.ctrl_wrb.reg_d <= (others => '0');
    buffer_reset.ctrl_wrb.reg_write <= '0';
    buffer_reset.end_execution <= '0';

    process (clk_i) is
    begin
        if (rising_edge(clk_i)) then
            if (rst_i = '1') then
                counter <= 0;
                write_ptr <= 0;
                read_ptr <= 0;
            else
                -- Keeps track of the total number of words in the FIFO
                if (wr_en_i = '1' and rd_en_i = '0') then
                    if (counter < depth) then
                        counter <= counter + 1;
                    end if;
                elsif (wr_en_i = '0' and rd_en_i = '1') then
                    if (counter > 0) then
                        counter <= counter - 1;
                    end if;
                end if;
                -- Keeps track of the write index (and controls roll-over)
                if (wr_en_i = '1' and full = '0') then
                    if write_ptr = depth-1 then
                        write_ptr <= 0;
                    else
                        write_ptr <= write_ptr + 1;
                    end if;
                end if;
                -- Keeps track of the read index (and controls roll-over)
                if (rd_en_i = '1' and empty = '0') then
                    if (read_ptr = depth-1) then
                        read_ptr <= 0;
                    else
                        read_ptr <= read_ptr + 1;
                    end if;
                end if;
                -- Registers the input data when there is a write
                if (wr_en_i) = '1' then
                    s_buffer(write_ptr) <= data_i;
                end if;
                if (counter >= depth-3) then
                    stall <= '1';
                else
                    stall <= '0';
                end if;
            end if;
        end if;
    end process;

    full  <= '1' when counter = depth else
             '0';
    empty <= '1' when counter = 0 else
             '0';

    data_o <= buffer_reset when empty = '1' else
              s_buffer(read_ptr);

    stall_o <= stall;

end arch;