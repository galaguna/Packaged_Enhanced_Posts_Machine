--=============================================================================
-- Entidad integradora para el sistema de procesamiento MPM (CPU Post) con una tarjeta Basys3
-- *Esta version incorpora comunicacion SPI para la escritura/lectura
--  de los espacios de programa y datos.
--=============================================================================
-- Codigo beta que emplea el reloj de 100 MHz de la tarjeta Basys:
--      * El reloj del CPU se configura en el orden de las decimas de segundo 
--        (.CPU_CLK_SEL(10) en modulo Post_sys_speed_cnfg)
--      * La velocidad para la comunicacion SPI se configura para producir una 
--        senial SCK=191 Hz (en realidad, 190.8 Hz)
--        (.SPI_CLK_SEL(15) en modulo Post_sys_speed_cnfg)  
--=============================================================================
-- Author: Gerardo A. Laguna S.
-- Universidad Autonoma Metropolitana
-- Unidad Lerma
-- 11.agosto.2025
-------------------------------------------------------------------------------
-- Library declarations
-------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------
-- Entity declaration
-------------------------------------------------------------------------------
entity Basys3_system is
port (

  --Basys3 Resources
  btnC          : in std_logic; -- sys_rst 
  btnR          : in std_logic; -- run_sig 
  sysclk        : in std_logic;
  led           : out std_logic_vector(15 downto 0);
  sw            : in std_logic_vector(15 downto 0);
  seg           : out std_logic_vector(6 downto 0);
  an            : out std_logic_vector(3 downto 0);
  SLV_CS        : in std_logic;
  SLV_MOSI      : in std_logic;
  SLV_MISO      : out std_logic;
  SLV_SCK       : in std_logic   
);
end Basys3_system;

architecture my_arch of Basys3_system is

-------------------------------------------------------------------------------
-- Components declaration
-------------------------------------------------------------------------------
component Bin_CounterN is
   generic(N: natural);
   port(
      clk, reset: in std_logic;
      q: out std_logic_vector(N-1 downto 0)
   );
end component;

component hex2led
    Port ( 
      hex   : in std_logic_vector(3 downto 0);
      led   : out std_logic_vector(6 downto 0 )
  );
end component;

component Post_sys_speed_cnfg is
    generic (CPU_CLK_SEL: natural; SPI_CLK_SEL: natural);
port (
  CLK          : in std_logic;
  RST          : in std_logic; 
  RUN          : in std_logic;  
  MODE         : in std_logic;
  STATE        : out std_logic_vector(3 downto 0);
  SPI_CS       : in std_logic;
  SPI_MOSI     : in std_logic;
  SPI_MISO     : out std_logic;
  SPI_SCK      : in std_logic   
);
end component;

-------------------------------------------------------------------------------
-- Signal declaration
-------------------------------------------------------------------------------
signal usrclk        : std_logic_vector(15 downto 0); -- Senales de reloj  
signal sys_rst       : std_logic;
signal mode          : std_logic;
signal exec          : std_logic;
signal disp_ref_clk  : std_logic;
signal disp_driver   : std_logic_vector(6 downto 0); -- Disp. 7 segmentos LED  
signal state_nibble  : std_logic_vector(3 downto 0);

-------------------------------------------------------------------------------
-- Begin
-------------------------------------------------------------------------------
begin

   my_Post_Sys : Post_sys_speed_cnfg
    generic map(CPU_CLK_SEL => 10, SPI_CLK_SEL=>15)  
   port map(
      CLK => sysclk,
      RST => sys_rst, 
      RUN => exec,  
      MODE => mode,
      STATE => state_nibble,
      SPI_CS => SLV_CS,
      SPI_MOSI => SLV_MOSI,
      SPI_MISO => SLV_MISO,
      SPI_SCK => SLV_SCK   
    );

    my_Counter : Bin_CounterN
     generic map(N => 16)  
     port map (
        clk => sysclk,
        reset => sys_rst,
        q => usrclk
    );

 -- Binary coded Hexa to 7 segments display:

    my_Display7seg : hex2led 
    port map (
          hex => state_nibble,
          led => disp_driver 
      );
             
-- Display logic:
    disp_ref_clk <= usrclk(15); 
    an <=  "0111";         
    seg <= disp_driver;

-- Conections:
    sys_rst <= btnC;
    exec <= btnR;  
    mode <= sw(15);
    
    led<= sw;   

end my_arch;
