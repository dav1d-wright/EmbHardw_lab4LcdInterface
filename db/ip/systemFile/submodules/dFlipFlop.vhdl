library ieee;
use ieee.std_logic_1164.all;

entity D_FF is
    generic (WIDTH:              natural := 16);
    port
    (
        Clk_CI:         in std_logic;
        Reset_NRI:      in std_logic;
        Set_SI:         in std_logic;
        D_DI:           in std_logic_vector (WIDTH-1 downto 0);
        Q_DO:           out std_logic_vector(WIDTH-1 downto 0)
    );
end entity D_FF;

architecture behavioural of D_FF is
begin
	process(Reset_NRI, Clk_CI)
    begin
        if(Reset_NRI = '0')then
            Q_DO <= (others => '0');
        elsif(Clk_CI'event and Clk_CI = '1')then
            if(Set_SI = '1')then
                Q_DO <= D_DI;
            end if;
        end if;
    end process;
end behavioural;