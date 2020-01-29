`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:35:50 01/27/2020 
// Design Name: 
// Module Name:    counter 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module counter(input clk, input rst, output reg [31:0] mycounter);
        
//-- Sensitive to rising edge
always @(posedge clk) begin
  //-- Incrementar el registro
  if (rst)
    mycounter = 0;
  else
    mycounter = mycounter + 1;
end
endmodule