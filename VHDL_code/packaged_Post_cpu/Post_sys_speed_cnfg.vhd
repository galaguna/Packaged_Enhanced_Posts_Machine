--=============================================================================
-- Entidad Post_sys_speed_cnfg con CPU Post, memoria y comunicacion SPI
-- * En esta version de puede configurar tanto la velocidad del reloj del CPU 
--   como la de la senial SCK del modulo SPI.
--  - El puerto de estado (state) se reduce de 8 a 4 bits.
--=============================================================================
-- Codigo beta 
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
  use ieee.numeric_std.all;

-------------------------------------------------------------------------------
-- Entity declaration
-------------------------------------------------------------------------------
entity Post_sys_speed_cnfg is
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
end Post_sys_speed_cnfg;

architecture my_arch of Post_sys_speed_cnfg is

-------------------------------------------------------------------------------
-- Components declaration
-------------------------------------------------------------------------------
component deboucing_3tics is
   port(
      clk   : in std_logic;
      rst   : in std_logic;
      x     : in std_logic;
      y     : out std_logic
   );
end component;

component pulse_generator is
   port(
      clk, reset  : in std_logic;
      trigger     : in std_logic;
      p           : out std_logic
   );
end component;

component Bin_CounterN is
   generic(N: natural);
   port(
      clk, reset: in std_logic;
      q: out std_logic_vector(N-1 downto 0)
   );
end component;

component sync_ram is
 generic(DATA_WIDTH: natural; ADD_WIDTH: natural);
 port (
    clock   : in  std_logic;
    we      : in  std_logic;
    address : in  std_logic_vector;
    datain  : in  std_logic_vector;
    dataout : out std_logic_vector
  );
end component;

component Post_cpu
   port(
      clk, reset : in std_logic;
      run        : in std_logic;
      state      : out std_logic_vector(3 downto 0);
      code_add   : out std_logic_vector(7 downto 0);
      code       : in std_logic_vector(3 downto 0);
      data_add   : out std_logic_vector(7 downto 0);
      din        : in std_logic;
      dout       : out std_logic;
      data_we    : out std_logic
  );
end component;

component post_spictrl is
    generic (CLK_DIVISOR: natural);
   port(
      CLK, RST: in std_logic;
      CS, MOSI, SCK: in std_logic;
      MISO: out std_logic;
      CIN: in std_logic_vector(3 downto 0);
      COUT: out std_logic_vector(3 downto 0);
      CADD: out std_logic_vector(7 downto 0);
      CWE: out std_logic;
      DIN: in std_logic;
      DOUT: out std_logic;
      DADD: out std_logic_vector(7 downto 0);
      DWE: out std_logic;
      PCLK: out std_logic
  );
end component;

-------------------------------------------------------------------------------
-- Signal declaration
-------------------------------------------------------------------------------
signal btnR_cln      : std_logic;
signal run_sig       : std_logic;

signal clk_sel       : std_logic_vector(3 downto 0);
signal div_clk       : std_logic_vector(25 downto 0);
signal post_clk      : std_logic;

signal cpu2ram_dout  : std_logic;
signal spi2ram_dout  : std_logic;

signal cpu2ram_din   : std_logic;
signal mxd_ram_din   : std_logic;
signal spi2ram_din   : std_logic;

signal cpu2ram_add   : std_logic_vector(7 downto 0);
signal mxd_ram_add   : std_logic_vector(7 downto 0);
signal spi2ram_add   : std_logic_vector(7 downto 0);

signal cpu2ram_we    : std_logic;
signal mxd_ram_we    : std_logic;
signal spi2ram_we    : std_logic;

signal cpu2rom_dout  : std_logic_vector(3 downto 0);
signal spi2rom_dout  : std_logic_vector(3 downto 0);

signal mxd_rom_din   : std_logic_vector(3 downto 0);
signal spi2rom_din   : std_logic_vector(3 downto 0);

signal cpu2rom_add   : std_logic_vector(7 downto 0);
signal mxd_rom_add   : std_logic_vector(7 downto 0);
signal spi2rom_add   : std_logic_vector(7 downto 0);

