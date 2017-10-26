-------------------------------------------------------
--! @file lcdDriver.vhdl
--! @author David Wright
--! @brief LCD driver. Translates avalon bus data and commands to the LCD interface
-------------------------------------------------------

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
        ByteEnable_DI:          in std_logic_vector (1 downto 0);
        BeginBurstTransfer_DI:  in std_logic;
        BurstCount_DI:          in std_logic_vector (7 downto 0);
        
        WaitReq_SO:             out std_logic;
        ReadData_DO:		    out std_logic_vector (15 downto 0);
        ReadDataValid_SO:       out std_logic;
        
      
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
                                    RxStateRxPostPush);
                                    
    type TxState_T              is (TxStateReset, 
                                    TxStateDispReset,
                                    TxStateIdle,
                                    TxStatePreTx,
                                    TxStateTx,
                                    TxStatePostTx);
    
                                    
    signal RxStateNext_D:       RxState_T := RxStateReset;
    signal TxStateNext_D:       TxState_T := TxStateReset;


    signal RxStatePres_D:       RxState_T := RxStateReset;
    signal TxStatePres_D:       TxState_T := TxStateReset;   

    -- FIFO signals
    signal Pop_S:               std_logic;
    signal Push_S:              std_logic;
    signal RxData_D:            std_logic_vector (15 downto 0);
    signal TxData_D:            std_logic_vector (15 downto 0);
    signal FifoFull_D:          std_logic;
    signal FifoEmpty_D:         std_logic;
    
    signal IsData_D:            std_logic;
    
    signal BitEnable_D:         std_logic_vector (15 downto 0);
    signal BurstCount_D:        integer;
    
    signal idleCount_D:         unsigned (7 downto 0);
    
    -- edge detection of Write_SI and Read_SI
    signal Write_Edge_D:        std_logic;
    signal Write_Last_D:        std_logic;
    
    signal Read_Edge_D:         std_logic;    
    signal Read_Last_D:         std_logic;
