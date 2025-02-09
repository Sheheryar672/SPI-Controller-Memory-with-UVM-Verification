# SPI Controller & Memory (UVM Verified)

## Overview  
The **Serial Peripheral Interface (SPI)** is a synchronous serial communication protocol widely used for high-speed data exchange between microcontrollers, sensors, and memory devices. This project implements an **SPI Controller & Memory**, verified using **UVM**, ensuring protocol compliance and functional accuracy.

## Features  
- **Implements SPI general signals:** Active Low Chip Select, MOSI, MISO, CLK, and Reset  
- **Supports read and write operations** on 8-bit data  
- **SLV error detection** for reliable communication  
- **32-byte memory depth** for efficient data storage  

## Makefile Instructions  

This project includes a **Makefile** for compiling, simulating, and displaying the waveform of the SPI controller and memory.  

### **Prerequisites**  
Ensure that **QuestaSim** with **UVM 1.2** is installed and accessible in your system's **PATH**.  

## Usage

Use the following commands for Makefile:

- **Compile and Run UVM Testbench**
  ```bash
  make run_tb

- **Display Waveform**
  ```bash
  make wave

- **CLEAN_UP**
  ```bash
  make clean
