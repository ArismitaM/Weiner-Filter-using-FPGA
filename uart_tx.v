module uart_tx #(
    parameter CLK_FREQ = 25000000,
    parameter BAUD_RATE = 115200
)(
    input  wire clk,
    input  wire reset,
    input  wire tx_start,
    input  wire [7:0] tx_data,
    output reg  tx,
    output reg  tx_busy
);

    localparam integer CYCLES_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam integer CTR_WIDTH = $clog2(CYCLES_PER_BIT);

    reg [CTR_WIDTH-1:0] baud_cnt = 0;
    reg [3:0] bit_idx = 0;
    reg [9:0] shift_reg = 10'b1111111111;

    always @(posedge clk) begin
        if (reset) begin
            tx <= 1'b1;
            tx_busy <= 1'b0;
            baud_cnt <= 0;
            bit_idx <= 0;
            shift_reg <= 10'b1111111111;
        end else begin
            if (tx_start && !tx_busy) begin
                shift_reg <= {1'b1, tx_data, 1'b0};
                tx_busy <= 1'b1;
                baud_cnt <= 0;
                bit_idx <= 0;
            end else if (tx_busy) begin
                if (baud_cnt == CYCLES_PER_BIT-1) begin
                    baud_cnt <= 0;
                    tx <= shift_reg[0];
                    shift_reg <= {1'b1, shift_reg[9:1]};
                    bit_idx <= bit_idx + 1;
                    if (bit_idx == 9)
                        tx_busy <= 1'b0;
                end else
                    baud_cnt <= baud_cnt + 1;
            end else
                tx <= 1'b1;
        end
    end
endmodule


//module uart_tx #(
//    parameter CLK_FREQ = 25000000,   // 25 MHz
//    parameter BAUD_RATE = 115200
//)(
//    input  wire clk,
//    input  wire reset,
//    input  wire tx_start,
//    input  wire [7:0] tx_data,
//    output reg  tx,
//    output reg  tx_busy
//);

//    localparam integer CYCLES_PER_BIT = CLK_FREQ / BAUD_RATE;
//    localparam integer CTR_WIDTH = $clog2(CYCLES_PER_BIT);

//    reg [CTR_WIDTH-1:0] baud_cnt = 0;
//    reg [3:0] bit_idx = 0;
//    reg [9:0] shift_reg = 10'b1111111111;

//    always @(posedge clk) begin
//        if (reset) begin
//            tx <= 1'b1;
//            tx_busy <= 1'b0;
//            baud_cnt <= 0;
//            bit_idx <= 0;
//            shift_reg <= 10'b1111111111;
//        end else begin
//            if (tx_start && !tx_busy) begin
//                shift_reg <= {1'b1, tx_data, 1'b0}; // stop bit, data, start bit
//                tx_busy <= 1'b1;
//                baud_cnt <= 0;
//                bit_idx <= 0;
//            end else if (tx_busy) begin
//                if (baud_cnt == CYCLES_PER_BIT-1) begin
//                    baud_cnt <= 0;
//                    tx <= shift_reg[0];
//                    shift_reg <= {1'b1, shift_reg[9:1]};
//                    bit_idx <= bit_idx + 1;
//                    if (bit_idx == 9) tx_busy <= 1'b0;
//                end else baud_cnt <= baud_cnt + 1;
//            end else tx <= 1'b1;
//        end
//    end

// endmodule
