// vga_sync_640x480.v
`timescale 1ns/1ps
module vga_sync_640x480(
    input  wire pclk,        // 25 MHz
    input  wire rst,
    output reg  hsync,
    output reg  vsync,
    output wire active,      // 1 when in visible area
    output reg  [9:0] x,     // 0..639
    output reg  [8:0] y      // 0..479
);
    // 640x480 @60Hz timing @25.175 MHz (we run ~25 MHz)
    localparam H_VISIBLE=640, H_FP=16, H_SYNC=96, H_BP=48, H_TOTAL=800;
    localparam V_VISIBLE=480, V_FP=10, V_SYNC=2,  V_BP=33, V_TOTAL=525;

    reg [9:0] hcnt = 0; // 0..799
    reg [9:0] vcnt = 0; // 0..524

    assign active = (hcnt < H_VISIBLE) && (vcnt < V_VISIBLE);

    always @(posedge pclk) begin
        if (rst) begin
            hcnt <= 0; vcnt <= 0; x <= 0; y <= 0; hsync <= 1; vsync <= 1;
        end else begin
            // h counter
            if (hcnt == H_TOTAL-1) begin
                hcnt <= 0;
                // v counter
                if (vcnt == V_TOTAL-1) vcnt <= 0; else vcnt <= vcnt + 1;
            end else begin
                hcnt <= hcnt + 1;
            end

            // visible coords
            x <= (hcnt < H_VISIBLE) ? hcnt : 10'd0;
            y <= (vcnt < V_VISIBLE) ? vcnt[8:0] : 9'd0;

            // negative pulses
            hsync <= ~((hcnt >= (H_VISIBLE+H_FP)) && (hcnt < (H_VISIBLE+H_FP+H_SYNC)));
            vsync <= ~((vcnt >= (V_VISIBLE+V_FP)) && (vcnt < (V_VISIBLE+V_FP+V_SYNC)));
        end
    end
endmodule
