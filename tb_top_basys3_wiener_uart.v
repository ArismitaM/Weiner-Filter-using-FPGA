`timescale 1ns/1ps

module tb_top_basys3_wiener_uart;

    // ============================================================
    // 1. CLOCK + RESET
    // ============================================================
    reg CLK100MHZ = 0;
    always #5 CLK100MHZ = ~CLK100MHZ;   // 100 MHz

    reg RESET_BTN = 1;
    reg SW_BYPASS = 0;

    wire UART_TXD;

    // ============================================================
    // 2. CONSTANTS
    // ============================================================
    localparam SRC_W      = 320;
    localparam SRC_H      = 240;
    localparam FRAME_SIZE = SRC_W * SRC_H;

    localparam TX_CYCLES  = 2170;    // 25MHz @ 115200 baud

    // ============================================================
    // 3. ROM MODEL
    // ============================================================
    reg [7:0] ROM [0:FRAME_SIZE-1];
    integer k;

    initial begin
        for (k = 0; k < FRAME_SIZE; k = k + 1)
            ROM[k] = (k % SRC_W) ^ (k / SRC_W);   // pseudo-image pattern
    end

    // ============================================================
    // 4. DUT
    // ============================================================
    top_basys3_wiener_uart DUT (
        .CLK100MHZ(CLK100MHZ),
        .RESET_BTN(RESET_BTN),
        .SW_BYPASS(SW_BYPASS),
        .UART_TXD(UART_TXD)
    );

    // ============================================================
    // 5. UART BUSY MOCK (legal hierarchical force)
    // ============================================================
    reg tx_busy_sim = 0;
    integer tx_cnt = 0;

    // UART busy generator
    always @(posedge DUT.pclk or posedge DUT.reset) begin
        if (DUT.reset) begin
            tx_busy_sim <= 0;
            tx_cnt <= 0;
        end
        else begin
            if (DUT.send_strobe && !tx_busy_sim) begin
                tx_busy_sim <= 1;
                tx_cnt <= 0;
            end
            else if (tx_busy_sim) begin
                if (tx_cnt == TX_CYCLES - 1)
                    tx_busy_sim <= 0;
                else
                    tx_cnt <= tx_cnt + 1;
            end
        end
    end

    // LEGAL force: force the wire INSIDE the DUT (not the submodule pin)
    always @* force DUT.tx_busy = tx_busy_sim;

    // ============================================================
    // 6. FORCE BRAM OUTPUT (legal)
    // ============================================================
    always @* force DUT.rom_q = ROM[DUT.addr_r];

    // ============================================================
    // 7. STIMULUS
    // ============================================================
    initial begin
        $display("==============================================");
        $display("  WIENER FILTER TESTBENCH STARTED");
        $display("==============================================");

        RESET_BTN = 1;
        #200;
        RESET_BTN = 0;

        $display("@%0t : Filtered mode (SW=0)", $time);
        SW_BYPASS = 0;
        #10_000_000;

        $display("@%0t : Raw mode (SW=1)", $time);
        SW_BYPASS = 1;
        #10_000_000;

        $display("@%0t : Back to filtered mode (SW=0)", $time);
        SW_BYPASS = 0;
        #5_000_000;

        $display("==============================================");
        $display("  TESTBENCH COMPLETED");
        $display("==============================================");
        $finish;
    end

    // ============================================================
    // 8. PIXEL LOGGER
    // ============================================================
    always @(posedge DUT.send_strobe) begin
        $display("PIXEL @%0t : %s  (%4d,%4d)  = %3d (0x%02h)",
                 $time,
                 SW_BYPASS ? "RAW " : "FILT",
                 DUT.src_x,
                 DUT.src_y,
                 DUT.pixel_reg,
                 DUT.pixel_reg);
    end

endmodule

// `timescale 1ns/1ps

//module tb_top_basys3_wiener_uart;

