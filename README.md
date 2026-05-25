# RISC-V Cache Controller

## Team
* Bruno Menezes Rodrigues Oliveira Vaz
* João Costa Calazans
* João Pedro Torres
* Lucas Carneiro Nassau Malta
* Pedro Henrique Debs Rabelo

## Description
This repository contains the implementation of a Cache Controller in SystemVerilog, based on the specification presented in Chapter 5, Section 5.12 of the book *Computer Organization and Design: The Hardware/Software Interface (RISC-V Edition)*.

The objective of this project is to consolidate hardware design concepts related to memory hierarchy, cache hits/misses handling, and main memory interaction.

## Project Structure
* `src/`: Core RTL implementation files in SystemVerilog.
* `tb/`: Testbenches for functional validation (Read/Write paths, replacement policies, etc.).
* `sim/`: Simulation scripts and Makefiles.
* `doc/`: Project documentation and final report.

## Prerequisites & Dependencies
To compile and simulate this project on a Linux/WSL environment, you will need:
* **GNU Make** (v4.3 or newer)
* **Icarus Verilog** (v11.0 or newer) or **Verilator**
* **GTKWave** (for waveform visualization)

You can install the dependencies on Ubuntu/Debian-based systems using:
```bash
sudo apt update
sudo apt install build-essential iverilog verilator gtkwave -y
```

## Compilation and Simulation Instructions
Instructions to run the automated testbenches via terminal:

1. Running Simulations
Navigate to the sim/ directory and execute the Makefile (adjust commands depending on the chosen tool):

```bash
cd sim
make run
```

2. Viewing Waveforms
To evaluate the functional correctness and analyze waveforms using GTKWave:

```bash
gtkwave sim/waveform.vcd
```
