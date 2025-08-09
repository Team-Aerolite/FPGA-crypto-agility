module uart_tx #(parameter CLK_FREQ = 50000000, parameter BAUD_RATE = 9600)(
    input wire clk, rst_n,
    output reg tx,
    input wire [7:0] tx_data,
    input wire tx_start,
    output reg tx_busy
);
    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    reg [15:0] clk_count;
    reg [3:0] bit_index;
    reg [9:0] tx_shift;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx <= 1;
            tx_busy <= 0;
        end else begin
            if (tx_start && !tx_busy) begin
                tx_shift <= {1'b1, tx_data, 1'b0};
                tx_busy <= 1;
                bit_index <= 0;
                clk_count <= 0;
            end else if (tx_busy) begin
                if (clk_count == CLKS_PER_BIT-1) begin
                    clk_count <= 0;
                    tx <= tx_shift[bit_index];
                    bit_index <= bit_index + 1;
                    if (bit_index == 9) tx_busy <= 0;
                end else clk_count <= clk_count + 1;
            end
        end
    end
endmodule
