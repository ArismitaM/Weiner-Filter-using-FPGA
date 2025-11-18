//`timescale 1ns/1ps

//module top_basys3_wiener_uart(
//    input  wire CLK100MHZ,
//    input  wire RESET_BTN,
//    input  wire SW_BYPASS,        // 1 = raw image, 0 = Wiener filtered
//    output wire UART_TXD
//);

//    localparam SRC_W = 320;
//    localparam SRC_H = 240;
//    localparam FRAME_SIZE = SRC_W * SRC_H;

//    // -------------------------------------------------
//    // Pixel clock = 25 MHz
//    // -------------------------------------------------
//    reg [1:0] div = 0;
//    always @(posedge CLK100MHZ) div <= div + 1;
//    wire pclk = div[1];

//    // -------------------------------------------------
//    // Reset sync
//    // -------------------------------------------------
//    wire reset_async = RESET_BTN;
//    reg [1:0] rst_sync = 2'b11;

//    always @(posedge pclk or posedge reset_async)
//        if (reset_async) rst_sync <= 2'b11;
//        else             rst_sync <= {1'b0, rst_sync[1]};

//    wire reset = rst_sync[0];

//    // -------------------------------------------------
//    // Address generator
//    // -------------------------------------------------
//    reg [8:0] src_x = 0;
//    reg [7:0] src_y = 0;

//    wire [16:0] src_addr = (src_y * SRC_W) + src_x;
//    reg  [16:0] addr_r;

//    wire [7:0] rom_q;

//    blk_mem_gen_0 blk_mem (
//        .clka(pclk),
//        .ena(1'b1),
//        .wea(1'b0),
//        .addra(addr_r),
//        .dina(8'd0),
//        .douta(rom_q)
//    );

//    // -------------------------------------------------
//    // Line buffers for 3x3 window
//    // -------------------------------------------------
//    reg [7:0] linebuf1[0:SRC_W-1];
//    reg [7:0] linebuf2[0:SRC_W-1];

//    reg [7:0] p0,p1,p2,p3,p4,p5,p6,p7,p8;

//    always @(posedge pclk) begin
//        if (!reset) begin
//            // shift 3x3 window horizontally
//            p0 <= p1; p1 <= p2; 
//            p3 <= p4; p4 <= p5; 
//            p6 <= p7; p7 <= p8;

//            // bring new pixels from buffers
//            p2 <= linebuf1[src_x];
//            p5 <= linebuf2[src_x];
//            p8 <= rom_q;

//            // update line buffers
//            linebuf2[src_x] <= linebuf1[src_x];
//            linebuf1[src_x] <= rom_q;
//        end
//    end

//    // -------------------------------------------------
//    // Wiener filter
//    // -------------------------------------------------
//    wire [7:0] y_filtered;

//    wiener3x3 #(.SIGMA_N2(200)) F (
//        .p0(p0), .p1(p1), .p2(p2),
//        .p3(p3), .p4(p4), .p5(p5),
//        .p6(p6), .p7(p7), .p8(p8),
//        .y_out(y_filtered)
//    );

//    // -------------------------------------------------
//    // UART streaming FSM
//    // -------------------------------------------------
//    reg pending_read = 0;
//    reg [7:0] pixel_reg = 0;
//    reg send_strobe = 0;
//    wire tx_busy;

//    reg [16:0] pixel_count = 0;
//    reg frame_done = 0;

//    always @(posedge pclk or posedge reset) begin
//        if (reset) begin
//            addr_r <= 0;
//            pending_read <= 0;
//            send_strobe <= 0;
//            pixel_reg <= 0;
//            src_x <= 0;
//            src_y <= 0;
//            pixel_count <= 0;
//            frame_done <= 0;
//        end else begin
//            send_strobe <= 0;

//            if (!frame_done) begin

//                if (!pending_read && !tx_busy) begin
//                    addr_r <= src_addr;
//                    pending_read <= 1;
//                end

//                else if (pending_read) begin
//                    pending_read <= 0;

//                    // BYPASS SWITCH FIXED HERE
//                    pixel_reg <= (SW_BYPASS ? rom_q : y_filtered);

//                    send_strobe <= 1;

//                    // pixel counter
//                    if (pixel_count == FRAME_SIZE - 1)
//                        frame_done <= 1;
//                    else
//                        pixel_count <= pixel_count + 1;

//                    // coordinate increment
//                    if (src_x == SRC_W-1) begin
//                        src_x <= 0;
//                        src_y <= src_y + 1;
//                    end else begin
//                        src_x <= src_x + 1;
//                    end
//                end
//            end
//        end
//    end

//    // -------------------------------------------------
//    // UART TX
//    // -------------------------------------------------
//    uart_tx #(
//        .CLK_FREQ(25000000),
//        .BAUD_RATE(115200)
//    ) u_uart (
//        .clk(pclk),
//        .reset(reset),
//        .tx_start(send_strobe),
//        .tx_data(pixel_reg),
//        .tx(UART_TXD),
//        .tx_busy(tx_busy)
//    );

