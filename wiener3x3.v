//module wiener3x3 #(parameter integer SIGMA_N2 = 200)(
//    input  wire [7:0] p0,p1,p2,p3,p4,p5,p6,p7,p8,
//    output wire [7:0] y_out
//);
//    wire [12:0] sum9   = p0+p1+p2+p3+p4+p5+p6+p7+p8;
//    wire [19:0] sumsq9 = p0*p0+p1*p1+p2*p2+p3*p3+p4*p4+p5*p5+p6*p6+p7*p7+p8*p8;

//    wire [11:0] mean = sum9 / 9;
//    wire [19:0] Ex2  = sumsq9 / 9;

//    wire [21:0] mean_sq = mean * mean;
//    wire [21:0] var     = (Ex2 > mean_sq) ? (Ex2 - mean_sq) : 0;

//    wire [21:0] num_var  = (var > SIGMA_N2) ? (var - SIGMA_N2) : 0;
//    wire [37:0] num_shift = {16'd0,num_var} << 16;

//    wire [31:0] gain_q16 = (var != 0) ? (num_shift / var) : 0;

//    wire signed [9:0] delta = p4 - mean;
//    wire signed [47:0] prod = gain_q16 * delta;

//    wire signed [31:0] filt = mean + (prod >>> 16);

//    assign y_out = (filt < 0) ? 0 :
//                   (filt > 255) ? 255 :
//                   filt[7:0];
//endmodule

// wiener3x3.v  -- 3x3 spatial Wiener (fixed point)
`timescale 1ns/1ps
module wiener3x3 #(
    parameter integer SIGMA_N2 = 500  // tune as needed
)(
    input  wire [7:0] p0, input wire [7:0] p1, input wire [7:0] p2,
    input  wire [7:0] p3, input wire [7:0] p4, input wire [7:0] p5,
    input  wire [7:0] p6, input wire [7:0] p7, input wire [7:0] p8,
    output wire [7:0] y_out
);
    // sums
    wire [12:0] sum9   = p0+p1+p2+p3+p4+p5+p6+p7+p8;
    wire [19:0] sumsq9 = p0*p0 + p1*p1 + p2*p2 + p3*p3 + p4*p4 + p5*p5 + p6*p6 + p7*p7 + p8*p8;

    // mean and E[x^2]
    wire [11:0] mean = sum9 / 9;       // 0..255
    wire [19:0] Ex2  = sumsq9 / 9;

    // var = Ex2 - mean^2
    wire [21:0] mean_sq = mean * mean;     // up to 65025
    wire [21:0] var     = (Ex2 > mean_sq) ? (Ex2 - mean_sq) : 22'd0;

    // gain = max(0, (var - sigma)/var) in Q16.16
    wire [21:0] num_var   = (var > SIGMA_N2) ? (var - SIGMA_N2) : 22'd0;
    wire [37:0] num_shift = {16'd0, num_var} << 16;         // * 2^16
    wire [31:0] gain_q16  = (var != 0) ? (num_shift / var) : 32'd0;

    // delta = center - mean
    wire signed [9:0]  delta    = $signed({1'b0,p4}) - $signed({1'b0,mean});
    wire signed [47:0] prod     = $signed({1'b0,gain_q16}) * $signed({6'b0,delta});
    wire signed [31:0] add_term = prod >>> 16;

    wire signed [31:0] filt = $signed({16'd0,mean}) + add_term;

    assign y_out = (filt < 0)   ? 8'd0 :
                   (filt > 255) ? 8'd255 : filt[7:0];
endmodule
