`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//=============================================================================
// Entidad integradora para el sistema de procesamiento MPM (CPU Post) con una tarjeta Basys3
// *Esta version incorpora comunicacion SPI para la escritura/lectura
//  de los espacios de programa y datos.
//=============================================================================
// Codigo beta que emplea el reloj de 100 MHz de la tarjeta Basys :   
//      * El reloj del CPU se configura en el orden de las decimas de segundo 
//        (.CPU_CLK_SEL(10) en modulo Post_sys_speed_cnfg)
//      * La velocidad para la comunicacion SPI se configura para producir una senial SCK=191 Hz (en realidad, 190.8 Hz)
//        (.SPI_CLK_SEL(15) en modulo Post_sys_speed_cnfg)  
//=============================================================================
// Author: Gerardo A. Laguna S.
// Universidad Autonoma Metropolitana
// Unidad Lerma
// 11.agosto.2025
//=============================================================================
//////////////////////////////////////////////////////////////////////////////////


module top_code(
    input btnC,
    input btnR,
    input sysclk,
    output [15:0] led,
    input [15:0] sw,
    input SLV_CS,        
    input SLV_MOSI,     
    output SLV_MISO,    
    input SLV_SCK,     
    output [6:0] seg,
    output [3:0] an     
    );
 
    //signals:
    wire mode; 
    wire exec;
    wire loc_rst; 
    
    wire [15:0] div_clk;
    wire disp_ref_clk;
    wire [6:0] disp_driver;
    wire [3:0] state_nibble;
    
    //instantiations:
    Post_sys_speed_cnfg #(.CPU_CLK_SEL(10), .SPI_CLK_SEL(15)) my_PostSys
    (
    .CLK(sysclk), .RST(loc_rst),
    .RUN(exec), .MODE(mode),
    .STATE(state_nibble),
    .SPI_CS(SLV_CS), .SPI_MOSI(SLV_MOSI), .SPI_SCK(SLV_SCK),
    .SPI_MISO(SLV_MISO)
    );    
    
    Bin_CounterN #(.N(16)) my_counter
      (.clk(sysclk), .reset(loc_rst), .q(div_clk));
      
    hex2led my_hex2led
        (.HEX(state_nibble), .LED(disp_driver));
          
  // interconnection logic:
    assign mode = sw[15];
    assign exec = btnR;
    assign loc_rst = btnC;

   // display logic:
     assign disp_ref_clk = div_clk[15];
     assign an = 4'b0111 ;
     assign seg = disp_driver;
  
  //output logic:
    assign led=sw;   

endmodule
