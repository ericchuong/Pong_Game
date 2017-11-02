`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2017 04:45:43 PM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    input wire clk, reset,
    input wire ps2d, ps2c,
    output wire hsync, vsync,
    output wire [2:0] rgb,
    output wire tx
    );

    wire [1:0] btn;

    kb_monitor keyboard
        (.clk1(clk), .reset(reset), .ps2d(ps2d), .ps2c(ps2c), .tx(tx), .btn(btn));
    
    pong_top_an screen
        (.clk(clk), .reset(reset), .btn(btn), .hsync(hsync), .vsync(vsync), .rgb(rgb));
    
endmodule

