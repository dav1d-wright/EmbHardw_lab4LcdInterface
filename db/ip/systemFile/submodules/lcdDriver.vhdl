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
        BeginBurstTransfer_DI:  in std_logic_vector (0 downto 0);
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
    -- D-FlipFlop for input storage 
    component D_FF is
        generic (WIDTH:     natural := 16);
        port
        (
            Reset_NRI:      in std_logic;
            Set_SI:         in std_logic;
            D_DI:           in std_logic_vector (WIDTH-1 downto 0);
            Q_DO:           out std_logic_vector(WIDTH-1 downto 0)
        );
    end component;


    -- State macine types & signals

    type State_T                is (StateReset,
                                    StateLcdReset,
                                    StateLcdResetWait,
                                    StateIdle,
                                    StateEvalData,
                                    StateTxCmd,
                                    StateTxDataIdentifier,
                                    StatePostTxDataIdentifier,
                                    StatePostTxDataIdentifierWait,
                                    StateTxData,
                                    StatePostTx,
                                    StatePostTxWait,
                                    StatePostTxBurstWaitData,
                                    StatePostTxBurstWaitCmd);
    
                                    
    signal StateNext_D:             State_T := StateReset;
    signal StatePres_D:             State_T := StateReset;
        
    signal IsData_D:                std_logic := '0';

    signal BurstCount_D:            std_logic_vector (7 downto 0) := (others => '0');
    signal CurBurstCount_D:         std_logic_vector (7 downto 0);
        
    
    signal ByteEnable_Persist_D:    std_logic_vector (1 downto 0) := (others => '0');
    signal WriteData_Persist_D:     std_logic_vector (15 downto 0) := (others => '0');
    signal BurstCount_Persist_D:    std_logic_vector (7 downto 0) := (others => '0');
    signal CurBurstCount_Persist_D: std_logic_vector (7 downto 0) := (others => '0');
    signal Address_Persist_D:       std_logic_vector (2 downto 0) := (others => '0');
    signal BeginBurstTransfer_Persist_D:       std_logic_vector (0 downto 0) := (others => '0');
    
    signal IdleCount_D:             std_logic_vector (7 downto 0) := (others => '0');
    signal IdleCount_Persist_D:     std_logic_vector (7 downto 0) := (others => '0');
    
    signal SetByteEnable_S:         std_logic := '0';
    signal SetWriteData_S:          std_logic := '0';
    signal SetBurstCount_S:         std_logic := '0';
    signal SetCurBurstCount_S:      std_logic := '0';
    signal SetIdlecount_S:          std_logic := '0';
    signal SetAddress_S:          std_logic := '0';
    signal SetBeginBurstTransfer_S:          std_logic := '0';
    

    -- edge detection of Write_SI and Read_SI
    -- signal Write_Edge_D:            std_logic := '0';
    -- signal Write_Last_D:            std_logic := '0';
        
    -- signal Read_Edge_D:             std_logic := '0';
    -- signal Read_Last_D:             std_logic := '0';

begin
--------------------------------------------------------------------------------
---                                                                          ---
--- data storage                                                             ---
---                                                                          ---
--------------------------------------------------------------------------------
WriteDataStorage: D_FF generic map(WIDTH => 16)
                        port map
                        (
                            Reset_NRI   => Reset_NRI,
                            Set_SI      => SetWriteData_S,
                            D_DI        => WriteData_DI,
                            Q_DO        => WriteData_Persist_D
                        );

BurstCountStorage: D_FF generic map(WIDTH => 8)
                        port map
                        (
                            Reset_NRI   => Reset_NRI,
                            Set_SI      => SetBurstCount_S,
                            D_DI        => BurstCount_DI,
                            Q_DO        => BurstCount_Persist_D
                        );

CurBurstCountStorage: D_FF generic map(WIDTH => 8)
                        port map
                        (
                            Reset_NRI   => Reset_NRI,
                            Set_SI      => SetCurBurstCount_S,
                            D_DI        => CurBurstCount_D,
                            Q_DO        => CurBurstCount_Persist_D
                        );
                        
IdleCountStorage: D_FF generic map(WIDTH => 8)
                        port map
                        (
                            Reset_NRI   => Reset_NRI,
                            Set_SI      => SetIdleCount_S,
                            D_DI        => IdleCount_D,
                            Q_DO        => IdleCount_Persist_D
                        );
                        
ByteEnableStorage: D_FF generic map(WIDTH => 2)
                        port map
                        (
                            Reset_NRI   => Reset_NRI,
                            Set_SI      => SetByteEnable_S,
                            D_DI        => ByteEnable_DI,
                            Q_DO        => ByteEnable_Persist_D
                        );
