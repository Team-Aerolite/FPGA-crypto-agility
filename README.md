# FPGA-crypto-agility
This demonstration showcases the communication and reconfiguration capabilities of the HA-FPGA system for cryptographic computation, specifically the decoding of Caesar cipher messages using hardware-level processing.

# Demonstration Goals
The main objective of this demo is to illustrate how users can interactively send encoded text to the FPGA, set the shift value in real time, and receive the decoded message instantly—demonstrating the flexible real-time data processing power of the FPGA. The system allows dynamic parameter reconfiguration and instant feedback via both UART messaging and on-board LEDs, all without requiring hardware reprogramming.

Demonstrated Capabilities:
* Configure Shift Value: Set the Caesar cipher shift parameter dynamically from the user interface on the PC.
* Transmit Encoded Message: Send encoded text via UART from PC to FPGA.
* Real-time Decoding: The FPGA decodes the message using the supplied shift value, processing each character through hardware logic.
* Instant Result Display: The decoded message is sent back to the PC and displayed immediately in the software interface.
* Visual Feedback: On-board LEDs indicate activity and processing state, providing live hardware status during decoding.
* Interactive Operation: Users can adjust the shift value or send new messages at any time, with no need to reprogram the FPGA.

# Hardware Setup
* FPGA: Intel Altera Cyclone IV FPGA Development Board
* Communication protocol: UART over inbuilt USB port

# Files
* uart_caesar_decoder.v: Verilog code file of the Caesar cipher decoding demonstration
* uart_rx.v: UART data recieve module
* uart_tx.v: UART data transmit module
