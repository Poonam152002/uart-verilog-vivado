UART Transceiver in VERILOG (XILINX VIVADO)
**Project Overview:**

This project implements a UART (Universal Asynchronous Receiver–Transmitter) in Verilog, with support for FIFO buffering, configurable baud rate generation, and modular testbench verification.

The design was developed and tested in Xilinx Vivado, with simulation testbenches provided for transmitter, receiver, and the integrated UART system.

**Tools & Environment:**

HDL: Verilog

Simulation: Xilinx Vivado

Clock Frequency: 50 MHz

Baud Rate: 115200 (configurable)

**Features:**

Transmitter (TX):

Start bit, 8 data bits (LSB first), optional parity (even/odd), and stop bit.

Busy flag and handshake (in_valid, in_ready) for reliable data transfer.

Receiver (RX):

16× oversampling for accurate sampling and noise resilience.

Error detection: Parity Error and Framing Error.

Handshake (rx_valid, rx_ready) for smooth data consumption.

Baud Rate Generator:

Generates both bit_tick (baud clock) and oversample_tick (16× baud).

Configurable parameters: CLK_FREQ (default 50 MHz), BAUD (default 115200).

FIFO Buffers:

TX and RX FIFOs (16 × 8-bit).

Prevents data loss when CPU/system cannot read/write immediately.

Top-Level UART (uart_top):

Integrates TX, RX, FIFOs, and baud generator.

Provides user-friendly interface:

tx_wr_en, tx_wr_data, tx_full

rx_rd_en, rx_rd_data, rx_empty, rx_valid

Error outputs: parity_err, frame_err.

Testbenches:

tb_uart_tx.v: Verifies transmitter functionality.

tb_uart_rx.v: Verifies receiver operation.

tb_uart.v: Full transceiver loopback test (TX → RX).
