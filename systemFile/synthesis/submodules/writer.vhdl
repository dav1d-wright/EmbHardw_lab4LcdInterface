library ieee;
use ieee.std_logic_1164.all;

entity writer is
    port
    (
        Clk_CI:         	in std_logic;
        Address_DI:     	in std_logic_vector (2 downto 0);
        Write_SI:		    in std_logic;
        WriteData_DI:       in std_logic_vector (7 downto 0);
              
        -- Register write from CPU
        RegDir_DO:          out std_logic_vector (7 downto 0);
        RegPort_DIO:        inout std_logic_vector (7 downto 0)
    );
end writer;

architecture behavioural of writer is
begin    
    pRegWrite: process(Clk_CI)
    begin        
        if (Clk_CI'event and (Clk_CI = '1')) then            
            if (Write_SI = '1') then 
                case Address_DI is
                    when "000" => RegDir_DO <= WriteData_DI;
                    when "010" => RegPort_DIO <= WriteData_DI;
                    when "011" => RegPort_DIO <= RegPort_DIO or WriteData_DI;
                    when "100" => RegPort_DIO <= RegPort_DIO and not WriteData_DI;
                    when others => null;
                end case;
            end if;
        end if;
    end process pRegWrite;
end behavioural;