library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

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
    type memory_T               is array (SIZE-1 downto 0) of std_logic_vector (15 downto 0);
    
    signal stateNext_D:         state_T;
    signal statePres_D:         state_T;
    
    signal data_D:              memory_T;
    signal numEl_D:             integer;
    signal head_D:              integer;
    signal tail_D:              integer;
    
    -- edge detection of Push_SI and Pop_SI
    signal Push_Edge_D:        std_logic;
    signal Push_Last_D:        std_logic;
    
    signal Pop_Edge_D:         std_logic; 
    signal Pop_Last_D:         std_logic;
begin

    -- edgeDetect: process(Reset_NRI, Clk_CI)
    -- begin
        -- if(Clk_CI'event and Clk_CI = '1')then
            -- if(Reset_NRI = '0')then
                -- Pop_Edge_D <= '0';
                -- Push_Edge_D <= '0';
            -- elsif(Clk_CI'event and Clk_CI = '1')then
                -- Pop_Edge_D <=  Pop_SI and (not Pop_Last_D);
                -- Pop_Last_D <=  Pop_SI;
                
                -- Push_Edge_D <= Push_SI and (not Push_Last_D);
                -- Push_Last_D <= Push_SI;
            -- end if;
        -- end if;
    -- end process edgeDetect;
--------------------------------------------------------------------------------
---                                                                          ---
--- state machine                                                            ---
---                                                                          ---
--------------------------------------------------------------------------------
    nextState: process(Clk_CI, Reset_NRI)
    begin
        if(Reset_NRI = '0')then
            statePres_D <= stateReset;
        elsif(Clk_CI'event and Clk_CI = '1')then
            statePres_D <= stateNext_D;
        end if;
    end process nextState;
    
    
    logic: process(statePres_D, Push_SI, Pop_SI)
    begin
        case statePres_D is
            when stateReset =>
                Empty_SO <= '1';
                Full_SO <= '0';
                Data_DO <= (others => 'Z');
                numEl_D <= 0;
                head_D <= 0;
                tail_D <= 0;
                
                stateNext_D <= stateEmpty;
            when stateEmpty =>
                Empty_SO <= '1';
                Full_SO <= '0'; 
                numEl_D <= 0;
                Data_DO <= (others => 'Z');
                
                if(Push_SI = '1')then
                    if(numEl_D < SIZE)then
                        if(head_D < SIZE-1)then
                            head_D <= head_D + 1;
                        else
                            head_D <= 0;
                        end if;
                        
                        numEl_D <= 1;
                        data_D(head_D) <= Data_DI;
                    else
                        head_D <= head_D;
                        numEl_D <= 0;
                        data_D(head_D) <= data_D(head_D);
                    end if;
                else
                    head_D <= head_D;
                    numEl_D <= 0;
                    data_D(head_D) <= data_D(head_D);
                end if;
                
                if(numEl_D /= 0)then
                    stateNext_D <= stateFilling;
                else  
                    stateNext_D <= stateEmpty;
                end if;
                
            when stateFilling =>
                Empty_SO <= '0';
                Full_SO <= '0';
                numEl_D <= numEl_D;
                
                if(Push_SI = '1')then
                    if(numEl_D < SIZE)then
                        if(head_D < SIZE-1)then
                            head_D <= head_D + 1;
                        else
                            head_D <= 0;
                        end if;
                        
                        numEl_D <= numEl_D + 1;
                        data_D(head_D) <= Data_DI;                    
                    end if;
                else
                    head_D <= head_D;
                    numEl_D <= numEl_D;
                    data_D(head_D) <= data_D(head_D);
                end if;
                
                if(Pop_SI = '1')then
                    if(numEl_D > 0)then
                        Data_DO <= data_D(tail_D);                    

                        if(tail_D < SIZE-1)then
                            tail_D <= tail_D + 1;
                        else
                            tail_D <= 0;
                        end if;
                            
                        numEl_D <= numEl_D - 1;
                    else
                        Data_DO <= (others => 'Z');
                        tail_D <= tail_D;
                        numEl_D <= numEl_D;
                    end if;
                end if;
                
                if(numEl_D = SIZE)then
                    stateNext_D <= stateFull;
                elsif(numEl_D = 0)then
                    stateNext_D <= stateEmpty;
                else
                    stateNext_D <= stateFilling;
                end if;
                
            when stateFull =>
                numEl_D <= numEl_D;
                Empty_SO <= '0';
                Full_SO <= '1';
                
                if(numEl_D /= SIZE)then
                    stateNext_D <= stateFilling;
                else
                    stateNext_D <= stateFull;
                end if;
                
            when others =>
                Empty_SO <= '1';
                Full_SO <= '0';
                Data_DO <= (others => 'Z');
                numEl_D <= 0;
                head_D <= 0;
                tail_D <= 0;
                stateNext_D <= stateReset;
        end case;
    end process logic;
end behavioural;