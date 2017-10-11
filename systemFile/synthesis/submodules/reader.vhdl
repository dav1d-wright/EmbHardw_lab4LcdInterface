library ieee;
use ieee.std_logic_1164.all;

entity reader is
    port
    (
        Clk_CI:         	in std_logic;
        Address_DI:     	in std_logic_vector (2 downto 0);
        Read_SI:		    in std_logic;
              
        -- Register write from CPU
        RegDir_DI:          in std_logic_vector (7 downto 0);
        RegPort_DI:         in std_logic_vector (7 downto 0);
        RegPin_DI:          in std_logic_vector (7 downto 0);
        
        -- ReadData output
        ReadData_DO:        out std_logic_vector (7 downto 0)
    );
end reader;

architecture behavioural of reader is
begin                
    ReadData_DO <= 
        RegDir_DI when Address_DI = "000" and Read_SI = '1' else
        RegPin_DI when Address_DI = "001" and Read_SI = '1' else        
        RegPort_DI when Address_DI = "010" and Read_SI = '1' else
        (others => '0');
end behavioural;