signal mxd_rom_we    : std_logic;
signal spi2rom_we    : std_logic;

signal mem_clk       : std_logic;
signal mxd_mem_clk   : std_logic;
signal prog_clk      : std_logic;

-------------------------------------------------------------------------------
-- Begin
-------------------------------------------------------------------------------
begin

  my_Counter : Bin_CounterN
    generic map(N => 26)  
    port map (
      clk => CLK,
      reset => RST,
      q => div_clk
    );
  
my_deboucing : deboucing_3tics 
   port map(
      clk => post_clk,
      rst => RST,
      x => RUN,
      y => btnR_cln
   );


my_pulse : pulse_generator 
   port map(
      clk  => post_clk, 
      reset => RST,
      trigger => btnR_cln,
      p => run_sig
   );

   my_Post_Machine : Post_cpu
   port map(
      clk => post_clk, 
      reset => RST,
      run  => run_sig,
      state => STATE,
      code_add => cpu2rom_add,
      code => cpu2rom_dout,
      data_add => cpu2ram_add,
      din => cpu2ram_dout,
      dout => cpu2ram_din,
      data_we => cpu2ram_we
  );


  mySpiCtrl : post_spictrl
    generic map(CLK_DIVISOR => SPI_CLK_SEL)  
    port map (
        CLK => CLK, 
        RST => RST,
        CS => SPI_CS, 
        MOSI => SPI_MOSI, 
        SCK => SPI_SCK,
        MISO => SPI_MISO,
        CIN => spi2rom_dout,
        COUT => spi2rom_din,
        CADD => spi2rom_add,
        CWE => spi2rom_we,
        DIN => spi2ram_dout,
        DOUT => spi2ram_din,
        DADD => spi2ram_add,
        DWE => spi2ram_we,
        PCLK => prog_clk
  );

  my_RAM : sync_ram
      generic map(DATA_WIDTH => 1, 
      ADD_WIDTH => 8)
      port map (
          clock   => mxd_mem_clk,
          we      => mxd_ram_we,
          address => mxd_ram_add,
          datain(0)  => mxd_ram_din,
          dataout(0) => cpu2ram_dout
      );
  
    my_ROM : sync_ram
      generic map(DATA_WIDTH =>4, 
      ADD_WIDTH => 8)
      port map (
          clock   => mxd_mem_clk,
          we      => mxd_rom_we,
          address => mxd_rom_add,
          datain  => mxd_rom_din,
          dataout => cpu2rom_dout
      );


-- RAM's multiplexed control:
  mxd_ram_din <= cpu2ram_din when (MODE = '1') else
                  spi2ram_din;

  mxd_ram_add <= cpu2ram_add when (MODE = '1') else
                  spi2ram_add;

  mxd_ram_we <= cpu2ram_we when (MODE = '1') else 
                  spi2ram_we;

  mxd_rom_din <=  (others => '0') when (MODE = '1') else
                  spi2rom_din;

  mxd_rom_add <= cpu2rom_add when (MODE = '1') else
                  spi2rom_add;

  mxd_rom_we <= '0' when (MODE = '1') else 
                  spi2rom_we;

  mxd_mem_clk <= mem_clk when (MODE = '1') else 
                  prog_clk;

-- Conections:
  mem_clk <= not post_clk;
    
  spi2ram_dout <= cpu2ram_dout;
  spi2rom_dout <= cpu2rom_dout;

  clk_sel <= std_logic_vector(to_unsigned(CPU_CLK_SEL, clk_sel'length));
    
  with clk_sel select
   post_clk  <=  div_clk(10) when x"0",  
                div_clk(11) when x"1",
                div_clk(12) when x"2",
                div_clk(13) when x"3",
                div_clk(14) when x"4",
                div_clk(15) when x"5",
                div_clk(16) when x"6",
                div_clk(17) when x"7",
                div_clk(18) when x"8",
                div_clk(19) when x"9",
                div_clk(20) when x"A",
                div_clk(21) when x"B",
                div_clk(22) when x"C",
                div_clk(23) when x"D",
                div_clk(24) when x"E",
                div_clk(25) when x"F";

end my_arch;
