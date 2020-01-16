# Core structure

- **Top module** - core_top.vhd
  - **AXI BRAM Controller IP** - axi_bram_ctrl_0.xci
  - **Instruction Memory** - sram.vhd
    - **BRAM Generator IP** - blk_mem_gen_0.xci
  - **Data Bus Address Decoder** - core_address_decoder.vhd
  - **Core** - core.vhd
    - **Instruction Fetch Stage (IF)** - fetch.vhd
    - **Instruction Decode Stage (ID)** - decode.vhd
      - **Dependency Handler Unit** - scoreboard.vhd
        - **Decoder** - Decoder.vhd
        - **Shift Register** - sb_shiftregister.vhd
      - **Register File** - gprf.vhd
        - **32-bit Register** - register32b.vhd
    - **Execution Stage (EX)** - execute.vhd
      - **Multiplier Unit** - multiplier_unit.vhd
        - **Multiplier IP** - multiplier.xci
      - **Divider Unit** - divider_unit.vhd
        - **Divider IP** - divider_0.xci
      - **Memory Stage (MEM)** - mem.vhd
        - **Memory Buffer** - mem_buffer.vhd
  - **UART Module** - UART.vhd
    - **UART FIFO TX IP** - uart_fifo_tx_0.xci
    - **UART FIFO RX IP** - uart_fifo_rx_0.xci
    - **UART TX Module** - UART_TX.vhd
    - **UART RX Module** - UART_RX.vhd
  - **Cycle Counter/Timer** - cycle_counter.vhd

#### Files structure
```
RISCV_IP_CORE
 \_ config_Pkg.vhd
 \_ std_Pkg.vhd
 \_ core_Pkg.vhd
 \_ core_top.vhd
     \_ axi_bram_ctrl_0.xci
     \_ sram.vhd
     |   \_ blk_mem_gen_0.xci
     \_ core_address_decoder.vhd
     \_ core.vhd
     |   \_ fetch.vhd
     |   \_ decode.vhd
     |   |   \_ scoreboard.vhd
     |   |   |   \_ Decoder.vhd
     |   |   |   \_ sb_shiftregister.vhd
     |   |   \_ gprf.vhd
     |   |       \_ register32b.vhd
     |   \_ execute.vhd
     |   |   \_ multiplier_unit.vhd
     |   |   |   \_ multiplier.xci
     |   |   \_ divider_unit.vhd
     |   |       \_ divider_0.xci
     |   \_ mem.vhd
     |       \_ mem_buffer.vhd
     \_ UART.vhd
     |   \_ uart_fifo_tx_0.xci
     |   \_ uart_fifo_rx_0.xci
     |   \_ UART_TX.vhd
     |   \_ UART_RX.vhd
     \_ cycle_counter.vhd
```

## Xilinx Vivado IPs configuration

### axi_bram_ctrl_0

TODO

### blk_mem_gen_0

TODO

### multiplier

TODO

### divider_0

TODO

### uart_fifo_tx_0

TODO

### uart_fifo_rx_0

TODO

