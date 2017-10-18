library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LcdDriver is
    port
    (
        -- communication between CPU and LcdDriver
        Clk_CI:         	    in std_logic;
        Reset_NRI:      	    in std_logic;
        Address_DI:     	    in std_logic_vector (15 downto 0);
        Write_SI:       	    in std_logic;
        WriteData_DI:		    in std_logic_vector (15 downto 0);
        Read_SI:		        in std_logic;
        ByteEnable_DI:          in std_logic_vector (15 downto 0);
        BeginBurstTransfer_DI:  in std_logic;
        BurstCount_DI:          in std_logic_vector (7 downto 0);
        
        WaitReq_SO:             out std_logic;
        ReadData_DO:		    out std_logic_vector (15 downto 0);
        
      
        -- communication from LcdDriver to LCD
        DB_DIO:      		    inout std_logic_vector (15 downto 0);
        Rd_NSO:                 out std_logic;
        Wr_NSO:                 out std_logic;
        Cs_NSO:                 out std_logic;
        DC_NSO:                 out std_logic;
        LcdReset_NRO:           out std_logic;
        IM0_SO:                 out std_logic
    );
end LcdDriver;

architecture LCD of LcdDriver is 
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


    -- State macine types & signals
    type RxState_T              is (RxStateReset, RxStateIdle, RxStateRxWord, RxStateRxBurst);
    type TxState_T              is (TxSTateReset, TxStateIdle, TxStateTx);
    
    signal RxStateNext_D:       RxState_T;
    signal TxStateNext_D:       TxState_D;

    signal RxStatePres_D:       RxState_T;
    signal TxStatePres_D:       TxState_D;   

    -- FIFO signals
    signal Pop_S:               std_logic;
    signal Push_S:              std_logic;
    signal RxData_D:            std_logic_vector (15 downto 0);
    signal TxData_D:            std_logic_vector (15 downto 0);
    signal FifoFull_D:          std_logic;
    signal FifoEmpty_D:         std_logic;
    
begin
    dataBuffer: FIFO generic map(256) port map(Clk_CI => Clk_CI,
                                                Reset_NRI => Reset_NRI,
                                                Push_SI => Push_S,
                                                Pop_SI => Pop_S, 
                                                Data_DI => RxData_D,
                                                Data_DO => TxData_D
                                                Full_SO => FifoFull_D,
                                                Empty_SO => FifoEmpty_D);
