----------------------------------------------------------------------------------------------
--
--      Input file         : core_top.vhd
--      Design name        : core_top
--      Author             : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--      Description        : Core top module
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;

use work.config_Pkg.all;
use work.core_Pkg.all;
use work.std_Pkg.all;

entity core_top is
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
end core_top;

architecture Behavioral of core_top is
    component axi_bram_ctrl_0
        port (
            s_axi_aclk    : in  std_logic;
			s_axi_aresetn : in  std_logic;
			s_axi_awid    : in  std_logic_vector(3 downto 0);
			s_axi_awaddr  : in  std_logic_vector(14 downto 0);
			s_axi_awlen   : in  std_logic_vector(7 downto 0);
			s_axi_awsize  : in  std_logic_vector(2 downto 0);
			s_axi_awburst : in  std_logic_vector(1 downto 0);
			s_axi_awlock  : in  std_logic;
			s_axi_awcache : in  std_logic_vector(3 downto 0);
			s_axi_awprot  : in  std_logic_vector(2 downto 0);
			s_axi_awvalid : in  std_logic;
			s_axi_awready : out std_logic;
			s_axi_wdata   : in  std_logic_vector(255 downto 0);
			s_axi_wstrb   : in  std_logic_vector(31 downto 0);
			s_axi_wlast   : in  std_logic;
			s_axi_wvalid  : in  std_logic;
			s_axi_wready  : out std_logic;
			s_axi_bid     : out std_logic_vector(3 downto 0);
			s_axi_bresp   : out std_logic_vector(1 downto 0);
			s_axi_bvalid  : out std_logic;
			s_axi_bready  : in  std_logic;
			s_axi_arid    : in  std_logic_vector(3 downto 0);
			s_axi_araddr  : in  std_logic_vector(14 downto 0);
			s_axi_arlen   : in  std_logic_vector(7 downto 0);
			s_axi_arsize  : in  std_logic_vector(2 downto 0);
			s_axi_arburst : in  std_logic_vector(1 downto 0);
			s_axi_arlock  : in  std_logic;
			s_axi_arcache : in  std_logic_vector(3 downto 0);
			s_axi_arprot  : in  std_logic_vector(2 downto 0);
			s_axi_arvalid : in  std_logic;
			s_axi_arready : out std_logic;
			s_axi_rid     : out std_logic_vector(3 downto 0);
			s_axi_rdata   : out std_logic_vector(255 downto 0);
			s_axi_rresp   : out std_logic_vector(1 downto 0);
			s_axi_rlast   : out std_logic;
			s_axi_rvalid  : out std_logic;
			s_axi_rready  : in  std_logic;
			bram_rst_a    : out std_logic;
			bram_clk_a    : out std_logic;
			bram_en_a     : out std_logic;
			bram_we_a     : out std_logic_vector(31 downto 0);
			bram_addr_a   : out std_logic_vector(14 downto 0);
			bram_wrdata_a : out std_logic_vector(255 downto 0);
			bram_rddata_a : in  std_logic_vector(255 downto 0)
		);
	end component;

    component UART is
        port (
            dat_o   : out std_logic_vector(31 downto 0);
            dat_i   : in  std_logic_vector(31 downto 0);
            adr_i   : in  std_logic_vector(31 downto 0);
            we_i    : in  std_logic;
            clk_i   : in  std_logic;
            ena_i   : in  std_logic;
            rst_n_i : in  std_logic;
            rx      : in  std_logic;
            tx      : out std_logic
        );
    end component;

    component cycle_counter is
        port (
            dat_o : out std_logic_vector(31 downto 0);
            adr_i : in  std_logic_vector(31 downto 0);
            clk_i : in  std_logic;
            rst_i : in  std_logic;
            ena_i : in  std_logic
        );
    end component;

    -- BRAM_CTRL
    signal bram_rst_a    : std_logic;
    signal bram_clk_a    : std_logic;
    signal bram_en_a     : std_logic;
    signal bram_we_a     : std_logic_vector(31 downto 0);
    signal bram_addr_a   : std_logic_vector(14 downto 0);
    signal bram_wrdata_a : std_logic_vector(255 downto 0);
    signal bram_rddata_a : std_logic_vector(255 downto 0);
    signal bram_axi_awaddr, bram_axi_araddr : std_logic_vector(14 downto 0);
    signal imem_o_pci : std_logic_vector(255 downto 0);

    -- Core
    signal dmem_o : dmem_out_type;
    signal imem_o : imem_out_type;
    signal dmem_i : dmem_in_type;
    signal imem_i : imem_in_type;

    signal s_dmem_o : dmem_out_array_type(CFG_NUM_SLAVES - 1 downto 0);
    signal s_dmem_i : dmem_in_array_type(CFG_NUM_SLAVES - 1 downto 0);

    signal sys_clk_i : std_logic;
    signal sys_int_i : std_logic;
    signal sys_rst_i : std_logic;
    signal sys_ena_i : std_logic;

    constant rom_size : integer := 14;
    constant ram_size : integer := 14;

    -- Control
    type ctrl_state is (
        IDLE,
        EX
    );
    signal state, next_state : ctrl_state := IDLE;
    signal end_execution : std_logic;

    -- PCIe
    signal s_adr_i_imem_pci : std_logic_vector(8 downto 0);
    signal s_adr_i_dmem_pci : std_logic_vector(8 downto 0);

