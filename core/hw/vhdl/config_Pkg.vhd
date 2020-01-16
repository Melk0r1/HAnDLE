----------------------------------------------------------------------------------------------
--
--      Input file         : config_Pkg.vhd
--      Design name        : config_Pkg
--      Author             : Tamar Kranenburg
--      Modified by        : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--      Description        : Configuration parameters for the design
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package config_Pkg is

    ----------------------------------------------------------------------------------------------
    -- CORE PARAMETERS
    ----------------------------------------------------------------------------------------------
    -- Implement external interrupt
    constant CFG_INTERRUPT : boolean := true;      -- Disable or enable external interrupt [0,1]

     -- Implement hardware multiplier
    constant CFG_USE_HW_MUL : boolean := true;     -- Disable or enable multiplier [0,1]

     -- Implement hardware divider
    constant CFG_USE_HW_DIV : boolean := true;     -- Disable or enable divider [0,1]

    -- Implement hardware barrel shifter
    constant CFG_USE_BARREL : boolean := true;     -- Disable or enable barrel shifter [0,1]

    -- Debug mode
    constant CFG_DEBUG : boolean := true;          -- Resets some extra registers for better readability
                                                   -- and enables feedback (report) [0,1]
                                                   -- Set CFG_DEBUG to zero to obtain best performance.

    -- Memory parameters
    constant CFG_DMEM_SIZE  : positive := 32;      -- Data memory bus size in 2LOG # elements
    constant CFG_IMEM_SIZE  : positive := 16;      -- Instruction memory bus size in 2LOG # elements
    constant CFG_BYTE_ORDER : boolean := true;     -- Switch between MSB (1, default) and LSB (0) byte order policy

    --constant CFG_MEM_BUFFER_DEPTH : positive := 4;

    -- Register parameters
    constant CFG_REG_FORCE_ZERO : boolean := true; -- Force data to zero if register address is zero [0,1]
    constant CFG_REG_FWD_WRB    : boolean := true; -- Forward writeback to loosen register memory requirements [0,1]
    constant CFG_MEM_FWD_WRB    : boolean := false; -- Forward memory result in stead of introducing stalls [0,1]

    ----------------------------------------------------------------------------------------------
    -- CONSTANTS (currently not configurable / not tested)
    ----------------------------------------------------------------------------------------------
    constant CFG_DMEM_WIDTH : positive := 32;   -- Data memory width in bits
    constant CFG_IMEM_WIDTH : positive := 32;   -- Instruction memory width in bits
    constant CFG_GPRF_SIZE  : positive :=  5;   -- General Purpose Register File Size in 2LOG # elements

    ----------------------------------------------------------------------------------------------
    -- BUS PARAMETERS
    ----------------------------------------------------------------------------------------------

    type memory_map_type is array(natural range <>) of std_logic_vector(CFG_DMEM_WIDTH - 1 downto 0);
    constant CFG_NUM_SLAVES : positive := 4;
    constant CFG_MEMORY_MAP : memory_map_type(0 to CFG_NUM_SLAVES) := (X"00000000", X"FFFFFF00", X"FFFFFF80", X"FFFFFFF0", X"FFFFFFFF");

    -- Data memory, Counter, RX/TX

end config_Pkg;
