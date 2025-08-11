//=============================
// master_spi_4post.v
//=============================
//
// El hardware sintetizado fue probado con el reloj del sistema 
// de 100MHz y funciono bien.
// La velocidad maxima generada para la senal SCK fue de 12.5 MHz, alimentando
// las senales de reloj con el reloj del sistema, sin division de frecuencia. 
// La expresion para calcular la velocidad de SCK es la siguiente:
// f_sck= clk/8
//
//=============================================================================
// *Codigo para el componente master_spi4post*
//=============================================================================
// Author: Gerardo Laguna
// UAM lerma
// Mexico
// 28/07/2025
//=============================================================================

module master_spi4post
   (
    input wire CLK, RST,
    output wire CS, MOSI, SCK,
    input wire MISO,
    input wire [15:0] Tx_word,
    output wire [15:0] Rx_word,
    input wire Go,
    output wire Busy
   );

   // symbolic state declaration
   localparam [3:0]
      idle = 4'h00,
      start = 4'h01, 
      latch_SRo = 4'h02, 
      Dout_ld = 4'h03, 
      LS_SRo = 4'h04, 
      SCK_L = 4'h05, 
      LS_SRi = 4'h06,
      SCK_H = 4'h07, 
      last_SCK_L = 4'h08, 
      finish = 4'h09;

   // signal declaration
   reg [4:0] state_reg, state_next;
   reg [15:0] SRi_reg, SRi_next;
   reg [15:0] SRo_reg, SRo_next;
   reg [6:0] bCnt_reg, bCnt_next;
   reg [5:0] wCnt_reg, wCnt_next;
   reg MOSI_buf_reg,MOSI_buf_next;
   reg CS_buf_reg, CS_buf_next;
   reg SCK_buf_reg, SCK_buf_next;
   reg busy_buf_reg, busy_buf_next;
   

   // body
   // FSMD state & data registers
   always @(posedge CLK, posedge RST)
      if (RST)
         begin
         	state_reg <= idle;
         	SRi_reg <= 0;
         	SRo_reg <= 0;
         	bCnt_reg <= 0;
         	wCnt_reg <= 0;
         	MOSI_buf_reg <= 1'b1;
          	CS_buf_reg <= 1'b1;
         	SCK_buf_reg <= 1'b1;
         	busy_buf_reg <= 1'b0;
        end
      else
         begin
         	state_reg <= state_next;
         	SRi_reg <= SRi_next;
         	SRo_reg <= SRo_next;
         	bCnt_reg <= bCnt_next;
         	wCnt_reg <= wCnt_next;
         	MOSI_buf_reg <= MOSI_buf_next;
         	CS_buf_reg <= CS_buf_next;
         	SCK_buf_reg <= SCK_buf_next;
         	busy_buf_reg <= busy_buf_next; 
         end

   // FSMD next-state logic
   always @*
   begin
      SRi_next = SRi_reg;
      SRo_next = SRo_reg;
      bCnt_next = bCnt_reg;
      wCnt_next = wCnt_reg;

      case (state_reg)
         idle :
            if (Go)
               state_next = start;
            else
               state_next = idle;
         start :
	       begin
            SRo_next = Tx_word;
            SRi_next = 0;
            bCnt_next = 0;
            state_next = latch_SRo;
	       end

         latch_SRo :
            state_next = Dout_ld;
        
         Dout_ld :
            state_next = LS_SRo;

         LS_SRo :
	       begin
            SRo_next = {SRo_reg[14 : 0] , 1'b0};
            wCnt_next = 0;
            state_next = SCK_L;
	       end

         SCK_L :
            if (wCnt_reg)
                state_next = LS_SRi;
            else
             begin
                wCnt_next = wCnt_reg+1;
                state_next = SCK_L;
             end

         LS_SRi :
	       begin
               SRi_next = {SRi_reg[14 : 0], MISO};
               wCnt_next = 0;
               state_next = SCK_H;
	       end

         SCK_H :
            if (wCnt_reg == 2)
	           begin
                state_next = LS_SRi;
                if (bCnt_reg == 15)
                 begin
                    wCnt_next = 0;
                    state_next = last_SCK_L;
                 end
                else
                 begin
                    bCnt_next = bCnt_reg+1;
                    state_next = Dout_ld;
                 end
	           end
            else
	           begin
                wCnt_next = wCnt_reg+1;
                state_next = SCK_H;
                end

         last_SCK_L :
            if (wCnt_reg == 4)
                state_next = finish;
            else
	           begin
                wCnt_next = wCnt_reg+1;
                state_next = last_SCK_L;
                end

         finish :
            state_next = idle;
            
      endcase
   end

   // look-ahead output logic
   always @*
   begin
      CS_buf_next = 1'b1;
      SCK_buf_next = 1'b1;
      busy_buf_next = 1'b1;
      MOSI_buf_next = MOSI_buf_reg;

      case (state_next)
        idle :
            busy_buf_next = 1'b0;
              
        latch_SRo :
	       begin
            CS_buf_next = 1'b0;
            SCK_buf_next = 1'b0;
	       end

        Dout_ld :
	       begin
            CS_buf_next = 1'b0;
            SCK_buf_next = 1'b0;
            MOSI_buf_next = SRo_reg[15];
	       end
          
        LS_SRo :
	       begin
            CS_buf_next = 1'b0;
            SCK_buf_next = 1'b0;
	       end
          
        SCK_L :
	       begin
            CS_buf_next = 1'b0;
            SCK_buf_next = 1'b0;
	       end
          
        LS_SRi :
            CS_buf_next = 1'b0;
          
        SCK_H :
            CS_buf_next = 1'b0;
          
        last_SCK_L :
	       begin
            CS_buf_next = 1'b0;
            SCK_buf_next = 1'b0;
	       end
          
        finish :
            busy_buf_next = 1'b0;

      endcase
   end

   //outputs
   assign MOSI = MOSI_buf_reg;
   assign CS = CS_buf_reg;
   assign SCK = SCK_buf_reg;
   assign Rx_word = SRi_reg;
   assign Busy = busy_buf_reg;

 endmodule
