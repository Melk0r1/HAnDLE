----------------------------------------------------------------------------------------------
--
--      Input file         : RISCV_IP_CORE_v1_0.vhd
--      Design name        : RISCV_IP_CORE_v1_0
--      Author             : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--
--      Description        : Core IP top file
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RISCV_IP_CORE_v1_0 is
    generic (
        C_S00_AXI_ID_WIDTH   : integer := 4;
        C_S00_AXI_DATA_WIDTH : integer := 256;
        C_S00_AXI_ADDR_WIDTH : integer := 32;
        C_S00_AXI_AWUSER_WIDTH : integer := 1;
        C_S00_AXI_ARUSER_WIDTH : integer := 1;
        C_S00_AXI_WUSER_WIDTH  : integer := 1;
        C_S00_AXI_RUSER_WIDTH  : integer := 1;
        C_S00_AXI_BUSER_WIDTH  : integer := 1
    );
    port (
        -- Instruction Memory AXI Slave
        s00_axi_aclk    : in  std_logic;
        s00_axi_aresetn : in  std_logic;
        s00_axi_awid    : in  std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);
        s00_axi_awaddr  : in  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        s00_axi_awlen   : in  std_logic_vector(7 downto 0);
        s00_axi_awsize  : in  std_logic_vector(2 downto 0);
        s00_axi_awburst : in  std_logic_vector(1 downto 0);
        s00_axi_awuser  : in  std_logic_vector(C_S00_AXI_AWUSER_WIDTH-1 downto 0);
        s00_axi_awvalid : in  std_logic;
        s00_axi_awready : out std_logic;
        s00_axi_wdata   : in  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        s00_axi_wstrb   : in  std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
        s00_axi_wlast   : in  std_logic;
        s00_axi_wuser   : in  std_logic_vector(C_S00_AXI_WUSER_WIDTH-1 downto 0);
        s00_axi_wvalid  : in  std_logic;
        s00_axi_wready  : out std_logic;
        s00_axi_bid     : out std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);
        s00_axi_bresp   : out std_logic_vector(1 downto 0);
        s00_axi_buser   : out std_logic_vector(C_S00_AXI_BUSER_WIDTH-1 downto 0);
        s00_axi_bvalid  : out std_logic;
        s00_axi_bready  : in  std_logic;
        s00_axi_arid    : in  std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);
        s00_axi_araddr  : in  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        s00_axi_arlen   : in  std_logic_vector(7 downto 0);
        s00_axi_arsize  : in  std_logic_vector(2 downto 0);
        s00_axi_arburst : in  std_logic_vector(1 downto 0);
        s00_axi_aruser  : in  std_logic_vector(C_S00_AXI_ARUSER_WIDTH-1 downto 0);
        s00_axi_arvalid : in  std_logic;
        s00_axi_arready : out std_logic;
        s00_axi_rid     : out std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);
        s00_axi_rdata   : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        s00_axi_rresp   : out std_logic_vector(1 downto 0);
        s00_axi_rlast   : out std_logic;
        s00_axi_ruser   : out std_logic_vector(C_S00_AXI_RUSER_WIDTH-1 downto 0);
        s00_axi_rvalid  : out std_logic;
        s00_axi_rready  : in  std_logic;

        -- Core Signals
        CORE_CLK        : in  std_logic;
        RX              : in  std_logic;
        TX              : out std_logic;

        -- Data Cache Signals
        dat_i           : in  std_logic_vector(31 downto 0);
        ena_i           : in  std_logic;
        dat_o           : out std_logic_vector(31 downto 0);
        adr_o           : out std_logic_vector(31 downto 0);
        we_o            : out std_logic;
        sel_o           : out std_logic_vector(3 downto 0);
        clk_o           : out std_logic;
        ena_o           : out std_logic;
        rst_o           : out std_logic
    );
end RISCV_IP_CORE_v1_0;

