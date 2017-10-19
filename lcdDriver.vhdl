library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LcdDriver is
    port
    (
        -- communication between CPU and LcdDriver
        Clk_CI:         	    in std_logic;
        Reset_NRI:      	    in std_logic;
        Address_DI:     	    in std_logic_vector (1 downto 0);
        Write_SI:       	    in std_logic;
        WriteData_DI:		    in std_logic_vector (15 downto 0);
        Read_SI:		        in std_logic;
        ByteEnable_DI:          in std_logic;
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
    type RxState_T              is (RxStateReset,
                                    RxStateIdle,
                                    RxStateRxPrePushCmd,
                                    RxStateRxPrePushDataIdentifier,
                                    RxStateRxPrePushData,
                                    RxStateRxPostPushDataIdentifier,
                                    RxStateRxPostPush,
                                    RxStateRxBurst);
                                    
    type TxState_T              is (TxSTateReset, 
                                    TxStateDispReset,
                                    TxStateIdle,
                                    TxStatePreTx,
                                    TxStateTx,
                                    TxStatePostTx);
    
    signal RxStateNext_D:       RxState_T := RxStateReset;
    signal TxStateNext_D:       TxState_T := TxSTateReset;

    signal RxStatePres_D:       RxState_T := RxStateReset;
    signal TxStatePres_D:       TxState_T := TxSTateReset;   

    -- FIFO signals
    signal Pop_S:               std_logic;
    signal Push_S:              std_logic;
    signal RxData_D:            std_logic_vector (15 downto 0);
    signal TxData_D:            std_logic_vector (15 downto 0);
    signal FifoFull_D:          std_logic;
    signal FifoEmpty_D:         std_logic;
    
    signal IsData_D:            std_logic;
    
begin
    dataBuffer: FIFO generic map(256) port map(Clk_CI => Clk_CI,
                                                Reset_NRI => Reset_NRI,
                                                Push_SI => Push_S,
                                                Pop_SI => Pop_S, 
                                                Data_DI => RxData_D,
                                                Data_DO => TxData_D,
                                                Full_SO => FifoFull_D,
                                                Empty_SO => FifoEmpty_D);
--------------------------------------------------------------------------------
---                                                                          ---
--- Receiver state machine                                                   ---
---                                                                          ---
--------------------------------------------------------------------------------
    nextStateRx: process(Clk_CI, Reset_NRI)
    begin
        if(Reset_NRI = '0')then
            RxStatePres_D <= RxStateReset;
        elsif(Clk_CI'event and Clk_CI = '1')then
            RxStatePres_D <= RxStateNext_D;
        end if;
    end process;
    
    logicRx: process(Clk_CI, Write_SI)
        variable BurstCount_D:  natural;
    begin
        RxStateNext_D <= RxStatePres_D;
        case RxStatePres_D is
            when RxStateReset =>
                WaitReq_SO <= '0';
                Push_S <= '0';
                RxData_D <= (others => '0');
                burstCount_D := 0;
                RxStateNext_D <= RxStateIdle;
                
            when RxStateIdle =>
                if((Write_SI'event) and (Write_SI = '1'))then
                    WaitReq_SO <= '1';
                    case Address_DI is
                        when "00" => 
                            IsData_D <= '1';
                            RxStateNext_D <= RxStateRxPrePushDataIdentifier;
                        when "01" =>
                            IsData_D <= '0';
                            RxStateNext_D <= RxStateRxPrePushCmd;
                        when others =>
                            IsData_D <= IsData_D;
                            RxStateNext_D <= RxStatePres_D;
                    end case;
                    
                    if(BeginBurstTransfer_DI = '1')then
                        BurstCount_D := to_integer(unsigned(BurstCount_DI));
                    elsif(ByteEnable_DI = '1')then
                        BurstCount_D := 0;
                    else
                        BurstCount_D := 0;
                    end if;
                end if;
                
            when RxStateRxPrePushCmd =>
                if(FifoFull_D = '1')then
                    Push_S <= '0';
                    RxStateNext_D <= RxStatePres_D;
                else
                    RxData_D <= WriteData_DI;
                    WaitReq_SO <= '0';
                    Push_S <= '1';
                    RxStateNext_D <= RxStateRxPostPush;
                end if;
                
            when RxStateRxPrePushDataIdentifier =>
                if(FifoFull_D = '1')then
                    WaitReq_SO <= '1';
                    Push_S <= '0';
                else
                    WaitReq_SO <= '0';
                    RxData_D <= x"002C";
                    Push_S <= '1';
                end if;
                RxStateNext_D <= RxStateRxPostPushDataIdentifier;
                
            when RxStateRxPostPushDataIdentifier =>
                Push_S <= '0';
                RxStateNext_D <= RxStateRxPrePushData;
                
            when RxStateRxPrePushData =>
                if(FifoFull_D = '1')then
                    WaitReq_SO <= '1';
                    Push_S <= '0';
                else
                    WaitReq_SO <= '0';
                    RxData_D <= WriteData_DI;
                    WaitReq_SO <= '0';
                    Push_S <= '1';
                end if;
                RxStateNext_D <= RxStateRxPostPush;

                
            when RxStateRxPostPush =>
                Push_S <= '0';
                if(BurstCount_D > 0)then
                    BurstCount_D := BurstCount_D - 1;
                    if(IsData_D = '1')then
                        RxStateNext_D <= RxStateRxPrePushDataIdentifier;
                    else
                        RxStateNext_D <= RxStateRxPrePushCmd;
                    end if;
                else
                    RxStateNext_D <= RxStateIdle;
                end if;
                
            when others =>
                RxStateNext_D <= RxStateReset;
        end case;
    end process logicRx; 

--------------------------------------------------------------------------------
---                                                                          ---
--- Transmitter state machine                                                ---
---                                                                          ---
--------------------------------------------------------------------------------
    nextStateTx: process(Clk_CI, Reset_NRI)
    begin
        if(Reset_NRI = '0')then
            TxStatePres_D <= TxStateReset;
        elsif(Clk_CI'event and Clk_CI = '1')then
            TxStatePres_D <= TxStateNext_D;
        end if;
    end process;

    logicTx: process(Clk_CI)
        variable idleCount_D:  natural;
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
                
                idleCount_D := 4;
                LcdReset_NRO <= '0';
                
                TxStateNext_D <= TxStateDispReset;
            when TxStateDispReset =>
                if(idleCount_D > 0)then
                    idleCount_D := idleCount_D - 1;
                else
                    TxStateNext_D <= TxStateIdle;
                end if;
                
            when TxStateIdle =>
                if(FifoEmpty_D = '0')then
                    TxStateNext_D <= TxStatePreTx;
                end if;
            
            when TxStatePreTx =>
                Pop_S <= '1';
                TxStateNext_D <= TxStateTx;
                
            when TxStateTx =>
                -- transfer to LCD

                if(TxData_D = x"002C")then
                    DC_NSO <= '1';
                else
                    DC_NSO <='0';
                end if;
                
                Pop_S <= '0';

                Cs_NSO <= '0';
                DC_NSO <= '0';
                Wr_NSO <= '0';
                
                DB_DIO <= TxData_D;
                
                idleCount_D := 4;
                TxStateNext_D <= TxStatePostTx;                
            
            when TxStatePostTx =>
                if(idleCount_D > 0)then
                    idleCount_D := idleCount_D - 1;
                else
                    Cs_NSO <= '1';
                    Wr_NSO <= '1';
                    Rd_NSO <= '1';
                    
                    TxStateNext_D <= TxStateIdle;
                end if;
                
            when others =>
                TxStateNext_D <= TxStateReset;
        end case;
    end process logicTx;
end LCD;