--------------------------------------------------------------------------------
---                                                                          ---
--- Receiver state machine                                                   ---
---                                                                          ---
--------------------------------------------------------------------------------
    nextStateRx: process(Clk_CI, Reset_NRI, RxStateNext_D)
    begin
        if(Reset_NRI = '1')then
            RxStatePres_D <= RxStateReset;
        elsif(Clk_CI'event and Clk_CI = '1')then
            RxStatePres_D <= RxStateNext_D;
        end
    end
    
    logicRx process(Clk_CI)
        variable burstCount_D:  std_logic_vector (7 downto 0);
    begin
        RxStateNext_D <= RxStatePres_D;
        case RxStatePres_D is
            when RxStateReset =>
                WaitReq_SO <= '0';
                Push_S <= '0';
                RxData_D <= (others => '0');
                burstCount_D <= (others => '0');
                stateNext_D <= RxStateIdle;
                
            when RxStateIdle =>
                if(Write_SI = '1')then
                    if(BeginBurstTransfer_DI = '1')then
                        RxStateNext_D <= RxStateRxBurst;
                    elsif(ByteEnable_DI = '1')
                        RxStateNext_D <= RxStateRxWord;
                    else
                        RxStateNext_D <= RxStatePres_D;
                    end if;
                end if;
                
            when RxStateRxWord =>
                -- word transfer
                case Address_DI is
                    when "00"
                        -- write command
                        if(FifoFull_D = '1')
                            WaitReq_SO <= '1';
                            Push_S <= '0';
                        else
                            WaitReq_SO <= '0';
                            RxData_D <= WriteData_DI;
                            Push_S <= '1';
                            Push_S <= '0';
                        end if;
                            
                    when "01"
                        -- write data
                        if(FifoFull_D = '1')
                            WaitReq_SO <= '1';
                            Push_S <= '0';
                        else
                            WaitReq_SO <= '0';
                            RxData_D <= x"002C";
                            Push_S <= '1';
                            Push_S <= '0';
                            RxData_D <= WriteData_DI;
                            Push_S <= '1';
                            Push_S <= '0';
                        end if;
                    else
                        RxData_D <= '0';
                        Push_S <= '0';
                end case;
                RxStateNext_D <= RxStateIdle;
                
            when RxStateRxBurst
                -- burst transfer
                burstCount_D := BurstCount_DI;
                case Address_DI is
                    when "00"
                        -- write command
                        while (burstCount_D > 0) loop
                            if(Write_SI = '1')then
                                if(FifoFull_D = '1')
                                    WaitReq_SO <= '1';
                                    Push_S <= '0';
                                    burstCount_D := burstCount_D
                                else
                                    WaitReq_SO <= '0';
                                    RxData_D <= WriteData_DI;
                                    Push_S <= '1';
                                    Push_S <= '0';
                                    burstCount_D := burstCount_D - 1;
                                end if;
                            else
                                null;
                            end if;
                        end loop;
                            
                    when "01"
                        -- write data
                        while (burstCount_D > 0) loop
                            if(Write_SI = '1')then
                                if(FifoFull_D = '1')then
                                    WaitReq_SO <= '1';
                                    Push_S <= '0';
                                    burstCount_D := burstCount_D;
                                else
                                    WaitReq_SO <= '0';
                                    RxData_D <= x"002C";
                                    Push_S <= '1';
                                    Push_S <= '0';
                                    RxData_D <= WriteData_DI;
                                    Push_S <= '1';
                                    Push_S <= '0';
                                    burstCount_D := burstCount_D - 1;
                                end if;
                            else
                                null;
                            end if;
                        end loop;
                    else
                        RxData_D <= '0';
                        Push_S <= '0';
                end case;
            when others
                RxStateNext_D <= RxStateReset;
        end case;
    end process logicRx; 

--------------------------------------------------------------------------------
---                                                                          ---
--- Transmitter state machine                                                ---
---                                                                          ---
--------------------------------------------------------------------------------
    nextStateTx: process(Clk_CI, Reset_NRI, RxStateRx)
    begin
        if(Reset_NRI = '1')then
            TxStatePres_D <= TxStateReset;
        elsif(Clk_CI'event and Clk_CI = '1')then
            TxStatePres_D <= TxStateNext_D;
        end
    end

    type TxState_T              is (TxSTateReset, TxStateIdle, TxStateTx);

    logicTx: process(Clk_CI)
    begin
        TxStateNext_D <= TxStatePres_D;
        case TxStatePres_D is
            when TxStateReset =>
                Pop_S <= '0';
                
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '1';                
                IM0_SO <= '0';        
                
                LcdReset_NRO <= '0';
                wait for 80ns;
                LcdReset_NRO <= '1';
                
                TxStateNext_D <= TxStateIdle;
                
            when TxStateIdle =>
                if(FifoEmpty_D = '0')then
                    TxStateNext_D <= TxStateTx;
                end if;
                
            when TxStateTx =>
                -- transfer to LCD
                Pop_S <= '1';

                if(TxData_D = x"002C")then
                    DC_NSO <= '1';
                else
                    DC_NSO <='0';
                end if;

                Cs_NSO <= '0';
                DC_NSO <= '0';
                Wr_NSO <= '0';
                
                DB_DIO <= TxData_D;
                wait for 80ns;
                
                TxStateNext_D <= TxStateIdle;                
                
            when others
                RxStateNext_D <= RxStateReset;
        end case;
    end process logicTx;
end LCD;