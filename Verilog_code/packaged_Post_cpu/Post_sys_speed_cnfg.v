`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//=============================================================================
// Entidad Post_sys_speed_cnfg con CPU Post, memoria y comunicacion SPI.
//  * En esta version de puede configurar tanto la velocidad del reloj del CPU como la de la senial SCK del modulo SPI.
//  * Puerto STATE de 4 bits.
//=============================================================================
// Codigo beta
//=============================================================================
// Author: Gerardo A. Laguna S.
// Universidad Autonoma Metropolitana
// Unidad Lerma
// 11.agosto.2025
//=============================================================================
//////////////////////////////////////////////////////////////////////////////////


module Post_sys_speed_cnfg
   #(parameter [3:0] CPU_CLK_SEL=0, SPI_CLK_SEL=0)
(
    input CLK,RST,RUN,MODE,
    output [3:0] STATE,
    input SPI_CS,        
    input SPI_MOSI,     
    output SPI_MISO,    
    input SPI_SCK     
    );
 
    //signals:
    wire exec_cln;
    wire run_sig;
    wire cpu_clk;
    
    wire prog_clk;
    wire mem_clk;
    wire mxd_mem_clk;
    
    wire spi2ram_dout;
    wire cpu2ram_dout;

    wire spi2ram_din;
    wire cpu2ram_din;
    wire mxd_ram_din;

    wire [7:0] spi2ram_add;
    wire [7:0] cpu2ram_add;
    wire [7:0] mxd_ram_add;
    
    wire spi2ram_we;
    wire cpu2ram_we;
    wire mxd_ram_we;
    
    wire [3:0] spi2rom_dout;
    wire [3:0] cpu2rom_dout;

    wire [3:0] spi2rom_din;
    wire [3:0] mxd_rom_din;

    wire [7:0] spi2rom_add;
    wire [7:0] cpu2rom_add;
    wire [7:0] mxd_rom_add;

    wire spi2rom_we;
    wire mxd_rom_we;
  
    wire [25:0] div_clk;
    
    //instantiations:
    sync_ram #(.DATA_WIDTH(1), .ADD_WIDTH(8)) my_ram
    (.clk(mxd_mem_clk), .we(mxd_ram_we), .datain(mxd_ram_din), .address(mxd_ram_add), .dataout(cpu2ram_dout));

    sync_ram #(.DATA_WIDTH(4), .ADD_WIDTH(8)) my_rom
    (.clk(mxd_mem_clk), .we(mxd_rom_we), .datain(mxd_rom_din), .address(mxd_rom_add), .dataout(cpu2rom_dout));

    post_spictrl #(.CLK_SEL(SPI_CLK_SEL)) my_PostSPI_ctrl
    (
    .CLK(CLK), .RST(RST),
    .CS(SPI_CS), .MOSI(SPI_MOSI), .SCK(SPI_SCK),
    .MISO(SPI_MISO),
    .CIN(spi2rom_dout),
    .COUT(spi2rom_din),
    .CADD(spi2rom_add),
    .CWE(spi2rom_we),
    .DIN(spi2ram_dout),
    .DOUT(spi2ram_din),        
    .DADD(spi2ram_add),
    .DWE(spi2ram_we),
    .PCLK(prog_clk)    
    );    
    
    Post_cpu my_cpu
   (
    .clk(cpu_clk), .reset(RST),
    .run(run_sig),
    .state(STATE),
    .code_add(cpu2rom_add),
    .code(cpu2rom_dout),
    .data_add(cpu2ram_add),
    .din(cpu2ram_dout),
    .dout(cpu2ram_din),
    .data_we(cpu2ram_we)
   );

    Bin_CounterN #(.N(26)) my_counter
      (.clk(CLK), .reset(RST), .q(div_clk));
      
    deboucing_3tics my_deboucing
        (.clk(cpu_clk), .rst(RST), .x(RUN), .y(exec_cln));

    pulse_generator my_pulse
        (.clk(cpu_clk), .reset(RST), .trigger(exec_cln), .p(run_sig));

  // interconnection logic:
    assign spi2ram_dout = cpu2ram_dout;
    assign spi2rom_dout = cpu2rom_dout;
  
  // multiplexors logic:
    assign mxd_ram_din = (MODE) ? cpu2ram_din : spi2ram_din;
    assign mxd_ram_add = (MODE) ? cpu2ram_add : spi2ram_add;
    assign mxd_ram_we = (MODE) ? cpu2ram_we :  spi2ram_we;
    assign mxd_rom_din =  (MODE) ? 4'b0000 : spi2rom_din;
    assign mxd_rom_add = (MODE) ? cpu2rom_add : spi2rom_add;
    assign mxd_rom_we = (MODE) ? 1'b0 :  spi2rom_we;
    assign mxd_mem_clk = (MODE) ? mem_clk :  prog_clk;
  
   //16 to 1 multiplexor for timing:
     assign cpu_clk = CPU_CLK_SEL[3] ?
                 (CPU_CLK_SEL[2] ? (CPU_CLK_SEL[1] ? (CPU_CLK_SEL[0] ? div_clk[25] : div_clk[24]) : (CPU_CLK_SEL[0] ? div_clk[23] : div_clk[22])) 
                                :
                               (CPU_CLK_SEL[1] ? (CPU_CLK_SEL[0] ? div_clk[21] : div_clk[20]) : (CPU_CLK_SEL[0] ? div_clk[19] : div_clk[18]))) 
                  :
                 (CPU_CLK_SEL[2] ? (CPU_CLK_SEL[1] ? (CPU_CLK_SEL[0] ? div_clk[17] : div_clk[16]) : (CPU_CLK_SEL[0] ? div_clk[15] : div_clk[14])) 
                                :
                               (CPU_CLK_SEL[1] ? (CPU_CLK_SEL[0] ? div_clk[13] : div_clk[12]) : (CPU_CLK_SEL[0] ? div_clk[11] : div_clk[10])));

    assign mem_clk = ~cpu_clk;
  
endmodule
