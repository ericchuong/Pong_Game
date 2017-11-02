`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2017 02:05:48 PM
// Design Name: 
// Module Name: kb_monitor
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


module kb_monitor
   (
    input wire clk, reset,
    input wire ps2d, ps2c,
    output wire tx,
    output reg [1:0]direction
   );
   // constant declaration
   localparam SP=8'h20; // space in ASCII
   // symbolic state declaration
   localparam [1:0]
      idle  = 2'b00,
      send1 = 2'b01,
      send0 = 2'b10,
      sendb = 2'b11;
   // signal declaration
   reg [1:0] state_reg, state_next;
   reg [7:0] w_data, ascii_code;
   reg wr_uart;
   wire scan_done_tick;
   wire [3:0] hex_in;
   wire [7:0]scan_data;
   // instantiate ps2 receiver
   ps2_rx ps2_rx_unit
      (.clk(clk), .reset(reset), .rx_en(1'b1),
       .ps2d(ps2d), .ps2c(ps2c),
    .rx_done_tick(scan_done_tick), .dout(scan_data));
   // instantiate UART
   uart uart_unit
      (.clk(clk), .reset(reset), .rd_uart(1'b0),
       .wr_uart(wr_uart), .rx(1'b1), .w_data(w_data),
       .tx_full(), .rx_empty(), .r_data(), .tx(tx));

   reg [1:0] d_state_reg, d_state_next;
   localparam [1:0]
      stop = 2'b00,
      right = 2'b01,
      left = 2'b10,
      hold = 2'b11;
   // FSM to send 3 ASCII characters
   // state registers
   always @(posedge clk, posedge reset)
      if (reset)
      begin
         state_reg <= idle;
         d_state_reg <= stop;
      end
      else
      begin
         state_reg <= state_next;
         d_state_reg <= d_state_next;
      end

   // next-state logic
   always @*
   begin
      wr_uart = 1'b0;
      w_data = SP;
      state_next = state_reg;
      case (state_reg)
         idle:
            if (scan_done_tick) // a scan code received
               state_next = send1;
         send1: // send higher hex char
            begin
               w_data = ascii_code;
               wr_uart = 1'b1;
               state_next = send0;
            end
         send0: // send lower hex char
            begin
               w_data = ascii_code;
               wr_uart = 1'b1;
               state_next = sendb;
            end
         sendb:  // send blank char
            begin
               w_data = SP;
               wr_uart = 1'b1;
               state_next = idle;
            end
      endcase
   end
 
 // keyboard part
   always @*
   begin
      d_state_next = d_state_reg;
      case (d_state_reg)
         stop:
            begin
               direction = stop;
               if (scan_done_tick) // a scan code received wait for F0
               begin
                  if (scan_data == 8'h23) // right
                     d_state_next = right;
                  else if (scan_data == 8'h1C) // left
                     d_state_next = left;
               end
            end
         left: // send higher hex char
            begin
               direction = left;
               if (scan_data == 8'hF0)
                  d_state_next = hold;
            end
         right: // send lower hex char
            begin
               direction = right;
               if (scan_data == 8'hF0)
                  d_state_next = hold;
            end
         hold:  // 
            begin
               direction = stop;
               if (scan_done_tick)
                  d_state_next = stop;
            end
      endcase
   end
   
   // scan code to ASCII display
 
   // split the scan code into two 4-bit hex
assign hex_in = (state_reg==send1)?    scan_data[7:4] :   scan_data[3:0];
   // hex digit to ASCII code
   always @*
    case (hex_in)
       4'h0: ascii_code = 8'h30;
       4'h1: ascii_code = 8'h31;
       4'h2: ascii_code = 8'h32;
       4'h3: ascii_code = 8'h33;
       4'h4: ascii_code = 8'h34;
       4'h5: ascii_code = 8'h35;
       4'h6: ascii_code = 8'h36;
       4'h7: ascii_code = 8'h37;
       4'h8: ascii_code = 8'h38;
       4'h9: ascii_code = 8'h39;
       4'ha: ascii_code = 8'h41;
       4'hb: ascii_code = 8'h42;
       4'hc: ascii_code = 8'h43;
       4'hd: ascii_code = 8'h44;
       4'he: ascii_code = 8'h45;
       default: ascii_code = 8'h46;
    endcase
endmodule

