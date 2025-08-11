`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//=============================================================================
// Entidad integradora para el sistema SPI maestro para CPU Post con una tarjeta Basys3
//=============================================================================
// Codigo para probar el componente master_spictrl_4post
// con deboucing en boton de disparo.
//=============================================================================
// Author: Gerardo A. Laguna S.
// Universidad Autonoma Metropolitana
// Unidad Lerma
// 11.agosto.2025
//=============================================================================
//////////////////////////////////////////////////////////////////////////////////


module my_basys3(
    input sysclk,
    input btnC,
    input btnR,
    output [15:0] led,
    input [15:0] sw,
    output MST_CS,        
    output MST_MOSI,     
    input MST_MISO,    
    output MST_SCK
    );
 
    //signals:
    wire sys_rst;
    wire run_sig;
    wire go_sig;
   
    //instantiations:
    deboucing_3tics my_deboucing
        (.clk(sysclk), .rst(sys_rst), .x(run_sig), .y(go_sig));

    master_spictrl_4post #(.CLK_SEL(15)) U01 
    (
    .CLK(sysclk), .RST(sys_rst),
    .CS(MST_CS), .MOSI(MST_MOSI), .SCK(MST_SCK),
    .MISO(MST_MISO),
    .TX_W(sw),
    .RX_W(led),
    .GO(go_sig),
    .BUSY()
    );    

   // interconnection logic:
   assign sys_rst = btnC;
   assign run_sig = btnR;
   
endmodule
