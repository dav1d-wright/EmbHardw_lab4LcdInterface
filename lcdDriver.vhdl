library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LcdDriver is
    port
    (
        -- communication between CPU and LcdDriver
        Clk_CI:         	    in std_logic;
        Reset_BRI:      	    in std_logic;
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
        Rd_BSO:                 out std_logic;
        Wr_BSO:                 out std_logic;
        Cs_BSO:                 out std_logic;
        DC_BSO:                 out std_logic;
        LcdReset_BRO:           out std_logic;
        IM0_SO:                 out std_logic;
    );
end LcdDriver;

architecture LCD of LcdDriver is 
    component FIFO
        generic (SIZE:              natural := 256);
        port
        (
            Clk_CI:         	    in std_logic;
            Reset_BRI:      	    in std_logic;
            Push_SI:                in std_logic;
            Pop_SI:                 in std_logic;
            Data_DI:                in std_logic_vector (15 downto 0);
            Data_DO:                out std_logic_vector (15 downto 0);
            Full_SO:                out std_logic;
            Empty_SO:               out std_logic
        );
    end component;


    -- State macine types & signals
    type RxState_T              is (RxStateReset, RxStateIdle, RxStateWaiting, RxStateRx);
    type TxState_T              is (TxSTateReset, TxStateIdle, TxStateWaiting, TxStateTx);
    
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
                                                Reset_BRI => Reset_BRI,
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
    nextStateRx process(Clk_CI, Reset_BRI, RxStateNext_D)
    begin
        if(Reset_BRI = '1')then
            RxStatePres_D <= RxStateReset;
        elsif(Clk_CI'event and Clk_CI = '1')then
            RxStatePres_D <= RxStateNext_D;
        end
    end
    
    logicRx process(Clk_CI)
    begin
        
    end
    
    rx: process(Clk_CI, ByteEnable_DI, Write_SI)
        variable burstCount_D:  std_logic_vector (7 downto 0);
    begin
        if((RxStatePres_D = RxStateRx) and (ByteEnable_DI = '1') and (Write_SI = '1'))
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
                    -- write data7
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
            end case
        elsif((RxStatePres_D = RxStateRx) and (BeginBurstTransfer_DI = '1') and (Write_SI = '1'))
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
            end case
        else
            null;
        end if
    end    

--------------------------------------------------------------------------------
---                                                                          ---
--- Transmitter state machine                                                ---
---                                                                          ---
--------------------------------------------------------------------------------
    nextStateTx process(Clk_CI, Reset_BRI, RxStateRx)
    begin
        if(Reset_BRI = '1')then
            TxStatePres_D <= TxStateReset;
        elsif(Clk_CI'event and Clk_CI = '1')then
            TxStatePres_D <= TxStateNext_D;
        end
    end
end LCD;