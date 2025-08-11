
--=============================================================================
-- Entidad integradora para el sistema SPI maestro para CPU Post con una tarjeta Basys3
--=============================================================================
--
-- El hardware sintetizado fue probado con el reloj del sistema 
-- de 100MHz y funciono bien, tanto el modulo maestro como el esclavo.
-- Se emplea la entidad master_spictrl que incluye un divisor de frecuencia 
-- para el reloj del sistema:
--  *El parametro CLK_DIVISOR es un valor entero en [0 : 15]
--   - Con CLK_DIVISOR=0 se obtiene una frecuencia en SCK de 6.25 MHz
--   - Con CLK_DIVISOR=15 se obtiene una frecuencia en SCK de 190.7 Hz
--
--=============================================================================
-- Codigo para probar el componente master_spictrl_4post
-- con deboucing en boton de disparo.
--=============================================================================
-- Author: Gerardo Laguna
-- UAM lerma
-- Mexico
-- 11/08/2025
--=============================================================================
-------------------------------------------------------------------------------------
-- Library declarations
-------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------------
-- Entity declaration
-------------------------------------------------------------------------------------
entity my_basys3 is
   port(
    --Basys Resources
    sysclk        : in std_logic;
    btnC          : in std_logic; -- sys_rst 
    btnR          : in std_logic; -- Go
    led           : out std_logic_vector(15 downto 0);
    sw            : in std_logic_vector(15 downto 0);
    MST_CS        : out std_logic;
    MST_MOSI      : out std_logic;
    MST_MISO      : in std_logic;
    MST_SCK       : out std_logic   
    );
end my_basys3;

architecture tst_arch of my_basys3 is
----------------------------------------------------------------------------------------------------
-- Components declaration
----------------------------------------------------------------------------------------------------

component deboucing_3tics is
   port(
      clk   : in std_logic;
      rst   : in std_logic;
      x     : in std_logic;
      y     : out std_logic
   );
end component;

component master_spictrl_4post is
    generic (CLK_DIVISOR: natural);
   port(
      CLK, RST: in std_logic;
      CS, MOSI, SCK: out std_logic;
      MISO: in std_logic;
      TX_W: in std_logic_vector(15 downto 0);
      RX_W: out std_logic_vector(15 downto 0);
      GO: in std_logic;
      BUSY: out std_logic
  );
end component;

----------------------------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------------------------
signal sys_rst       : std_logic;
signal run_sig       : std_logic;
signal go_sig        : std_logic;

----------------------------------------------------------------------------------------------------
-- Architecture body
----------------------------------------------------------------------------------------------------

begin

my_deboucing: deboucing_3tics
       port map(
          clk => sysclk,
          rst => sys_rst,
          x => run_sig,
          y => go_sig
       );
    
    
U01 : master_spictrl_4post
  generic map(CLK_DIVISOR => 15)  
  PORT MAP (
    CLK => sysclk, 
    RST => sys_rst,
    CS => MST_CS, 
    MOSI => MST_MOSI, 
    SCK => MST_SCK,
    MISO => MST_MISO,
    TX_W => sw,
    RX_W => led,
    GO => go_sig,
    BUSY => open
  );

-- interconnection logic:
    sys_rst <= btnC;
    run_sig <= btnR;
    

    
end tst_arch;