AddressStorage: D_FF generic map(WIDTH => 3)
                        port map
                        (
                            Reset_NRI   => Reset_NRI,
                            Set_SI      => SetAddress_S,
                            D_DI        => Address_DI,
                            Q_DO        => Address_Persist_D
                        );

BeginBurstTransferStorage: D_FF generic map(WIDTH => 1)
                        port map
                        (
                            Reset_NRI   => Reset_NRI,
                            Set_SI      => SetBeginBurstTransfer_S,
                            D_DI        => BeginBurstTransfer_DI,
                            Q_DO        => BeginBurstTransfer_Persist_D
                        );
--------------------------------------------------------------------------------
---                                                                          ---
--- state machine                                                            ---
---                                                                          ---
--------------------------------------------------------------------------------
    -- edgeDetect: process(Reset_NRI, Clk_CI)
    -- begin
        -- if(Clk_CI'event and Clk_CI = '1')then
            -- if(Reset_NRI = '0')then
                -- Read_Edge_D <= '0';
                -- Write_Edge_D <= '0';
                -- Read_Last_D <= '0';
                -- Write_Last_D <= '0';
            -- elsif(Clk_CI'event and Clk_CI = '1')then
                -- Write_Edge_D <= Write_SI and (not Write_Last_D);
                -- Write_Last_D <= Write_SI;
                
                -- Read_Edge_D <= Read_SI and (not Read_Last_D);
                -- Read_Last_D <= Read_SI;
            -- end if;
        -- end if;
    -- end process edgeDetect;

    captAddress: process(Clk_CI, Reset_NRI)
    begin
        if(Reset_NRI = '0')then
            SetAddress_S <= '0';
        elsif(Clk_CI'event and Clk_CI = '1')then
            if(Write_SI = '1')then
                SetAddress_S <= '1';
            else
                SetAddress_S <= '0';
            end if;
        end if;
    end process;
    
    captByteEnable: process(Clk_CI, Reset_NRI)
    begin
        if(Reset_NRI = '0')then
            SetByteEnable_S <= '0';
        elsif(Clk_CI'event and Clk_CI = '1')then
            if(Write_SI = '1')then
                SetByteEnable_S <= '1';
            else
                SetByteEnable_S <= '0';
            end if;
        end if;
    end process;
 
    captBeginBurstTransfer: process(Clk_CI, Reset_NRI)
    begin
        if(Reset_NRI = '0')then
            SetBeginBurstTransfer_S <= '0';
        elsif(Clk_CI'event and Clk_CI = '1')then
            if(Write_SI = '1')then
                SetBeginBurstTransfer_S <= '1';
            else
                SetBeginBurstTransfer_S <= '0';
            end if;
        end if;
    end process;
    
    captBurstCount: process(Clk_CI, Reset_NRI)
    begin
        if(Reset_NRI = '0')then
            SetBurstCount_S <= '0';
        elsif(Clk_CI'event and Clk_CI = '1')then
            if(Write_SI = '1')then
                SetBurstCount_S <= '1';
            else
                SetBurstCount_S <= '0';
            end if;
        end if;
    end process;
    
    captWriteData: process(Clk_CI, Reset_NRI)
    begin
        if(Reset_NRI = '0')then
            SetWriteData_S <= '0';
        elsif(Clk_CI'event and Clk_CI = '1')then
            if(Write_SI = '1')then
                SetWriteData_S <= '1';
            else
                SetWriteData_S <= '0';
            end if;
        end if;
    end process;
    
    nextState: process(Clk_CI, Reset_NRI)
    begin
        if(Reset_NRI = '0')then
            StatePres_D <= StateReset;
        elsif(Clk_CI'event and Clk_CI = '1')then
            StatePres_D <= StateNext_D;
        end if;
    end process;
    
    
    logic: process(Write_SI, StatePres_D)
        -- storage for all input data on read/write cycles
        variable Address_D:                 std_logic_vector (2 downto 0) := (others =>  '0');
        variable BitEnable_D:               std_logic_vector (15 downto 0) := (others =>  '0');
        variable BeginBurstTransfer_D:      std_logic := '0';

    begin
        case StatePres_D is
            when StateReset =>
                WaitReq_SO <= '0';
                StateNext_D <= StateLcdReset;
                IdleCount_D <= std_logic_vector(to_unsigned(5, 8));
                
                SetCurBurstCount_S <= '0';
                
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '1';                
                IM0_SO <= '0';        
                
                LcdReset_NRO <= '0';
                SetIdleCount_S <= '1';
                
            when StateLcdReset =>
                SetCurBurstCount_S <= '0';
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '0';                
                IM0_SO <= '0';  
                WaitReq_SO <= '1';


                if(to_integer(unsigned(IdleCount_Persist_D)) > 0)then
                    IdleCount_D <= std_logic_vector(unsigned(IdleCount_Persist_D) - to_unsigned(1, 8));
                    StateNext_D <= StateLcdResetWait;
                else
                    IdleCount_D <= std_logic_vector(to_unsigned(0, 8));
                    StateNext_D <= StateIdle;
                end if;
                SetIdleCount_S <= '1';

            when StateLcdResetWait =>
                SetIdlecount_S <= '0';
                SetCurBurstCount_S <= '0';
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '0';                
                IM0_SO <= '0';  
                WaitReq_SO <= '1';
                
                StateNext_D <= StateLcdReset;

                
            when StateIdle =>
                -- store input values as early as possible
                Address_D := Address_DI;
                IdleCount_D <= std_logic_vector(to_unsigned(0, 8));

                -- default values
                WaitReq_SO <= '0';
                
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '1';                
                IM0_SO <= '0';  

                SetIdleCount_S <= '0';
                SetCurBurstCount_S <= '0';
                IsData_D <= '0';
                
                if(Write_SI = '1')then                  
                    StateNext_D <= StateEvalData;
                else
                    StateNext_D <= StateIdle;
                end if;
                
            when StateEvalData =>
                WaitReq_SO <= '0';
                
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '1';                
                IM0_SO <= '0';  
                
                SetCurBurstCount_S <= '1';
                SetIdleCount_S <= '0';
                IdleCount_D <= std_logic_vector(to_unsigned(0, 8));

                if(BeginBurstTransfer_Persist_D = "1")then
                    CurBurstCount_D <= BurstCount_Persist_D;
                else
                    CurBurstCount_D <= (others => '0');
                end if;
                
                case Address_Persist_D is
                    when "000" => 
                        IsData_D <= '1';
                        StateNext_D <= StateTxDataIdentifier;
                    when "010" =>
                        IsData_D <= '0';
                        StateNext_D <= StateTxCmd;
                    when others =>
                        IsData_D <= IsData_D;
                        StateNext_D <= StateIdle;
                end case;
                
            when StateTxCmd =>
                SetIdleCount_S <= '0';
                SetCurBurstCount_S <= '0';

                -- -- debug begin
                -- StateNext_D <= StateTxDataIdentifier;
                -- -- debug end 
                -- transfer to LCD
                WaitReq_SO <= '1';
                case ByteEnable_Persist_D is
                    when "00" => 
                        BitEnable_D := (others => '0');
                    when "01" =>
                        BitEnable_D := "0000000011111111";
                    when "10" =>
                        BitEnable_D := "1111111100000000";
                    when "11" =>
                        BitEnable_D := (others => '1');
                    when others =>
                        BitEnable_D := (others => '0');
                end case;
                
                
                DC_NSO <='0';
                
                LcdReset_NRO <= '1';  
                Rd_NSO <= '1';
                Cs_NSO <= '0';
                Wr_NSO <= '0';
                IM0_SO <= '0';
                
                IdleCount_D <= std_logic_vector(to_unsigned(0, 8));
                
                DB_DIO <= WriteData_Persist_D and BitEnable_D;
                
                StateNext_D <= StatePostTx;
                
            when StateTxDataIdentifier =>
                SetIdleCount_S <= '0';
                SetCurBurstCount_S <= '0';

                
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
                
                IdleCount_D <= std_logic_vector(to_unsigned(0, 8));

                
                StateNext_D <= StatePostTxDataIdentifier;
                
            when StatePostTxDataIdentifier =>
                WaitReq_SO <= '0';
                SetCurBurstCount_S <= '0';

                -- -- debug begin
                -- StateNext_D <= StateIdle;
                -- -- debug end 

                
                if(to_integer(unsigned(IdleCount_Persist_D)) > 0)then
                    IdleCount_D <= std_logic_vector(unsigned(IdleCount_Persist_D) - to_unsigned(1, 8));                 DB_DIO <= x"002C";

                    StateNext_D <= StatePostTxDataIdentifierWait;
                else
                    DB_DIO <= (others => '0');
                    IdleCount_D <= std_logic_vector(to_unsigned(0, 8));
                    LcdReset_NRO <= '1';  
                    Rd_NSO <= '1';
                    Cs_NSO <= '1';
                    Wr_NSO <= '1';
                    IM0_SO <= '0';
                    StateNext_D <= StateTxData;
                end if;

                SetIdleCount_S <= '1';

            when StatePostTxDataIdentifierWait =>
                SetIdlecount_S <= '0';
                SetCurBurstCount_S <= '0';
                DB_DIO <= x"002C"; 
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '0';                
                IM0_SO <= '0';  
                WaitReq_SO <= '1';

                
                StateNext_D <= StatePostTxDataIdentifier;
                
            when StateTxData =>
                SetCurBurstCount_S <= '0';
                SetIdleCount_S <= '0';
                -- -- debug begin
                -- StateNext_D <= StateRxPostPush;
                -- -- debug end                 
                -- transfer to LCD
                WaitReq_SO <= '1';
                case ByteEnable_Persist_D is
                    when "00" => 
                        BitEnable_D := (others => '0');
                    when "01" =>
                        BitEnable_D := "0000000011111111";
                    when "10" =>
                        BitEnable_D := "1111111100000000";
                    when "11" =>
                        BitEnable_D := (others => '1');
                    when others =>
                        BitEnable_D := (others => '0');
                end case;
                
                DC_NSO <= '1';
                
                LcdReset_NRO <= '1';  
                Rd_NSO <= '1';
                Cs_NSO <= '0';
                Wr_NSO <= '0';
                IM0_SO <= '0';
                
                IdleCount_D <= std_logic_vector(to_unsigned(0, 8));
                
                DB_DIO <= WriteData_Persist_D and BitEnable_D;

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
                
                if(to_integer(unsigned(IdleCount_Persist_D)) > 0)then
                    IdleCount_D <= std_logic_vector(unsigned(IdleCount_Persist_D) - to_unsigned(1, 8));
                    WaitReq_SO <= '0';
                    case ByteEnable_Persist_D is
                        when "00" => 
                            BitEnable_D := (others => '0');
                        when "01" =>
                            BitEnable_D := "0000000011111111";
                        when "10" =>
                            BitEnable_D := "1111111100000000";
                        when "11" =>
                            BitEnable_D := (others => '1');
                        when others =>
                            BitEnable_D := (others => '0');
                    end case;
                    
                    DB_DIO <= WriteData_Persist_D and BitEnable_D;
                    
                    LcdReset_NRO <= '1';  
                    Rd_NSO <= '1';
                    Cs_NSO <= '0';
                    Wr_NSO <= '0';
                    IM0_SO <= '0';
                
                    StateNext_D <= StatePostTxWait;
                elsif(to_integer(unsigned(CurBurstCount_Persist_D)) > 0)then
                    CurBurstCount_D <= std_logic_vector(unsigned(CurBurstCount_Persist_D) - to_unsigned(1, 8));
                    WaitReq_SO <= '0';
                    DB_DIO <= (others => '0');

                    
                    LcdReset_NRO <= '1';  
                    Rd_NSO <= '1';
                    Cs_NSO <= '1';
                    Wr_NSO <= '1';
                    IM0_SO <= '0';
                    
                    if(IsData_D = '1')then
                        StateNext_D <= StatePostTxBurstWaitData;
                    else
                        StateNext_D <= StatePostTxBurstWaitCmd;
                    end if;
                else                                
                    LcdReset_NRO <= '1';  
                    Rd_NSO <= '1';
                    Cs_NSO <= '1';
                    Wr_NSO <= '1';
                    IM0_SO <= '0';
                    IdleCount_D <= std_logic_vector(to_unsigned(0, 8));
                    
                    WaitReq_SO <= '0';
                    DB_DIO <= (others => '0');
                    StateNext_D <= StateIdle;
                end if;
                SetIdleCount_S <= '1';
                SetCurBurstCount_S <= '1';

            when StatePostTxBurstWaitData =>
                SetCurBurstCount_S <= '0';
                StateNext_D <= StateTxDataIdentifier;

                
            when StatePostTxBurstWaitCmd =>
                SetCurBurstCount_S <= '0';
                StateNext_D <= StateTxCmd;
                
            when StatePostTxWait =>
                SetIdlecount_S <= '0';
                SetCurBurstCount_S <= '0';
                DB_DIO <= x"002C"; 
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '0';                
                IM0_SO <= '0';  
                WaitReq_SO <= '1';
                
                StateNext_D <= StatePostTx;
            when others =>
                SetCurBurstCount_S <= '0';
                SetIdleCount_S <= '0';

                WaitReq_SO <= '0';
                StateNext_D <= StateLcdReset;
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '1';                
                IM0_SO <= '0';        
                
                IdleCount_D <= std_logic_vector(to_unsigned(0, 8));
                LcdReset_NRO <= '0';
                
                StateNext_D <= StateReset;
        end case;
    end process logic; 
end LCD;