`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2017 01:20:52 PM
// Design Name: 
// Module Name: pong_graph_animate
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

// VERTICAL GAME

module pong_graph_animate
   (
    input wire clk, reset,
    input wire video_on,
    input wire [9:0] pix_x, pix_y,
    input wire [1:0] direction,
    output reg [2:0] graph_rgb
   );

   // constant and signal declaration
   // x, y coordinates (0,0) to (639,479)
   localparam MAX_X = 640;
   localparam MAX_Y = 480;
   wire refr_tick;
   //--------------------------------------------
   // vertical stripe as a wall
   //--------------------------------------------
   // wall top, bottom boundary
   localparam WALL_Y_T = 50;
   localparam WALL_Y_B = 53;
   //--------------------------------------------
   // bottom horizontal bar
   //--------------------------------------------
   // bar top, bottom boundary
   localparam BAR_Y_T = 450;
   localparam BAR_Y_B = 453;
   // bar left, right boundary
   wire [9:0] bar_x_l, bar_x_r;
   localparam BAR_X_SIZE = 72;
   // register to track right boundary  (y position is fixed)
   reg [9:0] bar_x_reg, bar_x_next;
   // bar moving velocity when a button is pressed
   localparam BAR_V = 4;
   
   //--------------------------------------------
   // square ball
   //--------------------------------------------
   localparam BALL_SIZE = 8;
   // ball left, right boundary
   wire [9:0] ball_x_l, ball_x_r;
   // ball top, bottom boundary
   wire [9:0] ball_y_t, ball_y_b;
   // reg to track left, top position
   reg [9:0] ball_x_reg, ball_y_reg;
   wire [9:0] ball_x_next, ball_y_next;
   // reg to track ball speed
   reg [9:0] x_delta_reg, x_delta_next;
   reg [9:0] y_delta_reg, y_delta_next;
   // ball velocity can be pos or neg)
   localparam BALL_V_P = 2;
   localparam BALL_V_N = -2;
   //--------------------------------------------
   // round ball
   //--------------------------------------------
   wire [2:0] rom_addr, rom_col;
   reg [7:0] rom_data;
   wire rom_bit;
   //--------------------------------------------
   // object output signals
   //--------------------------------------------
   wire wall_on, bar_on, sq_ball_on, rd_ball_on;
   wire [2:0] wall_rgb, bar_rgb, ball_rgb;
   
   integer mcounter = 0;
   integer counter_logic = 0;
   reg [3:0]dig1;
   reg [3:0]dig0;
   // body
   //--------------------------------------------
   // round ball image ROM
   //--------------------------------------------
   always @*
   case (rom_addr)
      3'h0: rom_data = 8'b00111100; //   ****
      3'h1: rom_data = 8'b01000010; //  *    *
      3'h2: rom_data = 8'b10000001; // *      *
      3'h3: rom_data = 8'b10000001; // *      *
      3'h4: rom_data = 8'b10000001; // *      *
      3'h5: rom_data = 8'b10000001; // *      *
      3'h6: rom_data = 8'b01000010; //  *    *
      3'h7: rom_data = 8'b00111100; //   ****
   endcase

   // registers
   always @(posedge clk, posedge reset)
      if (reset)
         begin
            bar_x_reg <= 0;
            ball_x_reg <= 0;
            ball_y_reg <= 0;
            x_delta_reg <= 10'h004;
            y_delta_reg <= 10'h004;
         end
      else
         begin
            bar_x_reg <= bar_x_next;
            ball_x_reg <= ball_x_next;
            ball_y_reg <= ball_y_next;
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
         end

   // refr_tick: 1-clock tick asserted at start of v-sync
   //            i.e., when the screen is refreshed (60 Hz)
   assign refr_tick = (pix_y==481) && (pix_x==0);

   //--------------------------------------------
   // (wall) top horizontal strip
   //--------------------------------------------
   // pixel within wall
   assign wall_on = (WALL_Y_T<=pix_y) && (pix_y<=WALL_Y_B);
   // wall rgb output
   assign wall_rgb = 3'b001; // blue
   //--------------------------------------------
   // bottom horizontal bar
   //--------------------------------------------
   // boundary
      
   assign bar_x_l = bar_x_reg;
   assign bar_x_r = bar_x_l + BAR_X_SIZE - 1;
   // pixel within bar
   assign bar_on = (BAR_Y_T<=pix_y) && (pix_y<=BAR_Y_B) &&
                   (bar_x_l<=pix_x) && (pix_x<=bar_x_r);
   // bar rgb output
   assign bar_rgb = 3'b010; // green
   // new bar x-position
   
   always @*
   begin
      bar_x_next = bar_x_reg; // no move

      if (refr_tick)
      begin
         if (direction[0] && (bar_x_r < (MAX_X-1-BAR_V))) 
            bar_x_next = bar_x_reg + BAR_V; // move right
         
         else if (direction[1] && (bar_x_l > BAR_V))
            bar_x_next = bar_x_reg - BAR_V; // move left
      end
   end

//   --------------------------------------------
//    square ball
//   --------------------------------------------
//    boundary
   assign ball_x_l = ball_x_reg;
   assign ball_y_t = ball_y_reg;
   assign ball_x_r = ball_x_l + BALL_SIZE - 1;
   assign ball_y_b = ball_y_t + BALL_SIZE - 1;
   // pixel within ball
   assign sq_ball_on =
            (ball_x_l<=pix_x) && (pix_x<=ball_x_r) &&
            (ball_y_t<=pix_y) && (pix_y<=ball_y_b);
   // map current pixel location to ROM addr/col
   assign rom_addr = pix_y[2:0] - ball_y_t[2:0];
   assign rom_col = pix_x[2:0] - ball_x_l[2:0];
   assign rom_bit = rom_data[rom_col];
   // pixel within ball
   assign rd_ball_on = sq_ball_on & rom_bit;
   // ball rgb output
   assign ball_rgb = 3'b100;   // red
   // new ball position
   assign ball_x_next = (refr_tick) ? ball_x_reg+x_delta_reg :
                        ball_x_reg ;
   assign ball_y_next = (refr_tick) ? ball_y_reg+y_delta_reg :
                        ball_y_reg ;
   // new ball velocity
   
   always @*
   begin
      x_delta_next = x_delta_reg;
      y_delta_next = y_delta_reg;
      if (ball_x_l < 1) // reach left
         x_delta_next = BALL_V_P;
      else if (ball_x_r > (MAX_X-1)) // reach right
         x_delta_next = BALL_V_N;
      else if (ball_y_t <= WALL_Y_B) // reach wall
         y_delta_next = BALL_V_P;    // bounce back
      else if ((BAR_Y_T<=ball_y_b) && (ball_y_b<=BAR_Y_B) &&
               (bar_x_l<=ball_x_r) && (ball_x_l<=bar_x_r))
         // reach y of bottom bar and hit, ball bounce back  
         y_delta_next = BALL_V_N;
   end
   
   //--------------------------------------------
   // score counter
   //--------------------------------------------
   always@* 
   begin
      if ((ball_y_t == 460) && (counter_logic == 1) && refr_tick)// ball falls below bar
      begin
         mcounter = (mcounter + counter_logic);
         counter_logic = 0;
      end 
      else if ((ball_y_t == 200)&& (counter_logic == 0) && refr_tick)
         counter_logic = 1;
   end
   
   always@*
   case((mcounter%(10)))
      0: dig0 = 4'b0000; // 1s digit
      1: dig0 = 4'b0001; //
      2: dig0 = 4'b0010; //
      3: dig0 = 4'b0011; //
      4: dig0 = 4'b0100; //
      5: dig0 = 4'b0101; //
      6: dig0 = 4'b0110; //
      7: dig0 = 4'b0111; //
      8: dig0 = 4'b1000; //
      9: dig0 = 4'b1001; //
   endcase
   
   always@*
   case((mcounter/(10)))
      0: dig1 = 4'b0000; // 10s digit
      1: dig1 = 4'b0001; //
      2: dig1 = 4'b0010; //
      3: dig1 = 4'b0011; //
      4: dig1 = 4'b0100; //
      5: dig1 = 4'b0101; //
      6: dig1 = 4'b0110; //
      7: dig1 = 4'b0111; //
      8: dig1 = 4'b1000; //
      9: dig1 = 4'b1001; //
   endcase
   
   wire text_on, text_rgb;
   
   pong_text score_text(.clk(clk), .dig0(dig0[3:0]), .dig1(dig1[3:0]),
      .pix_x(pix_x), .pix_y(pix_y), .text_on(text_on), .text_rgb(text_rgb));

   //--------------------------------------------
   // rgb multiplexing circuit
   //--------------------------------------------
   always @*
      if (~video_on)
         graph_rgb = 3'b000; // blank
      else
         if (wall_on)
            graph_rgb = wall_rgb;
         else if (bar_on)
            graph_rgb = bar_rgb;
         else if (rd_ball_on)
            graph_rgb = ball_rgb;
         else if (text_on)
            graph_rgb = text_rgb;
         else 
            graph_rgb = 3'b111; // gray background    
endmodule
