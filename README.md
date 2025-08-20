**#UART Transceiver in Verilog**
Project Overview:
UART (Universal Asynchronous Receiver-Transmitter) module implemented in Verilog with FIFO buffering, baud rate generator, and testbench simulation in Xilinx Vivado.
This project implements a Universal Asynchronous Receiver Transmitter (UART) in Verilog, including:
Transmitter (TX)
Receiver (RX)
Baud Rate Generator
FIFO Buffering
Complete Testbenches for verification
The design was developed and tested using Xilinx Vivado simulation environment, with modular testbenches for TX, RX, and the integrated UART.
Repository Structure:
uart-verilog-vivado/
│
├── src/            # Source Verilog RTL files
│   ├── uart_tx.sv
│   ├── uart_rx.sv
│   ├── baud_gen.sv
│   ├── uart_top.sv
│   └── fifo.sv
│
├── tb/             # Testbench files
│   ├── tb_uart_tx.sv
│   ├── tb_uart_rx.sv
│   └── tb_uart.sv   # Full UART system test
│
├── docs/           # Documentation (diagrams, reports, waveforms) [optional]
│
└── README.md       # Project description
