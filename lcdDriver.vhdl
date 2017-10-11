library ieee;
use ieee.std_logic_1164.all;

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


    type RxState_T          is (RxStateReset, RxStateIdle, RxStateWaiting, RxStateRx);
    type TxState_T          is (TxSTateReset, TxStateIdle, TxStateWaiting, TxStateTx);
    
    signal RxStateNext_D:   RxState_T;
    signal TxStateNext_D:   TxState_D;

    signal RxStatePres_D:   RxState_T;
    signal TxStatePres_D:   TxState_D;   


    
begin
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