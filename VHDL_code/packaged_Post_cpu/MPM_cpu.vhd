--=============================================================================
-- Entidad para la Maquina de Post Mejorada (CPU MPM) 
--=============================================================================
-- Version mejorada y actualizada:
--  - Se opera con memoria RAM propia (entidad sync_ram en myRAM.vhd) 
--    tanto para el espacio de código como el de datos.
--  - Se optimiza el codigo original y se simplifican los estados ASMD de conformidad
--    con la operacion mas simple de la memoria propia.
--  - El puerto de estado (state) se reduce de 8 a 4 bits.
--=============================================================================
-- Codigo para la monografia:
-- La Maquina de Post actualizada:
-- Diseno, puesta en marcha y programacion del 
-- prototipo de un pequeno CPU funcional
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
entity Post_cpu is
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
end Post_cpu;

architecture my_arch of Post_cpu is
-------------------------------------------------------------------------------
-- Constant declaration
-------------------------------------------------------------------------------

--*************************Machine states**************************************
   constant stop             :  std_logic_vector(3 downto 0):= "0000";
   constant start            :  std_logic_vector(3 downto 0):= "0001";
   constant fetch_decode     :  std_logic_vector(3 downto 0):= "0010";
   constant load_ha_jmp      :  std_logic_vector(3 downto 0):= "0011";
   constant load_la_jmp      :  std_logic_vector(3 downto 0):= "0100";
   constant jmp_exe          :  std_logic_vector(3 downto 0):= "0101";
   constant jz_exe           :  std_logic_vector(3 downto 0):= "0110";
   constant incdp_exe        :  std_logic_vector(3 downto 0):= "0111";
   constant decdp_exe        :  std_logic_vector(3 downto 0):= "1000";
   constant set_exe          :  std_logic_vector(3 downto 0):= "1001";
   constant clr_exe          :  std_logic_vector(3 downto 0):= "1010";

--*************************Instruction Op codes********************************
   constant nop_code         :  std_logic_vector(3 downto 0):= "0000";
   constant incdp_code       :  std_logic_vector(3 downto 0):= "0001";
   constant decdp_code       :  std_logic_vector(3 downto 0):= "0010";
   constant set_code         :  std_logic_vector(3 downto 0):= "0011";
   constant clr_code         :  std_logic_vector(3 downto 0):= "0100";
   constant jmp_code         :  std_logic_vector(3 downto 0):= "0101";
   constant jz_code          :  std_logic_vector(3 downto 0):= "0110";
   constant stop_code        :  std_logic_vector(3 downto 0):= "0111";

-------------------------------------------------------------------------------
-- Signal declaration
-------------------------------------------------------------------------------
   signal state_reg, state_next            : std_logic_vector(3 downto 0);
   signal IP_reg, IP_next                  : unsigned(7 downto 0);
   signal DP_reg, DP_next                  : unsigned(7 downto 0);
   signal instruction_reg, instruction_next: std_logic_vector(3 downto 0);
   signal hadd_reg, hadd_next              : unsigned(3 downto 0);
   signal ladd_reg, ladd_next              : unsigned(3 downto 0);
   signal bit_reg, bit_next                : std_logic;
   signal we_reg, we_next                  : std_logic;

-------------------------------------------------------------------------------
-- Begin
-------------------------------------------------------------------------------
begin
   -- state & data registers
   process(clk,reset)
   begin
      if (reset='1') then
         state_reg <= stop;
         IP_reg <= (others=>'0');
         DP_reg <= (others=>'0');
         instruction_reg <= (others=>'0');
         hadd_reg <= (others=>'0');
         ladd_reg <= (others=>'0');
         bit_reg <= '0';
         we_reg <= '0';
      elsif (clk'event and clk='1') then
         state_reg <= state_next;
         IP_reg <= IP_next;
         DP_reg <= DP_next;
         instruction_reg <= instruction_next;
         hadd_reg <= hadd_next;
         ladd_reg <= ladd_next;
         bit_reg <= bit_next;
         we_reg <= we_next;
      end if;
   end process;

   -- next-state logic & data path functional units/routing
   process(state_reg,run,code,din, 
           IP_reg,DP_reg,instruction_reg,hadd_reg,ladd_reg)
   begin
      IP_next <= IP_reg;
      DP_next <= DP_reg;
      instruction_next <= instruction_reg;
      hadd_next <= hadd_reg;
      ladd_next <= ladd_reg;

      case state_reg is
         when stop =>
            if run='1' then
               state_next <= start;
            else
               state_next <= stop;
            end if;
         when start =>
            IP_next <= (others=>'0');
            DP_next <= (others=>'0');
            state_next <= fetch_decode;
         when fetch_decode =>
            instruction_next <= code;
            IP_next <= IP_reg + 1;
            
            case code is
                when nop_code =>
                    state_next <= fetch_decode;
                when incdp_code=>
                    state_next <= incdp_exe;
                when decdp_code =>
                    state_next <= decdp_exe;
                when set_code =>
                    state_next <= set_exe;
                when clr_code => 
                    state_next <= clr_exe;                
                when jmp_code =>
                    state_next <= load_ha_jmp;
                when jz_code =>
                    state_next <= jz_exe;
                when others =>
                    state_next <=stop;
            end case;

         when load_ha_jmp => 
            IP_next <= IP_reg + 1;
            hadd_next <= unsigned(code);
            state_next <= load_la_jmp;
         when load_la_jmp =>
            ladd_next <= unsigned(code);
            state_next <= jmp_exe;
         when jmp_exe =>
            IP_next <= hadd_reg & ladd_reg;
            state_next <= fetch_decode;
         when jz_exe =>
            if din='0' then
               state_next <= load_ha_jmp;
            else
               IP_next <= IP_reg + 2;
               state_next <= fetch_decode;
            end if;
         when incdp_exe =>
            DP_next <= DP_reg + 1;
            state_next <=fetch_decode;
         when decdp_exe =>
            DP_next <= DP_reg - 1;
            state_next <=fetch_decode;
         when set_exe =>
            state_next <=fetch_decode;
         when clr_exe =>
            state_next <=fetch_decode;
         when others =>
            state_next <=stop;
      end case;
   end process;

   -- look-ahead output logic
   --Para las seniales deben mostrar el estado deseado justo al iniciar el siguiente estado.
   process(state_next)
   begin
      we_next <= '0';
      bit_next <= '0';
      
      case state_next is
         when set_exe =>
            bit_next <= '1';
            we_next <= '1';
         when clr_exe =>
            bit_next <= '0';
            we_next <= '1';
         when others =>         
      end case;
   end process;

   --  outputs
   state <= state_reg;
   code_add <= std_logic_vector(IP_reg);
   data_add <= std_logic_vector(DP_reg);
   dout <= bit_reg;
   data_we <= we_reg;

end my_arch;
