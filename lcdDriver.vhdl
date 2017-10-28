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
        Address_DI:     	    in std_logic_vector (2 downto 0);
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

    type State_T                is (StateReset,
                                    StateLcdReset,
                                    StateIdle,
                                    StateTxCmd,
                                    StateTxDataIdentifier,
                                    StatePostTxDataIdentifier,
                                    StateTxData,
                                    StatePostTx);
    
                                    
    signal StateNext_D:       State_T := StateReset;
    signal StatePres_D:       State_T := StateReset;
        
    signal IsData_D:                std_logic;
        
    signal BitEnable_D:             std_logic_vector (15 downto 0);
    signal BurstCount_D:            natural range 0 to 255;
        
    signal idleCount_D:             natural range 0 to 255;
    
    signal WriteData_D:             std_logic_vector (15 downto 0);
begin
--------------------------------------------------------------------------------
---                                                                          ---
--- state machine                                                   ---
---                                                                          ---
--------------------------------------------------------------------------------
    nextStateRx: process(Clk_CI, Reset_NRI)
    begin
        if(Reset_NRI = '0')then
            StatePres_D <= StateReset;
        elsif(Clk_CI'event and Clk_CI = '1')then
            StatePres_D <= StateNext_D;
        end if;
    end process;
    
    logic: process(Write_SI, StatePres_D)
        -- storage for all input data on read/write cycles
        variable Address_D:                 std_logic_vector (2 downto 0);
        variable ByteEnable_D:              std_logic_vector (1 downto 0);
        variable BeginBurstTransfer_D:      std_logic;
        variable TotalBurstCount_D:           natural range 0 to 255;
    begin
        case StatePres_D is
            when StateReset =>
                WaitReq_SO <= '0';
                BurstCount_D <= 0;
                StateNext_D <= StateLcdReset;
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '1';                
                IM0_SO <= '0';        
                
                idleCount_D <= 0;
                LcdReset_NRO <= '0';
                
            when StateLcdReset =>
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '0';                
                IM0_SO <= '0';  
                WaitReq_SO <= '1';


                if(idleCount_D < 5)then
                    idleCount_D <= idleCount_D + 1;
                    StateNext_D <= StateLcdReset;
                else
                    idleCount_D <= 0;
                    StateNext_D <= StateIdle;
                end if;
                
            when StateIdle =>
                -- store input values as early as possible
                Address_D := Address_DI;
                ByteEnable_D := ByteEnable_DI;
                WriteData_D <= WriteData_DI;  
                TotalBurstCount_D := to_integer(unsigned(BurstCount_DI));
                BeginBurstTransfer_D := BeginBurstTransfer_DI;
                
                -- default values
                BurstCount_D <= 0;
                WaitReq_SO <= '0';
                
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '1';                
                IM0_SO <= '0';  

                idleCount_D <= 0;
                
                if(Write_SI = '1')then
                    if(BeginBurstTransfer_D = '1')then
                        BurstCount_D <= TotalBurstCount_D;
                    else
                        BurstCount_D <= 0;
                    end if;
                    
                    case ByteEnable_D is
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
                    
                    
                    case Address_D is
                        when "000" => 
                            IsData_D <= '1';
                            StateNext_D <= StateTxDataIdentifier;
                        when "011" =>
                            IsData_D <= '0';
                            StateNext_D <= StateTxCmd;
                        when others =>
                            IsData_D <= IsData_D;
                            StateNext_D <= StateIdle;
                    end case;

                else
                    IsData_D <= '0';
                    BitEnable_D <= (others => '0');
                    BurstCount_D <= 0;
                    StateNext_D <= StateIdle;
                end if;
                
                
            when StateTxCmd =>
                -- -- debug begin
                -- StateNext_D <= StateTxDataIdentifier;
                -- -- debug end 
                -- transfer to LCD
                WaitReq_SO <= '1';
                DB_DIO <= WriteData_D and BitEnable_D;

                DC_NSO <='0';
                
                LcdReset_NRO <= '1';  
                Rd_NSO <= '1';
                Cs_NSO <= '0';
                Wr_NSO <= '0';
                IM0_SO <= '0';
                
                idleCount_D <= 0;
                BurstCount_D <= BurstCount_D;
                StateNext_D <= StatePostTx;
                
            when StateTxDataIdentifier =>
                -- -- debug begin
                -- StateNext_D <= StateRxPostPushDataIdentifier;
                -- -- debug end 
                -- transfer to LCD
                WaitReq_SO <= '1';
                DB_DIO <= x"002C";

                DC_NSO <= '1';
                
                LcdReset_NRO <= '1';  
                Rd_NSO <= '1';
                Cs_NSO <= '0';
                Wr_NSO <= '0';
                IM0_SO <= '0';
                
                idleCount_D <= 0;
                
                BurstCount_D <= BurstCount_D;

                StateNext_D <= StatePostTxDataIdentifier;
                
            when StatePostTxDataIdentifier =>
                WaitReq_SO <= '1';
                
                -- -- debug begin
                -- StateNext_D <= StateIdle;
                -- -- debug end 
                BurstCount_D <= BurstCount_D;

                
                if(idleCount_D < 1)then
                    DB_DIO <= x"002C";

                    idleCount_D <= idleCount_D + 1;
                    StateNext_D <= StatePostTxDataIdentifier;
                else
                    DB_DIO <= (others => '0');
                    StateNext_D <= StateTxData;
                end if;
                
            when StateTxData =>
                -- -- debug begin
                -- StateNext_D <= StateRxPostPush;
                -- -- debug end                 
                -- transfer to LCD
                WaitReq_SO <= '1';
                DB_DIO <= WriteData_D and BitEnable_D;

                DC_NSO <= '1';
                
                LcdReset_NRO <= '1';  
                Rd_NSO <= '1';
                Cs_NSO <= '0';
                Wr_NSO <= '0';
                IM0_SO <= '0';
                
                idleCount_D <= 0;
                
                BurstCount_D <= BurstCount_D;

                StateNext_D <= StatePostTx;

                
            when StatePostTx =>
                
                -- -- debug begin
                -- StateNext_D <= StateIdle;
                -- -- debug end 
                if(IsData_D = '1')then
                    DC_NSO <= '1';
                else
                    DC_NSO <= '0';
                end if;
                
                if(idleCount_D < 1)then
                    WaitReq_SO <= '1';
                    DB_DIO <= WriteData_D and BitEnable_D;

                    idleCount_D <= idleCount_D + 1;
                    
                    LcdReset_NRO <= '1';  
                    Rd_NSO <= '1';
                    Cs_NSO <= '1';
                    Wr_NSO <= '1';
                    IM0_SO <= '0';
                
                    StateNext_D <= StatePostTx;
                elsif(BurstCount_D > 0)then
                    WaitReq_SO <= '0';
                    DB_DIO <= (others => '0');

                    BurstCount_D <= BurstCount_D - 1;
                    
                    LcdReset_NRO <= '1';  
                    Rd_NSO <= '1';
                    Cs_NSO <= '1';
                    Wr_NSO <= '1';
                    IM0_SO <= '0';
                    
                    if(IsData_D = '1')then
                        StateNext_D <= StateTxDataIdentifier;
                    else
                        StateNext_D <= StateTxCmd;
                    end if;
                else
                    LcdReset_NRO <= '1';  
                    Rd_NSO <= '1';
                    Cs_NSO <= '1';
                    Wr_NSO <= '1';
                    IM0_SO <= '0';
                    
                    WaitReq_SO <= '0';
                    DB_DIO <= (others => '0');
                    StateNext_D <= StateIdle;
                end if;
                
            when others =>
                WaitReq_SO <= '0';
                BurstCount_D <= 0;
                StateNext_D <= StateLcdReset;
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '1';                
                IM0_SO <= '0';        
                
                idleCount_D <= 0;
                LcdReset_NRO <= '0';
                
                StateNext_D <= StateReset;
        end case;
    end process logic; 
end LCD;