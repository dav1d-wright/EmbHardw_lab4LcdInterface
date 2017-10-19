library ieee;
use ieee.std_logic_1164.all;

entity testbenchFifo is
end testbenchFifo;

architecture behavioural of testbenchFifo is
    component FIFO
        generic (SIZE:              natural := 256);
        port
        (
        Clk_CI:         	    in std_logic;
        Reset_NRI:      	    in std_logic;
        Push_SI:                in std_logic;
        Pop_SI:                 in std_logic;
        Data_DI:                in std_logic_vector (15 downto 0);
        Data_DO:                out std_logic_vector (15 downto 0);
        Full_SO:                out std_logic;
        Empty_SO:               out std_logic
        );
    end component;

   --declare inputs and initialize them
    -- communication between CPU and LcdDriver
    signal Clk_S:               std_logic;
    signal Reset_NR:            std_logic;
    signal Push_S:              std_logic;
    signal Pop_S:               std_logic;
    signal DataPush_D:          std_logic_vector (15 downto 0);
    signal DataPop_D:           std_logic_vector (15 downto 0);
    signal Full_S:              std_logic;
    signal Empty_S:             std_logic; 
    
    
    signal Time_S:               time := 0 ns;

    constant TimeMax_C:          time := 1000 ns;
    constant Clk_period_C :      time := 20 ns;
begin   
    DUT: FIFO port map(
                            Clk_CI => Clk_S,	    
                            Reset_NRI => Reset_NR,      	    
                            Push_SI => Push_S,    
                            Pop_SI => Pop_S,                     
                            Data_DI => DataPush_D,                       
                            Data_DO => DataPop_D,                             
                            Full_SO => Full_S,                            
                            Empty_SO => Empty_S                 
                            );

   clk_process : process
   begin
        if(Time_S < TimeMax_C)then
            Clk_S <= '0';
            wait for Clk_period_C/2;
            Clk_S <= '1';
            wait for Clk_period_C/2;
            Time_S <= Time_S + Clk_period_C;
        else
            wait;
        end if;
   end process;
   
   -- Stimulus process
  stim_proc: process
   begin         
        wait for 7 ns;
            Reset_NR <='0';
        wait for Clk_period_C;
            Reset_NR <= '1';
            Push_S <= '0';
            Pop_S <= '0';
        wait for Clk_period_C;
            DataPush_D <= (others => '1');
            Push_S <= '1';
            Push_S <= '0';
        wait for Clk_period_C;        
            Pop_S <= '1';
        wait;
  end process;
end;