begin
    dataBuffer: FIFO generic map(256) port map(Clk_CI => Clk_CI,
                                                Reset_NRI => Reset_NRI,
                                                Push_SI => Push_S,
                                                Pop_SI => Pop_S, 
                                                Data_DI => RxData_D,
                                                Data_DO => TxData_D,
                                                Full_SO => FifoFull_D,
                                                Empty_SO => FifoEmpty_D);
                                                
    -- edgeDetect: process(Reset_NRI, Clk_CI)
    -- begin
        -- if(Clk_CI'event and Clk_CI = '1')then
            -- if(Reset_NRI = '0')then
                -- Read_Edge_D <= '0';
                -- Write_Edge_D <= '0';
            -- elsif(Clk_CI'event and Clk_CI = '1')then
                -- Write_Edge_D <= Write_SI and (not Write_Last_D);
                -- Write_Last_D <= Write_SI;
                
                -- Read_Edge_D <= Read_SI and (not Read_Last_D);
                -- Read_Last_D <= Read_SI;
            -- end if;
        -- end if;
    -- end process edgeDetect;
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
    
    logicRx: process(Write_SI, RxStatePres_D)
    begin
        case RxStatePres_D is
            when RxStateReset =>
                WaitReq_SO <= '0';
                Push_S <= '0';
                RxData_D <= (others => '0');
                BurstCount_D <= 0;
                RxStateNext_D <= RxStateIdle;
                
            when RxStateIdle =>
                Push_S <= '0';
                BurstCount_D <= 0;
                RxData_D <= (others => '0');
                WaitReq_SO <= '0';
                if(Write_SI = '1')then
                    case ByteEnable_DI is
                        when "00" => 
                            BitEnable_D <= (others => '0');
                        when "01" =>
                            BitEnable_D <= "0000000011111111";
                        when "10" =>
                            BitEnable_D <= "1111111100000000";
                        when "11" =>
                            BitEnable_D <= (others => '1');
                        when others =>
                            BitEnable_D <= (others => '0');
                    end case;
                    
                    if(BeginBurstTransfer_DI = '1')then
                        BurstCount_D <= to_integer(unsigned(BurstCount_DI));
                    else
                        BurstCount_D <= 0;
                    end if;
                    
                    case Address_DI is
                        when "00" => 
                            IsData_D <= '1';
                            RxStateNext_D <= RxStateRxPrePushDataIdentifier;
                        when "01" =>
                            IsData_D <= '0';
                            RxStateNext_D <= RxStateRxPrePushCmd;
                        when others =>
                            IsData_D <= IsData_D;
                            RxStateNext_D <= RxStateIdle;
                    end case;

                else
                    IsData_D <= '0';
                    BitEnable_D <= (others => '0');
                    BurstCount_D <= 0;
                    RxStateNext_D <= RxStateIdle;
                end if;
                
            when RxStateRxPrePushCmd =>
                BurstCount_D <= BurstCount_D;
                if(FifoFull_D = '1')then
                    WaitReq_SO <= '1';
                    Push_S <= '0';
                    RxData_D <= (others => '0');
                    RxStateNext_D <= RxStateRxPrePushCmd;
                else
                    RxData_D <= WriteData_DI and BitEnable_D;
                    WaitReq_SO <= '0';
                    Push_S <= '1';
                    RxStateNext_D <= RxStateRxPostPush;
                end if;
                
            when RxStateRxPrePushDataIdentifier =>
                BurstCount_D <= BurstCount_D;
                if(FifoFull_D = '1')then
                    WaitReq_SO <= '1';
                    Push_S <= '0';
                    RxData_D <= (others => '0');
                    RxStateNext_D <= RxStateRxPrePushDataIdentifier;
                else
                    WaitReq_SO <= '0';
                    RxData_D <= x"002C";
                    Push_S <= '1';
                    RxStateNext_D <= RxStateRxPostPushDataIdentifier;
                end if;
                
            when RxStateRxPostPushDataIdentifier =>
                BurstCount_D <= BurstCount_D;
                Push_S <= '0';
                RxData_D <= (others => '0');
                RxStateNext_D <= RxStateRxPrePushData;
                
            when RxStateRxPrePushData =>
                BurstCount_D <= BurstCount_D;
                if(FifoFull_D = '1')then
                    WaitReq_SO <= '1';
                    Push_S <= '0';
                    RxData_D <= (others => '0');
                    RxStateNext_D <= RxStateRxPrePushData;
                else
                    WaitReq_SO <= '0';
                    RxData_D <= WriteData_DI and BitEnable_D;
                    WaitReq_SO <= '0';
                    Push_S <= '1';
                    RxStateNext_D <= RxStateRxPostPush;
                end if;

                
            when RxStateRxPostPush =>
                WaitReq_SO <= '0';
                BurstCount_D <= BurstCount_D;
                Push_S <= '0';
                RxData_D <= (others => '0');
                
                if(BurstCount_D > 0)then
                    BurstCount_D <= BurstCount_D - 1;
                    if(IsData_D = '1')then
                        RxStateNext_D <= RxStateRxPrePushDataIdentifier;
                    else
                        RxStateNext_D <= RxStateRxPrePushCmd;
                    end if;
                else
                    RxStateNext_D <= RxStateIdle;
                end if;
                
            when others =>
                RxData_D <= (others => '0');
                WaitReq_SO <= '0';
                BurstCount_D <= BurstCount_D;
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

    logicTx: process(FifoEmpty_D, FifoFull_D, TxStatePres_D, Push_S)
    begin
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
                
                idleCount_D <= to_unsigned(0, 8);
                LcdReset_NRO <= '0';
                
                TxStateNext_D <= TxStateDispReset;
                
            when TxStateDispReset =>
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '0';                
                IM0_SO <= '0';  
                Pop_S <= '0';

                if(idleCount_D < to_unsigned(5, 8))then
                    idleCount_D <= idleCount_D + to_unsigned(1, 8);
                    TxStateNext_D <= TxStateDispReset;
                else
                    idleCount_D <= to_unsigned(0, 8);
                    TxStateNext_D <= TxStateIdle;
                end if;
                
            when TxStateIdle =>
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '1';                
                IM0_SO <= '0';  
                Pop_S <= '0';

                idleCount_D <= to_unsigned(0, 8);
                
                if(FifoEmpty_D = '0')then
                    TxStateNext_D <= TxStatePreTx;
                else
                    TxStateNext_D <= TxStateIdle;
                end if;
            
            when TxStatePreTx =>
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '1';                
                IM0_SO <= '0';  
                idleCount_D <= to_unsigned(0, 8);
                Pop_S <= '1';
                TxStateNext_D <= TxStateTx;
                
            when TxStateTx =>
                -- transfer to LCD
                DB_DIO <= TxData_D;

                if(TxData_D = x"002C")then
                    DC_NSO <= '1';
                else
                    DC_NSO <='0';
                end if;
                
                LcdReset_NRO <= '1';  
                Pop_S <= '0';
                Rd_NSO <= '1';
                Cs_NSO <= '0';
                Wr_NSO <= '0';
                IM0_SO <= '0';
                
                
                idleCount_D <= to_unsigned(0, 8);
                TxStateNext_D <= TxStatePostTx;                
            
            when TxStatePostTx =>
                DB_DIO <= TxData_D;
                Pop_S <= '0';
                LcdReset_NRO <= '1';
                
                if(idleCount_D < to_unsigned(5, 8))then
                    idleCount_D <= idleCount_D + to_unsigned(1, 8);
                    TxStateNext_D <= TxStatePostTx;
                else
                    idleCount_D <= to_unsigned(0, 8);
                    Cs_NSO <= '1';
                    Wr_NSO <= '1';
                    Rd_NSO <= '1';
                    
                    TxStateNext_D <= TxStateIdle;
                end if;
                
            when others =>
                DB_DIO <= (others => '0');
                idleCount_D <= to_unsigned(0, 8);
                TxStateNext_D <= TxStateReset;
        end case;
    end process logicTx;
end LCD;