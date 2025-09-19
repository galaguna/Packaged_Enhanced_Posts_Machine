`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//=============================================================================
// post_spi_ctrl.v
//=============================================================================
// Interfaz SPI esclava, con velocidad configurable, para maquina de Post
//=============================================================================
// Author: Gerardo A. Laguna S.
// Universidad Autonoma Metropolitana
// Unidad Lerma
// 19.sep.2025
//=============================================================================
//////////////////////////////////////////////////////////////////////////////////


module post_spictrl
   #(parameter [3:0] CLK_SEL=0)
   (
    input CLK, RST,
    input CS, MOSI, SCK,
    output MISO,
    input [3:0] CIN,
    output [3:0] COUT,
    output [7:0] CADD,
    output CWE,
    input DIN,
    output DOUT,        
    output [7:0] DADD,
    output DWE,
    output PCLK    
    );
 
    //signals:
    wire [15:0] div_clk;

    wire loc_clk;
    
   
    //instantiations:
    Bin_CounterN #(.N(16)) my_counter
      (.clk(CLK), .reset(RST), .q(div_clk));
      

    slave_spi4post my_PostSPI
    (
    .CLK(loc_clk), .RST(RST),
    .CS(CS), .MOSI(MOSI), .SCK(SCK),
    .MISO(MISO),
    .cin_prg(CIN),
    .cout_prg(COUT),
    .cadd_prg(CADD),
    .cwe_prg(CWE),
    .din_prg(DIN),
    .dout_prg(DOUT),
    .dadd_prg(DADD),
    .dwe_prg(DWE), .prog_clk(PCLK)
    );    

    //16 to 1 multiplexor:
     assign loc_clk = CLK_SEL[3] ?
                 (CLK_SEL[2] ? (CLK_SEL[1] ? (CLK_SEL[0] ? div_clk[15] : div_clk[14]) : (CLK_SEL[0] ? div_clk[13] : div_clk[12])) 
                                :
                               (CLK_SEL[1] ? (CLK_SEL[0] ? div_clk[11] : div_clk[10]) : (CLK_SEL[0] ? div_clk[9] : div_clk[8]))) 
                  :
                 (CLK_SEL[2] ? (CLK_SEL[1] ? (CLK_SEL[0] ? div_clk[7] : div_clk[6]) : (CLK_SEL[0] ? div_clk[5] : div_clk[4])) 
                                :
                               (CLK_SEL[1] ? (CLK_SEL[0] ? div_clk[3] : div_clk[2]) : (CLK_SEL[0] ? div_clk[1] : div_clk[0])));

   // output logic:

endmodule
