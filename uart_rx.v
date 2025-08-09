module uart_rx #(parameter CLK_FREQ = 50000000, parameter BAUD_RATE = 9600)(
    input wire clk, rst_n, rx,
    output reg [7:0] rx_data,
    output reg rx_ready,
    input wire rx_ack
);
    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam integer HALF_BIT = CLKS_PER_BIT / 2;

    reg [15:0] clk_count;
    reg [3:0] bit_index;
    reg [7:0] data_buffer;
    reg rx_reg, rx_sync;
    reg [1:0] state;

    localparam IDLE=0, START=1, DATA=2, STOP=3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_ready <= 0;
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
        end else begin
            rx_sync <= rx;
            rx_reg <= rx_sync;
            if (rx_ack) rx_ready <= 0;

            case(state)
                IDLE: begin
                    if (!rx_reg) begin
                        state <= START;
                        clk_count <= 0;
                    end
                end
                START: begin
                    if (clk_count == HALF_BIT) begin
                        if (!rx_reg) begin
                            state <= DATA;
                            clk_count <= 0;
                            bit_index <= 0;
                        end else state <= IDLE;
                    end else clk_count <= clk_count + 1;
                end
                DATA: begin
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count <= 0;
                        data_buffer[bit_index] <= rx_reg;
                        if (bit_index == 7) state <= STOP;
                        bit_index <= bit_index + 1;
                    end else clk_count <= clk_count + 1;
                end
                STOP: begin
                    if (clk_count == CLKS_PER_BIT-1) begin
                        rx_data <= data_buffer;
                        rx_ready <= 1;
                        state <= IDLE;
                    end else clk_count <= clk_count + 1;
                end
            endcase
        end
    end
endmodule
