//==========================================================
// Universidad Atonoma Metropolitana, Unidad Lerma
//==========================================================
// CounterN.v
// Programador: Gerardo Laguna
// 2 de julio 2025
//==========================================================
// A partir de codigo 4.9 del libro 
// Chu, Pong P. (2008). FPGA Prototyping by Verilog Examples. EUA: Wiley.
//!!!Gracias Prof. P. Chu :) !!! 
//==========================================================
module Bin_CounterN
   #(parameter N=8)
   (
    input wire clk, reset,
    output wire [N-1:0] q
   );

   //signal declaration
   reg [N-1:0] r_reg;
   wire [N-1:0] r_next;

   // body
   // register
   always @(posedge clk, posedge reset)
      if (reset)
         r_reg <= {N{1'b0}}; 
      else
         r_reg <= r_next;

   // next-state logic
   assign r_next = r_reg + 1;
   // output logic
   assign q = r_reg;

endmodule