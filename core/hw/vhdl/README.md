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

# Xilinx Vivado IPs configuration

## axi_bram_ctrl_0 (AXI BRAM Controller)

 - **AXI Protocol:** AXI4
 - **Data Width:** 256
 - **Memory Depth:** 1024
 - **ID Width:** 4
 - **Support AXI Narrow Bursts:** Yes
 - **Read Latency:** 1
 - **Read Command Optimization:** No
 - **BRAM Instance:** External
 - **Number of BRAM interfaces:** 1

## blk_mem_gen_0 (Block Memory Generator)

### Basic:

 - **Interface Type:** Native
 - **Memory Type:** True Dual Port RAM

### Port A Options:

 - **Write Width:** 256
 - **Read Width:** 256
 - **Write Depth:** 512
 - **Read Depth:** 512

### Port B Options:

 - **Write Width:** 32
 - **Read Width:** 32

## multiplier (Multiplier)

### Basic:

 - **Multiplier Type:** Parallel Multiplier
 - **Data type:** Signed / Signed
 - **Width:** 33 / 33
 - **Multiplier Construction:** Use Mults
 - **Optimization Options:** Speed Optimized

### Output and Control:

 - **Pipeline Stages:** 6


## divider_0 (Divider Generator)

### Channel Settings:

 - **Algorithm Type:** Radix2
 - **Operand Sign:** Signed
 - **Dividend Width:** 33
 - **Divisor Width:** 33
 - **Remainder Type:** Remainder
 - **Detect Divide-By-Zero:** Yes

### Options:

 - **Clocks per Division:** 1
 - **Flow Control:** Non Blocking
 - **Latency Configuration:** Manual
 - **Latency:** 30
 - **ACKLEN:** Yes
 - **ARESETN:** Yes

## uart_fifo_tx_0 (FIFO Generator)

### Basic:

 - **Interface Type:** Native
 - **Fifo Implementation:** Common Clock Builtin FIFO

### Native Ports:

 - **Read Mode:** Standard FIFO
 - **Write Width:** 8
 - **Write Depth:** 512
 - **Output Register:** Yes

## uart_fifo_rx_0 (FIFO Generator)

### Basic:

 - **Interface Type:** Native
 - **Fifo Implementation:** Common Clock Builtin FIFO

### Native Ports:

 - **Read Mode:** Standard FIFO
 - **Write Width:** 8
 - **Write Depth:** 512
 - **Output Register:** Yes
