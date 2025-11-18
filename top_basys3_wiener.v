// top_basys3_wiener.v  -- Option A: 320x240 8-bit ROM -> 3x3 Wiener -> 2x upscaler -> VGA
`timescale 1ns/1ps

module top_basys3_wiener(
    input  wire CLK100MHZ,
    input  wire RESET_BTN,     // map to btnC in XDC
    input  wire SW_BYPASS,     // 1=show raw; 0=filtered
    output wire VGA_HS,
    output wire VGA_VS,
    output wire [3:0] VGA_R,
    output wire [3:0] VGA_G,
    output wire [3:0] VGA_B
);

    // ------------------------
    // 25 MHz pixel clock
    // ------------------------
    reg [1:0] div = 0;
    always @(posedge CLK100MHZ) div <= div + 1'b1;
    wire pclk = div[1]; // 100/4 = 25 MHz

    // ------------------------
    // Async reset combine (physical button OR VIO output)
    // ------------------------
    // wire vio_reset;     // from VIO (1-bit)
    // wire reset_async = RESET_BTN | vio_reset;
    wire reset_async = RESET_BTN;


    // Sync reset to pclk
    reg [1:0] rst_sync = 2'b11;
    always @(posedge pclk or posedge reset_async) begin
        if (reset_async) rst_sync <= 2'b11;
        else             rst_sync <= {1'b0, rst_sync[1]};
    end
    wire reset = rst_sync[0];

    // ------------------------
    // VGA timing 640x480@60
    // ------------------------
    wire active;
    wire [9:0] vga_x;
    wire [8:0] vga_y;

    vga_sync_640x480 u_sync (
        .pclk(pclk),
        .rst(reset),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .active(active),
        .x(vga_x),
        .y(vga_y)
    );

    // ---------------------------------------------------------
    // 320x240 raster at half-rate vs VGA: 2x upscaler (2x2)
    // src_x increments every 2 VGA pixels in active region,
    // src_y increments every 2 VGA lines in active region.
    // ---------------------------------------------------------
    localparam SRC_W = 320;
    localparam SRC_H = 240;

    reg       hrep;      // toggles each active VGA pixel
    reg       vrep;      // toggles each VGA line (only in active region)
    reg [8:0] src_x;     // 0..319  (9 bits)
    reg [7:0] src_y;     // 0..239  (8 bits)

    wire line_end = active && (vga_x == 10'd639);
    wire frm_end  = active && (vga_x == 10'd639) && (vga_y == 9'd479);

    // advance logic: only step source pixel when we're at the first of the 2 horizontal reps
    wire src_step = active && (hrep == 1'b0); // every other pixel
    // at line end, toggle vrep; only advance src_y on second vrep
    // at new line start, reset hrep & src_x

    always @(posedge pclk) begin
        if (reset) begin
            hrep  <= 1'b0;
            vrep  <= 1'b0;
            src_x <= 9'd0;
            src_y <= 8'd0;
        end else begin
            if (active) begin
                // toggle horizontal rep each pixel
                hrep <= ~hrep;

                // increment src_x at the first of each 2 pixels
                if (src_step) begin
                    if (src_x == SRC_W-1) src_x <= 9'd0;
                    else                   src_x <= src_x + 1'b1;
                end

                // end-of-line handling
                if (line_end) begin
                    hrep  <= 1'b0;  // reset for next line
                    src_x <= 9'd0;

                    // toggle vertical rep once per line
                    vrep <= ~vrep;

                    // only advance src_y on the second repeated line
                    if (vrep == 1'b1) begin
                        if (src_y == SRC_H-1) src_y <= 8'd0;
                        else                   src_y <= src_y + 1'b1;
                    end
                end
            end else begin
                // outside visible area, keep reps reset so next active starts clean
                if (vga_x == 10'd0) hrep <= 1'b0;
            end
        end
    end

    // ---------------------------------------------------------
    // Single-port ROM (8-bit) read, 1-cycle latency
    // Depth = 320*240 = 76800, Width = 8
    // Address = src_y*320 + src_x = (src_y<<8) + (src_y<<6) + src_x
    // ---------------------------------------------------------
    wire [16:0] src_addr = ({src_y,8'b0}) + ({src_y,6'b0}) + {8'b0,src_x};
    reg  [16:0] rom_addr_r;
    always @(posedge pclk) rom_addr_r <= src_addr; // register address (optional)

    wire [7:0] rom_q;
    blk_mem_gen_0 blk_mem (           // <-- YOUR IP (Single Port ROM)
        .clka   (pclk),               // input  wire
        .ena    (1'b1),               // input  wire
        .wea    (1'b0),               // input  wire [0:0]
        .addra  (rom_addr_r),         // input  wire [16:0]
        .dina   (8'd0),               // input  wire [7:0]
        .douta  (rom_q)               // output wire [7:0]
    );

    // ---------------------------------------------------------
    // 3x3 window builder for streaming 320-wide raster
    // Two line buffers (previous two rows), plus three 3-tap shift regs
    // ---------------------------------------------------------
    reg [7:0] lb0 [0:SRC_W-1];   // previous row
    reg [7:0] lb1 [0:SRC_W-1];   // row before previous
    reg [7:0] r0a, r0b, r0c;     // top row shift
    reg [7:0] r1a, r1b, r1c;     // mid row shift
    reg [7:0] r2a, r2b, r2c;     // bot row shift
    reg [7:0] curr_pix;

    // edge replicate helpers
    wire first_col = (src_x == 0);
    wire new_line  = line_end; // when vga line ends (i.e., src_x will reset soon)

    // Run window updates only when a new source pixel is produced (src_step==1)
    // Note: rom_q is 1-cycle after src_addr, so use curr_pix as the valid pixel stream.
    always @(posedge pclk) begin
        if (reset) begin
            r0a<=0; r0b<=0; r0c<=0; r1a<=0; r1b<=0; r1c<=0; r2a<=0; r2b<=0; r2c<=0;
            curr_pix <= 0;
        end else if (src_step) begin
            // shift current pixel stream
            curr_pix <= rom_q;

            // read buffered pixels from prior rows at this column
            // (registered ROM means lb reads & writes align with curr_pix)
            // top & mid rows from line buffers
            // replicate left-edge by reusing *_c when first_col
            r0a <= first_col ? r0b : r0b;
            r0b <= first_col ? lb1[src_x] : r0c;
            r0c <= lb1[src_x];

            r1a <= first_col ? r1b : r1b;
            r1b <= first_col ? lb0[src_x] : r1c;
            r1c <= lb0[src_x];

            r2a <= first_col ? r2b : r2b;
            r2b <= first_col ? curr_pix  : r2c;
            r2c <= curr_pix;

            // write current row into lb0; rotate rows at end of source line
            lb0[src_x] <= curr_pix;
            lb1[src_x] <= lb0[src_x];

            // At start of a new VGA line (after last pixel), nothing special needed here;
            // lb1/lb0 rotation is happening column-wise which effectively makes lb1 the
            // previous row and lb0 the current row over the course of the line.
        end
    end

    // Pack the 3x3 window pixels
    wire [7:0] p0 = r0a, p1 = r0b, p2 = r0c,
               p3 = r1a, p4 = r1b, p5 = r1c,
               p6 = r2a, p7 = r2b, p8 = r2c;

    // ------------------------
    // Wiener filter (spatial, 3x3)
    // ------------------------
    wire [7:0] y_wien;
    wiener3x3 #(.SIGMA_N2(500)) u_wien (
        .p0(p0), .p1(p1), .p2(p2),
        .p3(p3), .p4(p4), .p5(p5),
        .p6(p6), .p7(p7), .p8(p8),
        .y_out(y_wien)
    );

    // Choose raw or filtered (center pixel raw = r1b)
    wire [7:0] pix8 = SW_BYPASS ? r1b : y_wien;

    // Drive VGA (map 8-bit gray to 4:4:4)
    assign VGA_R = active ? pix8[7:4] : 4'b0000;
    assign VGA_G = active ? pix8[7:4] : 4'b0000;
    assign VGA_B = active ? pix8[7:4] : 4'b0000;

    // ------------------------
    // ILA (probe0=reset, probe1=src_x[8:0], probe2=src_addr[16:0])
    // ------------------------
    /* ila_0 ila (
        .clk(pclk),
        .probe0(reset),            // [0:0]
        .probe1(src_x),            // [8:0]
        .probe2(src_addr)          // [16:0]
    );

    // ------------------------
    // VIO (probe_in0=src_x, probe_in1=src_addr, probe_out0=vio_reset)
    // ------------------------
    vio_0 vio (
        .clk(pclk),
        .probe_in0(src_x),         // [8:0]
        .probe_in1(src_addr),      // [16:0]
        .probe_out0(vio_reset)     // [0:0]
    );
    */

endmodule