//endmodule

`timescale 1ns/1ps

module top_basys3_wiener_uart(
    input  wire CLK100MHZ,
    input  wire RESET_BTN,
    input  wire SW_BYPASS,     // 1 = RAW, 0 = FILTERED
    output wire UART_TXD
);

    localparam SRC_W = 320;
    localparam SRC_H = 240;
    localparam FRAME_SIZE = SRC_W * SRC_H;

    // ---------------------------------------------------------
    // Pixel clock = 25 MHz
    // ---------------------------------------------------------
    reg [1:0] div = 0;
    always @(posedge CLK100MHZ) div <= div + 1;
    wire pclk = div[1];

    // ---------------------------------------------------------
    // Reset sync
    // ---------------------------------------------------------
    wire reset_async = RESET_BTN;
    reg [1:0] rst_sync = 2'b11;

    always @(posedge pclk or posedge reset_async)
        if (reset_async) rst_sync <= 2'b11;
        else             rst_sync <= {1'b0, rst_sync[1]};

    wire reset = rst_sync[0];

    // ---------------------------------------------------------
    // Address generator
    // ---------------------------------------------------------
    reg [8:0] src_x = 0;
    reg [7:0] src_y = 0;

    wire [16:0] src_addr = (src_y * SRC_W) + src_x;
    reg  [16:0] addr_r;

    wire [7:0] rom_q;

    blk_mem_gen_0 blk_mem (
        .clka(pclk),
        .ena(1'b1),
        .wea(1'b0),
        .addra(addr_r),
        .dina(8'd0),
        .douta(rom_q)
    );

    // ---------------------------------------------------------
    // 3×3 WINDOW - FIXED & PROPERLY TIMED
    // ---------------------------------------------------------
    reg [7:0] linebuf1 [0:SRC_W-1];
    reg [7:0] linebuf2 [0:SRC_W-1];

    // Registered current ROM pixel (1-cycle delay)
    reg [7:0] pixel_now;

    // 3×3 window taps
    reg [7:0] p0,p1,p2,p3,p4,p5,p6,p7,p8;

    always @(posedge pclk) begin
        if (reset) begin
            pixel_now <= 0;
        end
        else begin
            // 1 cycle alignment
            pixel_now <= rom_q;

            // shift window horizontally
            p0 <= p1;  p1 <= p2;
            p3 <= p4;  p4 <= p5;
            p6 <= p7;  p7 <= p8;

            // new column enters at right
            p2 <= linebuf1[src_x];
            p5 <= linebuf2[src_x];
            p8 <= pixel_now;

            // update buffers AFTER window uses the old values
            linebuf2[src_x] <= linebuf1[src_x];
            linebuf1[src_x] <= pixel_now;
        end
    end

    // ---------------------------------------------------------
    // Wiener filter (using corrected taps)
    // ---------------------------------------------------------
    wire [7:0] y_filtered;

    wiener3x3 #(.SIGMA_N2(200)) F (
        .p0(p0), .p1(p1), .p2(p2),
        .p3(p3), .p4(p4), .p5(p5),
        .p6(p6), .p7(p7), .p8(p8),
        .y_out(y_filtered)
    );

    // ---------------------------------------------------------
    // UART streaming FSM
    // ---------------------------------------------------------
    reg pending_read = 0;
    reg send_strobe = 0;
    reg [7:0] pixel_reg = 0;
    wire tx_busy;

    reg [16:0] pixel_count = 0;
    reg frame_done = 0;

    always @(posedge pclk or posedge reset) begin
        if (reset) begin
            addr_r <= 0;
            pending_read <= 0;
            send_strobe <= 0;
            pixel_reg <= 0;
            src_x <= 0;
            src_y <= 0;
            pixel_count <= 0;
            frame_done <= 0;
        end
        else begin
            send_strobe <= 0;

            if (!frame_done) begin

                if (!pending_read && !tx_busy) begin
                    addr_r <= src_addr;
                    pending_read <= 1;
                end

                else if (pending_read) begin
                    pending_read <= 0;

                    // FINAL CORRECT OUTPUT SELECTION
                    pixel_reg <= (SW_BYPASS ? pixel_now : y_filtered);

                    // start UART
                    send_strobe <= 1;

                    // Count pixels
                    if (pixel_count == FRAME_SIZE - 1)
                        frame_done <= 1;
                    else
                        pixel_count <= pixel_count + 1;

                    // XY increment
                    if (src_x == SRC_W-1) begin
                        src_x <= 0;
                        src_y <= src_y + 1;
                    end else begin
                        src_x <= src_x + 1;
                    end
                end

            end
        end
    end

    // ---------------------------------------------------------
    // UART TX
    // ---------------------------------------------------------
    uart_tx #(
        .CLK_FREQ(25000000),
        .BAUD_RATE(115200)
    ) u_uart (
        .clk(pclk),
        .reset(reset),
        .tx_start(send_strobe),
        .tx_data(pixel_reg),
        .tx(UART_TXD),
        .tx_busy(tx_busy)
    );

endmodule
