----------------------------------------------------------------------------------------------
--
--      Input file         : UART.vhd
--      Design name        : UART
--      Author             : João Rodrigues
--      Company            : Instituto Superior Técnico
--                         : University of Lisbon
--
--
--      Description        : UART main module
--
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity UART is
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
end UART;

architecture Behavioral of UART is
    component uart_fifo_tx_0
      port (
        clk         : in  std_logic;
        srst        : in  std_logic;
        din         : in  std_logic_vector(7 downto 0);
        wr_en       : in  std_logic;
        rd_en       : in  std_logic;
        dout        : out std_logic_vector(7 downto 0);
        full        : out std_logic;
        empty       : out std_logic;
        wr_rst_busy : out std_logic;
        rd_rst_busy : out std_logic
      );
    end component;

    component uart_fifo_rx_0
        port (
            clk         : in  std_logic;
            srst        : in  std_logic;
            din         : in  std_logic_vector(7 downto 0);
            wr_en       : in  std_logic;
            rd_en       : in  std_logic;
            dout        : out std_logic_vector(7 downto 0);
            full        : out std_logic;
            empty       : out std_logic;
            wr_rst_busy : out std_logic;
            rd_rst_busy : out std_logic
        );
    end component;

    component uart_tx is
        generic (
            g_CLKS_PER_BIT : integer := 868 -- Needs to be set correctly
        );
        port (
            i_clk       : in  std_logic;
            i_tx_dv     : in  std_logic;
            i_tx_byte   : in  std_logic_vector(7 downto 0);
            o_tx_active : out std_logic;
            o_tx_serial : out std_logic;
            o_tx_done   : out std_logic
        );
    end component uart_tx;

    component uart_rx is
        generic (
            g_CLKS_PER_BIT : integer := 868 -- Needs to be set correctly
        );
        port (
            i_clk       : in  std_logic;
            i_rx_serial : in  std_logic;
            o_rx_dv     : out std_logic;
            o_rx_byte   : out std_logic_vector(7 downto 0)
        );
    end component uart_rx;

    constant c_CLKS_PER_BIT : integer := 868; -- 100MHz/115200
    constant c_BIT_PERIOD   : time := 8680 ns;

    -- TX
    signal r_TX_DV   : std_logic := '0';
    signal r_TX_BYTE : std_logic_vector(7 downto 0) := (others => '0');
    signal w_TX_DONE : std_logic := '0';

    -- RX
    signal w_RX_DV   : std_logic := '0';
    signal w_RX_BYTE : std_logic_vector(7 downto 0) := (others => '0');

    -- TX FIFO signals
    signal fifo_tx_empty : std_logic := '0';
    signal fifo_tx_full  : std_logic := '0';
    signal fifo_tx_rd_en : std_logic := '0';

    -- RX FIFO signals
    signal fifo_rx_empty : std_logic := '0';

    -- Control
    type ctrl_state is (
        IDLE,
        READ_TX_FIFO,
        START_TX_1,
        START_TX_2,
        TX_DONE
    );
    signal state, next_state : ctrl_state := IDLE;

    signal s_byte_i,s_byte_o : std_logic_vector(7 downto 0) := (others => '0');

    signal rst : std_logic := '1';

    signal wr_en_i, rd_en_i : std_logic := '0';

    signal prev_adr : std_logic_vector(31 downto 0) := (others => '0');

begin
    rst <= not rst_n_i;

    s_byte_i <= dat_i(7 downto 0);

    wr_en_i <= '1' when ena_i = '1' and we_i = '1' and adr_i = X"FFFFFFFC" else
               '0';
    rd_en_i <= '1' when ena_i = '1' and we_i = '0' and adr_i = X"FFFFFFF8" else
               '0';

    -- select tje output value (byte, empyt, or full signals)
    dat_o <= X"0000000" & "000" & fifo_rx_empty when prev_adr = X"FFFFFFF0" else
             X"0000000" & "000" & fifo_tx_full when prev_adr = X"FFFFFFF4" else
             X"000000" & s_byte_o when prev_adr = X"FFFFFFF8" else
             (others => '0');

    uart_fifo_tx : uart_fifo_tx_0
    port map (
        clk         => clk_i,
        srst        => rst,
        din         => s_byte_i,
        wr_en       => wr_en_i,
        rd_en       => fifo_tx_rd_en,
        dout        => r_TX_BYTE,
        full        => fifo_tx_full,
        empty       => fifo_tx_empty,
        wr_rst_busy => open,
        rd_rst_busy => open
    );

    uart_fifo_rx : uart_fifo_rx_0
    port map (
        clk         => clk_i,
        srst        => rst,
        din         => w_RX_BYTE,
        wr_en       => w_RX_DV,
        rd_en       => rd_en_i,
        dout        => s_byte_o,
        full        => open,
        empty       => fifo_rx_empty,
        wr_rst_busy => open,
        rd_rst_busy => open
    );

    -- Instantiate UART transmitter
    UART_TX_INST : uart_tx
    generic map (
        g_CLKS_PER_BIT => c_CLKS_PER_BIT
    )
    port map (
        i_clk       => clk_i,
        i_tx_dv     => r_TX_DV,
        i_tx_byte   => r_TX_BYTE,
        o_tx_active => open,
        o_tx_serial => tx,
        o_tx_done   => w_TX_DONE
    );

    -- Instantiate UART Receiver
    UART_RX_INST : uart_rx
    generic map (
        g_CLKS_PER_BIT => c_CLKS_PER_BIT
    )
    port map (
        i_clk       => clk_i,
        i_rx_serial => rx,
        o_rx_dv     => w_RX_DV,
        o_rx_byte   => w_RX_BYTE
    );

    SEQ_PROC : process (clk_i)
    begin
        if (rising_edge(clk_i)) then
            state <= next_state;
            prev_adr <= adr_i;
        end if;
    end process;

    COMB_PROC : process(state, fifo_tx_empty, w_TX_DONE) is
    begin
        fifo_tx_rd_en <= '0';
        r_TX_DV   <= '0';

        case state is
            when IDLE =>
                if (fifo_tx_empty = '1') then
                    next_state <= IDLE;
                else
                    next_state <= READ_TX_FIFO;
                    fifo_tx_rd_en <= '1';
                end if;

            when READ_TX_FIFO =>
                next_state <= START_TX_1;

            when START_TX_1 =>
                next_state <= START_TX_2;
                r_TX_DV   <= '1';

            when START_TX_2 =>
                next_state <= TX_DONE;

            when TX_DONE =>
                if (w_TX_DONE = '1') then
                    next_state <= IDLE;
                else
                    next_state <= TX_DONE;
                end if;
        end case;
    end process;

end Behavioral;
