library ieee;
use ieee.std_logic_1164.all;

entity D_FF is
    generic (WIDTH:              natural := 16);
    port
    (
        Reset_NRI:      in std_logic;
        Set_SI:         in std_logic;
        D_DI:           in std_logic_vector (WIDTH-1 downto 0);
        Q_DO:           out std_logic_vector(WIDTH-1 downto 0)
    );
end entity D_FF;

architecture behavioural of D_FF is
    signal Set_Edge_D:            std_logic := '0';
    signal Set_Last_D:            std_logic := '0';
begin
    process(Reset_NRI, Set_SI)
    begin
        if(Reset_NRI = '0')then
            Q_DO <= (others => '0');
        elsif(Set_SI'event and Set_SI = '1')then
            Q_DO <= D_DI;
        end if;
    end process;
end behavioural;