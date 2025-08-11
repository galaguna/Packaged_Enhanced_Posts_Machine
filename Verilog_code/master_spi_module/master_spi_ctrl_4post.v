//=============================
// master_spi_ctrl_4post.v
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
// *Codigo para el componente master_spictrl_4post*
//=============================================================================
// Author: Gerardo Laguna
// UAM lerma
// Mexico
// 11/08/2025
//=============================================================================

module master_spictrl_4post
   #(parameter [3:0] CLK_SEL=0)
   (
    input wire CLK, RST,
    output wire CS, MOSI, SCK,
    input wire MISO,
    input wire [15:0] TX_W,
    output wire [15:0] RX_W,
    input wire GO,
    output wire BUSY
   );


   // signal declaration
    wire [15:0] div_clk;
    wire loc_clk;
    wire one_pulse;


   // body
  
  //instantiations:
    Bin_CounterN #(.N(16)) my_counter
      (.clk(CLK), .reset(RST), .q(div_clk));
      
    pulse_generator my_pulse
        (.clk(loc_clk), .reset(RST), .trigger(GO), .p(one_pulse));
      
   master_spi4post my_masterSPI
    (
    .CLK(loc_clk), .RST(RST),
    .CS(CS), .MOSI(MOSI), .SCK(SCK),
    .MISO(MISO),
    .Tx_word(TX_W),
    .Rx_word(RX_W),
    .Go(one_pulse),
    .Busy(BUSY)
    );    

  // interconnection logic:
    //16 to 1 multiplexor:
     assign loc_clk = CLK_SEL[3] ?
                 (CLK_SEL[2] ? (CLK_SEL[1] ? (CLK_SEL[0] ? div_clk[15] : div_clk[14]) : (CLK_SEL[0] ? div_clk[13] : div_clk[12])) 
                                :
                               (CLK_SEL[1] ? (CLK_SEL[0] ? div_clk[11] : div_clk[10]) : (CLK_SEL[0] ? div_clk[9] : div_clk[8]))) 
                  :
                 (CLK_SEL[2] ? (CLK_SEL[1] ? (CLK_SEL[0] ? div_clk[7] : div_clk[6]) : (CLK_SEL[0] ? div_clk[5] : div_clk[4])) 
                                :
                               (CLK_SEL[1] ? (CLK_SEL[0] ? div_clk[3] : div_clk[2]) : (CLK_SEL[0] ? div_clk[1] : div_clk[0])));


  

 endmodule