begin
    -- Core
    sys_clk_i <= CORE_CLK;
    sys_int_i <= '0';

    -- BRAM connections
    s_adr_i_imem_pci <= bram_addr_a(13 downto 5);
    s_adr_i_dmem_pci <= bram_addr_a(13 downto 5);
    bram_rddata_a <= imem_o_pci;
    wr_en_pci_imem_i <= (not bram_addr_a(14)) and bram_we_a(0);
    bram_axi_awaddr <= S_AXI_AWADDR(14 downto 0);
    bram_axi_araddr <= S_AXI_ARADDR(14 downto 0);

    -- 1 cycle latency peripherals 'hit'
    s_dmem_i(1).ena_i <= '1'; -- counter
    s_dmem_i(3).ena_i <= '1'; -- UART

    -- Data Cache
    s_dmem_i(0).dat_i <= dat_i;
    s_dmem_i(0).ena_i <= ena_i;
    dat_o <= s_dmem_o(0).dat_o;
    adr_o <= "000000000000000000" & s_dmem_o(0).adr_o(13 downto 0);
    we_o <= s_dmem_o(0).we_o;
    sel_o <= s_dmem_o(0).sel_o;
    clk_o <= sys_clk_i;
    ena_o <= (not sys_rst_i and s_dmem_o(0).ena_o);
    rst_o <= sys_rst_i;

    axi_bram_ctrl : axi_bram_ctrl_0
    port map (
		s_axi_aclk    => S_AXI_ACLK,
		s_axi_aresetn => S_AXI_ARESETN,
		s_axi_awid    => S_AXI_AWID,
		s_axi_awaddr  => bram_axi_awaddr,
		s_axi_awlen   => S_AXI_AWLEN,
		s_axi_awsize  => S_AXI_AWSIZE,
		s_axi_awburst => S_AXI_AWBURST,
		s_axi_awlock  => '0',
		s_axi_awcache => (others => '0'),
		s_axi_awprot  => (others => '0'),
		s_axi_awvalid => S_AXI_AWVALID,
		s_axi_awready => S_AXI_AWREADY,
		s_axi_wdata   => S_AXI_WDATA,
		s_axi_wstrb   => S_AXI_WSTRB,
		s_axi_wlast   => S_AXI_WLAST,
		s_axi_wvalid  => S_AXI_WVALID,
		s_axi_wready  => S_AXI_WREADY,
		s_axi_bid     => S_AXI_BID,
		s_axi_bresp   => S_AXI_BRESP,
		s_axi_bvalid  => S_AXI_BVALID,
		s_axi_bready  => S_AXI_BREADY,
		s_axi_arid    => S_AXI_ARID,
		s_axi_araddr  => bram_axi_araddr,
		s_axi_arlen   => S_AXI_ARLEN,
		s_axi_arsize  => S_AXI_ARSIZE,
		s_axi_arburst => S_AXI_ARBURST,
		s_axi_arlock  => '0',
		s_axi_arcache => (others => '0'),
		s_axi_arprot  => (others => '0'),
		s_axi_arvalid => S_AXI_ARVALID,
		s_axi_arready => S_AXI_ARREADY,
		s_axi_rid     => S_AXI_RID,
		s_axi_rdata   => S_AXI_RDATA,
		s_axi_rresp   => S_AXI_RRESP,
		s_axi_rlast   => S_AXI_RLAST,
		s_axi_rvalid  => S_AXI_RVALID,
		s_axi_rready  => S_AXI_RREADY,
		bram_rst_a    => bram_rst_a,
		bram_clk_a    => bram_clk_a,
		bram_en_a     => bram_en_a,
		bram_we_a     => bram_we_a,
		bram_addr_a   => bram_addr_a,
		bram_wrdata_a => bram_wrdata_a,
		bram_rddata_a => bram_rddata_a
    );

    imem : sram
    generic map (
        WIDTH => 256,
        SIZE  => rom_size - 2
    )
    port map (
        dat_o     => imem_i.dat_i,
        dat_o_pci => imem_o_pci,
        dat_i     => (others = >'0'),
        dat_i_pci => bram_wrdata_a,
        adr_i     => imem_o.adr_o(rom_size - 1 downto 2),
        adr_i_pci => s_adr_i_imem_pci,
        wre_i     => '0',
        wre_i_pci => wr_en_pci_imem_i,
        ena_i     => imem_o.ena_o,
        ena_i_pci => bram_en_a,
        clk_i     => sys_clk_i,
        clk_i_pci => bram_clk_a
    );

    decoder : core_address_decoder
    generic map (
        G_NUM_SLAVES => CFG_NUM_SLAVES
    )
    port map (
        m_dmem_i => dmem_i,
        s_dmem_o => s_dmem_o,
        m_dmem_o => dmem_o,
        s_dmem_i => s_dmem_i,
        clk_i    => sys_clk_i
    );

    core0 : core
    port map (
        imem_o => imem_o,
        dmem_o => dmem_o,
        imem_i => imem_i,
        dmem_i => dmem_i,
        int_i  => sys_int_i,
        rst_i  => sys_rst_i,
        clk_i  => sys_clk_i,
        ena_i  => sys_ena_i,
        end_execution => end_execution
    );

    uart0 : UART
    port map (
        dat_o   => s_dmem_i(3).dat_i,
        dat_i   => s_dmem_o(3).dat_o,
        adr_i   => s_dmem_o(3).adr_o,
        we_i    => s_dmem_o(3).we_o,
        clk_i   => sys_clk_i,
        ena_i   => s_dmem_o(3).ena_o,
        rst_n_i => S_AXI_ARESETN,
        rx      => RX,
        tx      => TX
    );

    cycle_counter_o : cycle_counter
    port map (
        dat_o => s_dmem_i(1).dat_i,
        adr_i => s_dmem_o(1).adr_o,
        clk_i => sys_clk_i,
        rst_i => sys_rst_i,
        ena_i => sys_ena_i
    );

    SEQ_PROC : process (S_AXI_ACLK)
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                state <= IDLE;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    COMB_PROC : process(state, end_execution, s_axi_wlast) is
    begin
        sys_rst_i <= '1';
        sys_ena_i <= '0';
        case state is
            when IDLE =>
                if (s_axi_wlast = '1') then
                    next_state <= EX;
                    sys_ena_i <= '1';
                    sys_rst_i <= '0';
                else
                    next_state <= IDLE;
                end if;
            when EX =>
                if (end_execution = '1') then
                    next_state <= IDLE;
                else
                    next_state <= EX;
                    sys_ena_i <= '1';
                    sys_rst_i <= '0';
                end if;
        end case;
    end process;

end Behavioral;
