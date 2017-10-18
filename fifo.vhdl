library ieee;
use ieee.std_logic_1164.all;

entity FIFO is
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
end FIFO;

architecture behavioural of FIFO is 
    type state_T                is (stateReset, stateEmpty, stateFilling, stateFull);
    type index_T                is range (SIZE-1 downto 0) of unsigned;
    type memory_T               is array (SIZE-1 downto 0) of std_logic_vector (15 downto 0);
    
    signal stateNext_D:         state_T;
    signal statePres_D:         state_T;
    
    signal data_D:              memory_T;
    signal numEl_D:             index_T := 0;
    signal head_D:              index_T := 0;
    signal tail_D:              index_T := 0;
begin
--------------------------------------------------------------------------------
---                                                                          ---
--- state machine                                                            ---
---                                                                          ---
--------------------------------------------------------------------------------
    nextState: process(Clk_CI, Reset_NRI, stateNext_D)
    begin
        if(Reset_NRI = '1')then
            statePres_D <= stateReset;
        elsif(Clk_CI'event and Clk_CI = '1')then
            statePres_D <= stateNext_D;
        end if;
    end process nextState;
    
    
    -- logic: process(Clk_CI, stateNext_D)
    -- begin
        -- stateNext_D <= statePres_D;
        -- case statePres_D is
            -- when stateReset =>
                -- Empty_SO <= '1';
                -- Full_SO <= '0';
                -- Data_DO <= 'Z';
                
                -- stateNext_D <= stateEmpty;
            -- when stateEmpty =>
                -- Empty_SO <= '1';
                -- Full_SO <= '0';    
                -- if(numEl_D /= 0)then
                    -- stateNext_D <= stateFilling;
                -- end if;
                
            -- when stateFilling =>
                -- Empty_SO <= '0';
                -- Full_SO <= '0';
                -- if(numEl_D = SIZE)then
                    -- stateNext_D <= stateFull;
                -- end if;
            -- when stateFull =>
                -- Empty_SO <= '0';
                -- Full_SO <= '1';
                -- if(numEl_D /= SIZE)then
                    -- stateNext_D <= stateFilling;
                -- end if;
        -- end case;
    -- end process logic;
    
    -- push: process(Clk_CI, Push_SI)
    -- begin
        -- if((statePres_D = stateFilling) or (statePres_D = stateEmpty))then
            -- if(Push_SI'event and Push_SI = '1')then
                -- if(numEl_D < SIZE)then
                    -- if(head_D < SIZE-1)then
                        -- head_D = head_D + 1;
                    -- else
                        -- head_D = 0;
                    -- end if;
                    
                    -- numEl_D = numEl_D + 1;
                    -- data_D(head_D) = Data_DI;                    
                -- end if;
            -- end if;
        -- end if;
    -- end process push;
    
    pop: process(Clk_CI)
    begin
        if((statePres_D = stateFilling) or (statePres_D = stateFull))then
            if(Pop_SI'event and Pop_SI = '1')then
                if(numEl_D > 0)then
                    Data_DO <= data_D(tail_D);                    

                    -- if(tail_D < SIZE-1)then
                        -- tail_D = tail_D + 1;
                    -- else
                        -- tail_D = 0;
                    -- end if;
                        
                    -- numEl_D = numEl_D - 1;
                end if;
            end if;
        end if;
    end process pop;
end behavioural;