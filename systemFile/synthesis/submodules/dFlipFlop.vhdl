library ieee;
use ieee.std_logic_1164.all;

entity D_FF is
    port
    (
        Clk_CI:         in std_logic;
        Reset_BRI:      in std_logic;
        D_DI:           in std_logic_vector (7 downto 0);
        Q_DO:           out std_logic_vector(7 downto 0)
    );
end entity D_FF;

architecture behavioural of D_FF is
begin
	reset: process(Reset_BRI)
    begin
        if(Reset_BRI = '0')then
            Q_DO <= (others => '0');
        end if;
    end process reset;
    
    process(Clk_CI)
    begin
        if(Clk_CI'event and Clk_CI = '1')then
            Q_DO <= D_DI;
        end if;
    end process;
end behavioural;