architecture Behavioral of RISCV_IP_CORE_v1_0 is
    -- component declaration
    component core_top is
        generic (
            C_S_AXI_ID_WIDTH   : integer := 4;
            C_S_AXI_DATA_WIDTH : integer := 256;
            C_S_AXI_ADDR_WIDTH : integer := 32
        );
        port (
            -- Instruction Memory AXI Slave
            S_AXI_ACLK    : in  std_logic;
            S_AXI_ARESETN : in  std_logic;
            S_AXI_AWID    : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
            S_AXI_AWADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            S_AXI_AWLEN   : in  std_logic_vector(7 downto 0);
            S_AXI_AWSIZE  : in  std_logic_vector(2 downto 0);
            S_AXI_AWBURST : in  std_logic_vector(1 downto 0);
            S_AXI_AWVALID : in  std_logic;
            S_AXI_AWREADY : out std_logic;
            S_AXI_WDATA   : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_WSTRB   : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
            S_AXI_WLAST   : in  std_logic;
            S_AXI_WVALID  : in  std_logic;
            S_AXI_WREADY  : out std_logic;
            S_AXI_BID     : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
            S_AXI_BRESP   : out std_logic_vector(1 downto 0);
            S_AXI_BVALID  : out std_logic;
            S_AXI_BREADY  : in  std_logic;
            S_AXI_ARID    : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
            S_AXI_ARADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            S_AXI_ARLEN   : in  std_logic_vector(7 downto 0);
            S_AXI_ARSIZE  : in  std_logic_vector(2 downto 0);
            S_AXI_ARBURST : in  std_logic_vector(1 downto 0);
            S_AXI_ARVALID : in  std_logic;
            S_AXI_ARREADY : out std_logic;
            S_AXI_RID     : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
            S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_RRESP   : out std_logic_vector(1 downto 0);
            S_AXI_RLAST   : out std_logic;
            S_AXI_RVALID  : out std_logic;
            S_AXI_RREADY  : in  std_logic;

            -- Core Signals
            CORE_CLK      : in  std_logic;
            RX            : in  std_logic;
            TX            : out std_logic;

            -- Data Cache Signals
            dat_i         : in  std_logic_vector(31 downto 0);
            ena_i         : in  std_logic;
            dat_o         : out std_logic_vector(31 downto 0);
            adr_o         : out std_logic_vector(31 downto 0);
            we_o          : out std_logic;
            sel_o         : out std_logic_vector(3 downto 0);
            clk_o         : out std_logic;
            ena_o         : out std_logic;
            rst_o         : out std_logic
        );
    end component core_top;

begin

s00_axi_buser <= (others => '0');
s00_axi_ruser <= (others => '0');

-- Instantiation of Axi Bus Interface S00_AXI
core_top_inst : core_top
    generic map (
        C_S_AXI_ID_WIDTH     => C_S00_AXI_ID_WIDTH,
        C_S_AXI_DATA_WIDTH   => C_S00_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH   => C_S00_AXI_ADDR_WIDTH
    )
    port map (
        -- Instruction Memory AXI Slave
        S_AXI_ACLK    => s00_axi_aclk,
        S_AXI_ARESETN => s00_axi_aresetn,
        S_AXI_AWID    => s00_axi_awid,
        S_AXI_AWADDR  => s00_axi_awaddr,
        S_AXI_AWLEN   => s00_axi_awlen,
        S_AXI_AWSIZE  => s00_axi_awsize,
        S_AXI_AWBURST => s00_axi_awburst,
        S_AXI_AWVALID => s00_axi_awvalid,
        S_AXI_AWREADY => s00_axi_awready,
        S_AXI_WDATA   => s00_axi_wdata,
        S_AXI_WSTRB   => s00_axi_wstrb,
        S_AXI_WLAST   => s00_axi_wlast,
        S_AXI_WVALID  => s00_axi_wvalid,
        S_AXI_WREADY  => s00_axi_wready,
        S_AXI_BID     => s00_axi_bid,
        S_AXI_BRESP   => s00_axi_bresp,
        S_AXI_BVALID  => s00_axi_bvalid,
        S_AXI_BREADY  => s00_axi_bready,
        S_AXI_ARID    => s00_axi_arid,
        S_AXI_ARADDR  => s00_axi_araddr,
        S_AXI_ARLEN   => s00_axi_arlen,
        S_AXI_ARSIZE  => s00_axi_arsize,
        S_AXI_ARBURST => s00_axi_arburst,
        S_AXI_ARVALID => s00_axi_arvalid,
        S_AXI_ARREADY => s00_axi_arready,
        S_AXI_RID     => s00_axi_rid,
        S_AXI_RDATA   => s00_axi_rdata,
        S_AXI_RRESP   => s00_axi_rresp,
        S_AXI_RLAST   => s00_axi_rlast,
        S_AXI_RVALID  => s00_axi_rvalid,
        S_AXI_RREADY  => s00_axi_rready,

        -- Core Signals
        CORE_CLK      => CORE_CLK,
        RX            => RX,
        TX            => TX,

        -- Data Cache Signals
        dat_i         => dat_i,
        ena_i         => ena_i,
        dat_o         => dat_o,
        adr_o         => adr_o,
        we_o          => we_o,
        sel_o         => sel_o,
        clk_o         => clk_o,
        ena_o         => ena_o,
        rst_o         => rst_o
    );

end Behavioral;
