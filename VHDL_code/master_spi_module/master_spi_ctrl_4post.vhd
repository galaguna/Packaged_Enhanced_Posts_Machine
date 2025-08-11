
--=============================
-- master_spi_ctrl_4post.vhd
--=============================
-- El hardware sintetizado fue probado con el reloj del sistema 
-- de 100MHz y funciono bien.
-- La velocidad maxima generada para la senal SCK fue de 12.5 MHz, alimentando
-- las senales de reloj con el reloj del sistema, sin division de frecuencia. 
-- La expresion para calcular la velocidad de SCK es la siguiente:
-- f_sck= clk/8
--=============================================================================
-- Author: Gerardo Laguna
-- UAM lerma
-- Mexico
-- 11/08/2025
--
--=============================================================================
-------------------------------------------------------------------------------------
-- Library declarations
-------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------------
-- Entity declaration
-------------------------------------------------------------------------------------
entity master_spictrl_4post is
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
end master_spictrl_4post;

architecture arch of master_spictrl_4post is
----------------------------------------------------------------------------------------------------
-- Components declaration
----------------------------------------------------------------------------------------------------
component Bin_CounterN is
   generic(N: natural);
   port(
      clk, reset: in std_logic;
      q: out std_logic_vector(N-1 downto 0)
   );
end component;

component pulse_generator is
   port(
      clk, reset  : in std_logic;
      trigger     : in std_logic;
      p           : out std_logic
   );
end component;

component master_spi4post is
   port(
      CLK, RST: in std_logic;
      CS, MOSI, SCK: out std_logic;
      MISO: in std_logic;
      Tx_word: in std_logic_vector(15 downto 0);
      Rx_word: out std_logic_vector(15 downto 0);
      Go: in std_logic;
      Busy: out std_logic
  );
end component;

----------------------------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------------------------
signal clk_sel       : std_logic_vector(3 downto 0);
signal div_clk       : std_logic_vector(15 downto 0);
signal loc_clk       : std_logic;
signal one_pulse     : std_logic;

----------------------------------------------------------------------------------------------------
-- Architecture body
----------------------------------------------------------------------------------------------------

begin

my_Counter : Bin_CounterN
  generic map(N => 16)  
  port map (
    clk => CLK,
    reset => RST,
    q => div_clk
  );
  
    
my_pulse: pulse_generator
  port map(
    clk => loc_clk, 
    reset => RST,
    trigger => GO,
    p => one_pulse
  );

my_master_spi : master_spi4post  
  port map (
    CLK => loc_clk, 
    RST => RST,
    CS => CS, 
    MOSI => MOSI, 
    SCK => SCK,
    MISO => MISO,
    Tx_word => TX_W,
    Rx_word => RX_W,
    Go => one_pulse,
    Busy => BUSY
  );

  clk_sel <= std_logic_vector(to_unsigned(CLK_DIVISOR, clk_sel'length));
    
  with clk_sel select
   loc_clk  <=  div_clk(0) when x"0",  
                div_clk(1) when x"1",
                div_clk(2) when x"2",
                div_clk(3) when x"3",
                div_clk(4) when x"4",
                div_clk(5) when x"5",
                div_clk(6) when x"6",
                div_clk(7) when x"7",
                div_clk(8) when x"8",
                div_clk(9) when x"9",
                div_clk(10) when x"A",
                div_clk(11) when x"B",
                div_clk(12) when x"C",
                div_clk(13) when x"D",
                div_clk(14) when x"E",
                div_clk(15) when x"F";
    
end arch;