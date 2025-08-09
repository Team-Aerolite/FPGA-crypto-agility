module uart_caesar_decoder (
    input  wire       clk,        // 50 MHz FPGA clock
    input  wire       rst_n,      // active low reset
    input  wire       uart_rx,    // UART receive from PC
    output wire       uart_tx,    // UART transmit to PC
    output reg [3:0]  leds        // 4 LEDs for activity indication
);
    // UART config
    parameter CLK_FREQ  = 50000000; // 50 MHz
    parameter BAUD_RATE = 9600;

    // UART wires
    wire        rx_ready;
    wire [7:0]  rx_data;
    reg         rx_ack;

    reg         tx_start;
    reg  [7:0]  tx_data;
    wire        tx_busy;

    // UART RX
    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_receiver (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx),
        .rx_data(rx_data),
        .rx_ready(rx_ready),
        .rx_ack(rx_ack)
    );

    // UART TX
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_transmitter (
        .clk(clk),
        .rst_n(rst_n),
        .tx(uart_tx),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_busy(tx_busy)
    );

    // FSM state definitions
    localparam S_WAIT_SHIFT = 0;
    localparam S_WAIT_MSG   = 1;
    localparam S_DECODE     = 2;
    localparam S_SEND       = 3;

    reg [1:0] state;
    reg [7:0] shift;
    reg [7:0] message[0:63]; // message buffer (64 chars max)
    reg [6:0] msg_index;
    reg       overflow_flag;

    reg [6:0] decode_index;  // index for sequential decoding
    reg [6:0] send_index;    // index for sequential sending
    reg signed [8:0] tmp;    // signed temp for decoding

    // LED blink counter
    reg [25:0] blink_counter;

    // Main FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_WAIT_SHIFT;
            shift <= 0;
            msg_index <= 0;
            rx_ack <= 0;
            tx_start <= 0;
            overflow_flag <= 0;
            decode_index <= 0;
            send_index <= 0;
            leds <= 4'b0000;
            blink_counter <= 0;
        end else begin
            rx_ack   <= 0;
            tx_start <= 0;

            // Blink counter increments always
            blink_counter <= blink_counter + 1;

            case (state)
                //----------------------------------------
                // Wait for shift value (first byte)
                //----------------------------------------
                S_WAIT_SHIFT: begin
                    leds <= 4'b0000; // idle
                    if (rx_ready) begin
                        // Accept numeric ASCII or raw binary shift
                        if (rx_data >= "0" && rx_data <= "9")
                            shift <= rx_data - "0";
                        else
                            shift <= rx_data;
                        rx_ack <= 1;
                        msg_index <= 0;
                        overflow_flag <= 0;
                        state <= S_WAIT_MSG;
                    end
                end

                //----------------------------------------
                // Receive message until newline
                //----------------------------------------
                S_WAIT_MSG: begin
                    // LED chase pattern while active
                    leds <= (4'b0001 << blink_counter[23:22]);
                    if (rx_ready) begin
                        rx_ack <= 1;
                        if (rx_data == 8'h0A) begin // newline -> end of message
                            decode_index <= 0;
                            state <= S_DECODE;
                        end else begin
                            if (msg_index < 64) begin
                                message[msg_index] <= rx_data;
                                msg_index <= msg_index + 1;
                            end else begin
                                overflow_flag <= 1; // too long
                            end
                        end
                    end
                end

                //----------------------------------------
                // Decode sequentially
                //----------------------------------------
                S_DECODE: begin
                    leds <= (4'b0001 << blink_counter[23:22]);
                    if (!overflow_flag && decode_index < msg_index && decode_index < 64) begin
                        if (message[decode_index] >= "A" && message[decode_index] <= "Z") begin
                            tmp = message[decode_index] - "A" - shift;
                            if (tmp < 0)
                                tmp = tmp + 26;
                            message[decode_index] <= tmp + "A";
                        end else if (message[decode_index] >= "a" && message[decode_index] <= "z") begin
                            tmp = message[decode_index] - "a" - shift;
                            if (tmp < 0)
                                tmp = tmp + 26;
                            message[decode_index] <= tmp + "a";
                        end
                        decode_index <= decode_index + 1;
                    end else begin
                        send_index <= 0;
                        state <= S_SEND;
                    end
                end

                //----------------------------------------
                // Send back decoded message (or overflow warning)
                //----------------------------------------
                S_SEND: begin
                    leds <= (4'b0001 << blink_counter[23:22]);
                    if (!tx_busy) begin
                        if (overflow_flag) begin
                            if (send_index == 0) begin
                                tx_data <= "!";
                                tx_start <= 1;
                                send_index <= 1;
                            end else begin
                                tx_data <= 8'h0A; // newline
                                tx_start <= 1;
                                state <= S_WAIT_SHIFT;
                            end
                        end else begin
                            if (send_index < msg_index) begin
                                tx_data <= message[send_index];
                                tx_start <= 1;
                                send_index <= send_index + 1;
                            end else begin
                                tx_data <= 8'h0A; // newline
                                tx_start <= 1;
                                state <= S_WAIT_SHIFT;
                            end
                        end
                    end
                end
            endcase
        end
    end
endmodule
