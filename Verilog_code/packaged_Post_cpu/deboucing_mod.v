//=============================================================================
// Entidad para eliminacion de rebotes en senales de entrada
//=============================================================================
// Author: Gerardo A. Laguna S.
// Universidad Autonoma Metropolitana
// Unidad Lerma
// 2.julio.2025
//=============================================================================

module deboucing_3tics
   (
    input wire clk, rst, x,
    output reg  y
   );
   //Constants:
   parameter N_TICS=3;

   // symbolic state declaration
   localparam [1:0]
      Low  = 2'b00,
      Idle = 2'b01,
      High  = 2'b10;

   // signal declaration
   reg [1:0] state_reg, state_next;
   reg [3:0] c_reg, c_next;

   // body
   // FSMD state & data registers
   always @(posedge clk, posedge rst)
      if (rst)
         begin
            state_reg <= Low;
            c_reg <= 0;
         end
      else
         begin
            state_reg <= state_next;
            c_reg <= c_next;
         end

   // FSMD next-state logic
   always @*
   begin
      c_next = c_reg;
      y = 1'b0;
      case (state_reg)
         Low:
            begin
               if (x)
                  state_next = Idle;
               else
                  state_next = Low;

               c_next = 0;
            end
         Idle:
            begin
               if (x)
               	begin
               		if (c_reg==N_TICS-1)
                  			state_next = High;
				else
					begin
                  				state_next = Idle;
						c_next = c_reg + 1;
					end
                  	end
               else
                  state_next = Low;
            end
         High:
            begin
               if (x)
                  state_next = High;
               else
                  state_next = Low;
       	
       	  y = 1'b1;

            end
         default:
            state_next = Low;
      endcase
   end


endmodule
