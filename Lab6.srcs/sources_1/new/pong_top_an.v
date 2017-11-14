`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2017 01:21:31 PM
// Design Name: 
// Module Name: pong_top_an
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


// Listing 13.6
module pong_top_an
   (
    input wire clk, reset,
    input wire ps2d, ps2c,
    output wire hsync, vsync,
    output wire [2:0] rgb,
    output wire tx
   );

   // signal declaration
   wire [9:0] pixel_x, pixel_y;
   wire video_on, pixel_tick;
   reg [2:0] rgb_reg;
   wire [2:0] rgb_next;
   wire clk_50m;
   wire [1:0]direction;
   
   // body
   // 50MHz clock generator
   clk_50m_generator clk_generator
      (.clk(clk), .reset_clk(reset), .clk_50m(clk_50m));
   // instantiate vga sync circuit
   vga_sync vsync_unit
      (.clk(clk_50m), .reset(reset), .hsync(hsync), .vsync(vsync),
       .video_on(video_on), .p_tick(pixel_tick),
       .pixel_x(pixel_x), .pixel_y(pixel_y));

   //keyboard
   kb_monitor keyboard
      (.clk(clk_50m), .reset(reset), .ps2d(ps2d), .ps2c(ps2c), .tx(tx), .direction(direction));
     
   // instantiate graphic generator
   pong_graph_animate pong_graph_an_unit
      (.clk(clk_50m), .reset(reset),
       .video_on(video_on), .pix_x(pixel_x),
       .pix_y(pixel_y), .direction(direction), .graph_rgb(rgb_next)); 
 
   // rgb buffer
   always @(posedge clk_50m)
      if (pixel_tick)
         rgb_reg <= rgb_next;
   // output
   assign rgb = rgb_reg;

endmodule