//    // ============================================================
//    // 1. CLOCK + RESET
//    // ============================================================
//    reg CLK100MHZ = 0;
//    always #5 CLK100MHZ = ~CLK100MHZ;   // 100 MHz

//    reg RESET_BTN = 1;

//    // Start in RAW mode (1) instead of FILTERED
//    reg SW_BYPASS = 1;

//    wire UART_TXD;

//    // ============================================================
//    // 2. CONSTANTS
//    // ============================================================
//    localparam SRC_W      = 320;
//    localparam SRC_H      = 240;
//    localparam FRAME_SIZE = SRC_W * SRC_H;

//    localparam TX_CYCLES  = 2170;    // 25MHz @ 115200 baud

//    // ============================================================
//    // 3. ROM MODEL
//    // ============================================================
//    reg [7:0] ROM [0:FRAME_SIZE-1];
//    integer k;

//    initial begin
//        for (k = 0; k < FRAME_SIZE; k = k + 1)
//            ROM[k] = (k % SRC_W) ^ (k / SRC_W);   // pseudo-image pattern
//    end

//    // ============================================================
//    // 4. DUT
//    // ============================================================
//    top_basys3_wiener_uart DUT (
//        .CLK100MHZ(CLK100MHZ),
//        .RESET_BTN(RESET_BTN),
//        .SW_BYPASS(SW_BYPASS),
//        .UART_TXD(UART_TXD)
//    );

//    // ============================================================
//    // 5. UART BUSY MOCK
//    // ============================================================
//    reg tx_busy_sim = 0;
//    integer tx_cnt = 0;

//    always @(posedge DUT.pclk or posedge DUT.reset) begin
//        if (DUT.reset) begin
//            tx_busy_sim <= 0;
//            tx_cnt <= 0;
//        end
//        else begin
//            if (DUT.send_strobe && !tx_busy_sim) begin
//                tx_busy_sim <= 1;
//                tx_cnt <= 0;
//            end
//            else if (tx_busy_sim) begin
//                if (tx_cnt == TX_CYCLES - 1)
//                    tx_busy_sim <= 0;
//                else
//                    tx_cnt <= tx_cnt + 1;
//            end
//        end
//    end

//    // Legal hierarchical force
//    always @* force DUT.tx_busy = tx_busy_sim;

//    // ============================================================
//    // 6. BRAM OUTPUT FORCE
//    // ============================================================
//    always @* force DUT.rom_q = ROM[DUT.addr_r];

//    // ============================================================
//    // 7. STIMULUS - STARTS IN RAW MODE
//    // ============================================================
//    initial begin
//        $display("==============================================");
//        $display("  WIENER FILTER TESTBENCH STARTED (RAW FIRST)");
//        $display("==============================================");

//        RESET_BTN = 1;
//        #200;
//        RESET_BTN = 0;

//        // --- Test 1: RAW mode first ---
//        $display("@%0t : RAW mode (SW=1)", $time);
//        SW_BYPASS = 1;
//        #10_000_000;

//        // --- Test 2: FILTERED mode ---
//        $display("@%0t : Filtered mode (SW=0)", $time);
//        SW_BYPASS = 0;
//        #10_000_000;

//        // --- Test 3: Switch back to RAW ---
//        $display("@%0t : RAW mode again (SW=1)", $time);
//        SW_BYPASS = 1;
//        #5_000_000;

//        $display("==============================================");
//        $display("  TESTBENCH COMPLETED");
//        $display("==============================================");
//        $finish;
//    end

//    // ============================================================
//    // 8. PIXEL LOGGER
//    // ============================================================
//    always @(posedge DUT.send_strobe) begin
//        $display("PIXEL @%0t : %s  (%4d,%4d)  = %3d (0x%02h)",
//                 $time,
//                 SW_BYPASS ? "RAW " : "FILT",
//                 DUT.src_x,
//                 DUT.src_y,
//                 DUT.pixel_reg,
//                 DUT.pixel_reg);
//    end

//endmodule

