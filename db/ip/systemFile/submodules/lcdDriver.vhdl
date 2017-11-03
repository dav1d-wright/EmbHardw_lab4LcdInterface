-------------------------------------------------------
--! @file lcdDriver.vhdl
--! @author David Wright
--! @brief LCD driver. Translates avalon bus data and commands to the LCD interface
-------------------------------------------------------

--! @mainpage This project is a Project for the MSE module TSM_EmbHardw during the autumn semester of 2017
--!
--! This project is implemented on the MSE-Embedded Board developed by Microlab at the Bern University of Applied Sciences (https://www.microlab.ti.bfh.ch/wiki/huce:microlab:projects:internal:mse-em-board)
--! @todo DO README!!!!
--! @todo CENTRALISE ALL TYPECASTS!!!
--! @todo DMA master inside LCDDriver
--! @todo display data identifier is sent from SW!! :)

 
--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

--! @brief LCD driver

--! Interface between Avalon bus
--! and LCD
entity LcdDriver is
    generic
    (
        PICSIZE_BIN:                    natural := 17;
        PICSIZE_DEC:                    natural := 76800
    );
    port
    (
        --! Clock input
        Clk_CI:         	        in std_logic;
        --! Reset input (Button 12 on Pin D6)
        Reset_NRI:      	        in std_logic;
        --! Address data input
        Address_DI:     	        in std_logic_vector (15 downto 0);
        --! Write signal input
        Write_SI:       	        in std_logic;
        --! Write data input
        WriteData_DI:		        in std_logic_vector (15 downto 0);
        --! Read signal input
        Read_SI:		            in std_logic;
        --! Byte enable data input
        ByteEnable_DI:              in std_logic_vector (1 downto 0);
        --! Begin burst transfer signal input
        BeginBurstTransfer_SI:      in std_logic;
        --! Burst count data input
        BurstCount_DI:              in std_logic_vector (PICSIZE_BIN-1 downto 0);
        
        --! Wait request signal output
        WaitReq_SO:                 out std_logic;
        --! Read data output
        ReadData_DO:		        out std_logic_vector (15 downto 0);
        --! Read data valid signal output
        ReadDataValid_SO:           out std_logic;

        --! data output to LCD
        DB_DIO:      		        inout std_logic_vector (15 downto 0);
        --! Read signal output to LCD
        Rd_NSO:                     out std_logic;
        --! Write signal output to LCD
        Wr_NSO:                     out std_logic;
        --! Chip select signal output to LCD
        Cs_NSO:                     out std_logic;
        --! Data/Command signal output to LCD
        DC_NSO:                     out std_logic;
        --! LCD reset output
        LcdReset_NRO:               out std_logic;
        --! Interface mode signal output to LCD
        IM0_SO:                     out std_logic
    );
end LcdDriver;

architecture LCD of LcdDriver is 
    --! @defgroup addressableReg Registers addressable from avalon bus
    --! @{        
    constant RegDataAddr:                   std_logic_vector (15 downto 0) := x"0000";
    signal RegDataPres_D:                   std_logic_vector (15 downto 0) := (others => '0');
    signal RegDataNext_D:                   std_logic_vector (15 downto 0) := (others => '0');
            
    constant RegWriteDataAddr:              std_logic_vector(15 downto 0) := x"0002";
    signal RegWriteDataPres_D:              std_logic_vector (15 downto 0) := (others => '0');
    signal RegWriteDataNext_D:              std_logic_vector (15 downto 0) := (others => '0');
            
    constant RegWriteCmdAddr:               std_logic_vector(15 downto 0) := x"0004";
    signal RegWriteCmdPres_D:               std_logic_vector (15 downto 0) := (others => '0');
    signal RegWriteCmdNext_D:               std_logic_vector (15 downto 0) := (others => '0');
    --! @}
    
    --! @defgroup internalReg Internal registers
    --! @{
    signal RegAddressNext_D:     	        std_logic_vector (15 downto 0) := (others => '0');
    signal RegAddressPres_D:     	        std_logic_vector (15 downto 0) := (others => '0');

    signal RegRxDataNext_D:		        std_logic_vector (15 downto 0) := (others => '0');
    signal RegRxDataPres_D:		        std_logic_vector (15 downto 0) := (others => '0');

    signal RegByteEnableNext_D:              std_logic_vector (1 downto 0) := (others => '0');
    signal RegByteEnablePres_D:              std_logic_vector (1 downto 0) := (others => '0');

    signal RegBeginBurstTransferNext_S:      std_logic := '0';
    signal RegBeginBurstTransferPres_S:      std_logic := '0';

    signal RegBurstCountNext_D:              std_logic_vector (PICSIZE_BIN-1 downto 0) := (others => '0');
    signal RegBurstCountPres_D:              std_logic_vector (PICSIZE_BIN-1 downto 0) := (others => '0');
    --! @}
    
    
    --! @defgroup states States for state machine
    --! @{
    
    
    --! @brief State machine states
    --!
    --! <table>
    --!     <caption id="multi_row">State machine description</caption>
    --!     <tr>
    --!         <th>State name</th> <th>Description</th>
    --!     </tr>
    --!     <tr>
    --!         <td>StateReset</td><td>Reset state</td>
    --!     </tr>
    --!     <tr>
    --!         <td>StateLcdReset</td><td>Lcd reset state </td>
    --!     </tr>
    --!     <tr>
    --!         <td>StateIdle</td><td>Idle state</td>
    --!     </tr>
    --!     <tr>
    --!         <td>StateNextBurstItem</td><td>Next burst item state</td>
    --!     </tr>
    --!     <tr>
    --!         <td>StateEvalData</td><td>Data evaluation state</td>
    --!     </tr>
    --!     <tr>
    --!         <td>StateTxCmd</td><td>Command transmit state</td>
    --!     </tr>
    --!     <tr>
    --!         <td>StateTxData</td><td>Data transmit state</td>
    --!     </tr>
    --!     <tr>
    --!         <td>StatePostTx</td><td> Post transmit state</td>
    --!     </tr>
    --! </table>
    type State_T                is (
                                    StateReset,
                                    StateLcdReset,
                                    StateResetIntRegData,
                                    StateIdle,
                                    StateNextBurstItem,
                                    StateEvalData,
                                    StatePrepareTx,
                                    StateTx);
    
    --! @brief Next state
    signal StateNext_D:             State_T := StateReset;
    --! @brief Present state
    signal StatePres_D:             State_T := StateReset;
    --! @}

    --! @brief Edge detection of Write_SI
    signal Write_Edge_D:                std_logic := '0';
    --! @brief Last state of Write_SI
    signal Write_Last_D:                std_logic := '0';

    --! @brief Edge detection of Read_SI    
    signal Read_Edge_D:                 std_logic := '0';
    --! @brief Last state of Read_SI
    signal Read_Last_D:                 std_logic := '0';
            
    --! @defgroup syncInp Synchronised input data
    --! @{    
    --! Synchronised Address
    signal Address_D:     	            std_logic_vector (15 downto 0) := (others => '0');
    --! @brief Synchronised Write
    signal Write_S:       	            std_logic := '0';
    --! @brief Synchronised WriteData
    signal WriteData_D:		            std_logic_vector (15 downto 0) := (others => '0');
    --! @brief Synchronised Read
    signal Read_S:		                std_logic := '0';
    --! @brief Synchronised ByteEnable
    signal ByteEnable_D:                std_logic_vector (1 downto 0) := (others => '0');
    --! @brief Synchronised BeginBurstTransfer
    signal BeginBurstTransfer_S:        std_logic := '0';
    --! @brief Synchronised BurstCount
    signal BurstCount_D:                std_logic_vector (PICSIZE_BIN-1 downto 0) := (others => '0');
    --! @}

    --! @defgroup inpP Input delayed one step
    --! @{
    
    
    --! @brief Address delayed one step
    signal Address_P_D:     	        std_logic_vector (15 downto 0) := (others => '0');
    --! @brief Write delayed one step
    signal Write_P_S:     	            std_logic := '0';
    --! @brief WriteData delayed one step
    signal WriteData_P_D:		        std_logic_vector (15 downto 0) := (others => '0');
    --! @brief ByteEnable delayed one step
    signal ByteEnable_P_D:              std_logic_vector (1 downto 0) := (others => '0');
    --! @brief BeginBurstTransfer delayed one step
    signal BeginBurstTransfer_P_S:      std_logic := '0';
    --! @brief BurstCount delayed one step
    signal BurstCount_P_D:              std_logic_vector (PICSIZE_BIN-1 downto 0) := (others => '0');
    --! @}

    --! @defgroup inpPP Input delayed two steps
    --! @{
    
    
    --! @brief Address delayed two steps
    signal Address_PP_D:     	        std_logic_vector (15 downto 0) := (others => '0');
    --! @brief Write delayed two steps
    signal Write_PP_S:     	            std_logic := '0';
    --! @brief WriteData delayed two steps
    signal WriteData_PP_D:		        std_logic_vector (15 downto 0) := (others => '0');
    --! @brief ByteEnable delayed two steps
    signal ByteEnable_PP_D:             std_logic_vector (1 downto 0) := (others => '0');
    --! @brief BeginBurstTransfer delayed two steps
    signal BeginBurstTransfer_PP_S:     std_logic := '0';
    --! @brief BurstCount delayed two steps
    signal BurstCount_PP_D:             std_logic_vector (PICSIZE_BIN-1 downto 0) := (others => '0');
    --! @}
        
    --! @defgroup cnt counters
    --! @{
    signal BurstCountPres_D:            std_logic_vector (PICSIZE_BIN-1 downto 0) := (others => '0');
    signal BurstCountNext_D:            std_logic_vector (PICSIZE_BIN-1 downto 0) := (others => '0');
    signal IdleCountPres_D:             std_logic_vector (31 downto 0) := (others => '0');
    signal IdleCountNext_D:             std_logic_vector (31 downto 0) := (others => '0');
    signal BurstStreamCountPres_D:      std_logic_vector (PICSIZE_BIN-1 downto 0) := (others => '0');
    signal BurstStreamCountNext_D:      std_logic_vector (PICSIZE_BIN-1 downto 0) := (others => '0');
    --! @}
    
    --! @brief Burst stream type
    type stream_T                       is array (PICSIZE_DEC-1 downto 0) of std_logic_vector (15 downto 0);
    --! @brief Burst stream 
    signal BurstStream_D:               stream_T;
begin
    --! Concurrent assignment
    IM0_SO <= '0';

    --! @brief This process synchronises input data with the clock and buffers it 
    syncData: process(Reset_NRI, Clk_CI)
    begin
        if(Reset_NRI = '0')then
            Address_D <= (others => '0');    	    
            Write_S <= '0';           	    
            WriteData_D <= (others => '0');    		    
            Read_S <= '0';    		        
            ByteEnable_D <= (others => '0');            
            BeginBurstTransfer_S <= '0';    
            BurstCount_D <= (others => '0');          
            
            Address_P_D <= (others => '0');    	    
            Write_P_S <= '0';           	    
            WriteData_P_D <= (others => '0');    		    
            ByteEnable_P_D <= (others => '0');            
            BeginBurstTransfer_P_S <= '0';    
            BurstCount_P_D <= (others => '0');          
            
            Address_PP_D <= (others => '0');    	    
            Write_PP_S <= '0';           	    
            WriteData_PP_D <= (others => '0');    		    
            ByteEnable_PP_D <= (others => '0');            
            BeginBurstTransfer_PP_S <= '0';    
            BurstCount_PP_D <= (others => '0');          
            
        elsif(Clk_CI'event and Clk_CI = '1')then
            Address_D <= Address_DI;   	    
            Write_S <= Write_SI;
            WriteData_D <= WriteData_DI;    
            Read_S <= Read_SI;
            ByteEnable_D <= ByteEnable_DI;   
            BeginBurstTransfer_S <= BeginBurstTransfer_SI;
            BurstCount_D <= BurstCount_DI;

            Address_P_D <= Address_D;
            Write_P_S <= Write_S;
            WriteData_P_D <= WriteData_D;    
            ByteEnable_P_D <= ByteEnable_D;   
            BeginBurstTransfer_P_S <= BeginBurstTransfer_S;
            BurstCount_P_D <= BurstCount_D;          	    
            
            Address_PP_D <= Address_P_D;   	    
            Write_PP_S <= Write_P_S;
            WriteData_PP_D <= WriteData_P_D;    
            ByteEnable_PP_D <= ByteEnable_P_D;   
            BeginBurstTransfer_PP_S <= BeginBurstTransfer_P_S;
            BurstCount_PP_D <= BurstCount_P_D;            	    
        end if;
    end process;

    --! @brief This process detects positive edges of the Write_SI and Read_SI signals
    edgeDetect: process(Reset_NRI, Clk_CI)
    begin
        if(Reset_NRI = '0')then
            Read_Edge_D <= '0';
            Write_Edge_D <= '0';
            Read_Last_D <= '0';
            Write_Last_D <= '0';
        elsif(Clk_CI'event and Clk_CI = '1')then
            if(Write_Last_D = '0' and Write_S = '1')then
                Write_Edge_D <= '1';
            else
                Write_Edge_D <= '0';
            end if;
            
            Write_Last_D <= Write_S;
            
            if(Read_Last_D = '0' and Read_S = '1')then
                Read_Edge_D <= '1';
            else
                Read_Edge_D <= '0';
            end if;
        end if;
    end process edgeDetect;

    --! @brief This process fills the burst stream array
    burstStream: process(Reset_NRI, Clk_CI)
    begin
        if(Reset_NRI = '0')then
            BurstStreamCountNext_D <= (others => '0');
        elsif(Clk_CI'event and Clk_CI = '1')then
            if(RegBeginBurstTransferPres_S = '1')then
                if((Write_PP_S = '1') and (unsigned(BurstStreamCountPres_D) < unsigned(RegBurstCountPres_D)))then
                    BurstStream_D(to_integer(unsigned(BurstStreamCountPres_D))) <= WriteData_PP_D;
                    BurstStreamCountNext_D <= std_logic_vector(unsigned(BurstStreamCountPres_D) + to_unsigned(1, PICSIZE_BIN-1));
                else
                    BurstStreamCountNext_D <= BurstStreamCountPres_D;
                end if;
            else
                BurstStreamCountNext_D <= (others => '0');
            end if;
        end if;
    end process burstStream;
    
    --! @brief This process updates the values of the idle counter and burst counter
    counters: process (Reset_NRI, Clk_CI)
    begin
        if(Reset_NRI = '0')then
            BurstCountPres_D <= (others => '0');
            IdleCountPres_D <= (others => '0');
            BurstStreamCountPres_D <= (others => '0');
        elsif(Clk_CI'event and Clk_CI = '1')then
            BurstCountPres_D <= BurstCountNext_D;
            IdleCountPres_D <= IdleCountNext_D;
            BurstStreamCountPres_D <= BurstStreamCountNext_D;
        end if;
    end process counters;
    
    --! @brief This process updates the values of the registers
    regUpdate: process (Reset_NRI, Clk_CI)
    begin
        if(Reset_NRI = '0')then
            RegAddressPres_D <= (others => '0');
            RegRxDataPres_D <= (others => '0');
            RegByteEnablePres_D <= (others => '0');
            RegBeginBurstTransferPres_S <= '0';
            RegBurstCountPres_D <= (others => '0');
            RegDataPres_D <= (others => '0');
            RegWriteDataPres_D <= (others => '0');
            RegWriteCmdPres_D <= (others => '0');
        elsif(Clk_CI'event and Clk_CI = '1')then
            RegAddressPres_D <= RegAddressNext_D;
            RegRxDataPres_D <= RegRxDataNext_D;
            RegByteEnablePres_D <= RegByteEnableNext_D;
            RegBeginBurstTransferPres_S <= RegBeginBurstTransferNext_S;
            RegBurstCountPres_D <= RegBurstCountPres_D;
            RegDataPres_D <= RegDataNext_D;
            RegWriteDataPres_D <= RegWriteDataNext_D;
            RegWriteCmdPres_D <= RegWriteCmdNext_D;
        end if;
    end process regUpdate;
    
    --! @brief This process implements the next state logic
    nextState: process(Clk_CI, Reset_NRI)
    begin
        if(Reset_NRI = '0')then
            StatePres_D <= StateReset;
        elsif(Clk_CI'event and Clk_CI = '1')then
            StatePres_D <= StateNext_D;
        end if;
    end process;
    
    --! @brief This process implements the present state logic    
    logic: process(Write_Edge_D, StatePres_D, IdleCountPres_D)
        variable BitEnable_D:       std_logic_vector (15 downto 0) := (others => '0');
    begin  
        --! State machine implementation
        case StatePres_D is
            --! Label "StateReset"
            when StateReset =>
                --! reset state
                WaitReq_SO <= '0';
                StateNext_D <= StateLcdReset;
                IdleCountNext_D <= std_logic_vector(to_unsigned(500000000, 32));
                BurstCountNext_D <= (others => '0');

                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '1';                
                                
                RegAddressNext_D <= (others => '0');
                RegRxDataNext_D <= (others => '0');
                RegByteEnableNext_D <= (others => '0');
                RegBeginBurstTransferNext_S <= '0';
                RegBurstCountNext_D <= (others => '0');
                RegDataNext_D <= (others => '0');
                RegWriteDataNext_D <= (others => '0');
                RegWriteCmdNext_D <= (others => '0');
                
            when StateLcdReset =>
                --! reset LCD
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '0';                
                WaitReq_SO <= '1';
                BurstCountNext_D <= BurstCountPres_D;
                
                RegAddressNext_D <= (others => '0');
                RegRxDataNext_D <= (others => '0');
                RegByteEnableNext_D <= (others => '0');
                RegBeginBurstTransferNext_S <= '0';
                RegBurstCountNext_D <= (others => '0');
                RegDataNext_D <= (others => '0');
                RegWriteDataNext_D <= (others => '0');
                RegWriteCmdNext_D <= (others => '0');               

                if(to_integer(unsigned(IdleCountPres_D)) > 0)then
                    IdleCountNext_D <= std_logic_vector(unsigned(IdleCountPres_D) - to_unsigned(1, 32));
                    StateNext_D <= StateLcdReset;
                else
                    IdleCountNext_D <= (others => '0');
                    StateNext_D <= StateResetIntRegData;
                end if;
                
            when StateResetIntRegData =>
                BurstCountNext_D <= (others => '0');
                IdleCountNext_D <= (others => '0');
                RegAddressNext_D <= (others => '1');
                RegBeginBurstTransferNext_S <= '0';
                RegBurstCountNext_D <= (others => '0');
                RegByteEnableNext_D <= (others => '0');
                RegRxDataNext_D <= (others => '0');
                
            
                StateNext_D <= StateIdle;
                
            when StateIdle =>
                --! wait for data from CPU
                IdleCountNext_D <= std_logic_vector(to_unsigned(5, 32));
                BurstCountNext_D <= (others => '0');

                -- default values                
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '0';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '1';                

                RegAddressNext_D <= RegAddressPres_D;
                RegRxDataNext_D <= RegRxDataPres_D;
                RegByteEnableNext_D <= RegByteEnablePres_D;
                RegBeginBurstTransferNext_S <= RegBeginBurstTransferPres_S;
                RegBurstCountNext_D <= RegBurstCountPres_D;
                RegDataNext_D <= RegDataPres_D;
                RegWriteDataNext_D <= RegWriteDataPres_D;
                RegWriteCmdNext_D <= RegWriteCmdPres_D; 
                
                if(Write_Edge_D = '1')then
                    RegAddressNext_D <= Address_P_D;
                    RegBeginBurstTransferNext_S <= BeginBurstTransfer_P_S;
                    RegBurstCountNext_D <= BurstCount_P_D;
                    RegRxDataNext_D <= WriteData_P_D;

                    if(BeginBurstTransfer_P_S = '1')then
                        RegByteEnableNext_D <= (others => '1');
                        BurstCountNext_D <= BurstCount_P_D;
                    else
                        BurstCountNext_D <= (others => '0');
                        RegByteEnableNext_D <= ByteEnable_P_D;
                    end if;
                    
                    StateNext_D <= StateEvalData;
                else
                    StateNext_D <= StateIdle;
                end if;
                
            when StateNextBurstItem =>
                --! wait for next burst data
                IdleCountNext_D <= std_logic_vector(to_unsigned(2, 32));
                BurstCountNext_D <= BurstCountPres_D;

                -- default values                
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '0';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '1';                
                
                RegAddressNext_D <= RegAddressPres_D;
                RegRxDataNext_D <= RegRxDataPres_D;
                RegByteEnableNext_D <= RegByteEnablePres_D;
                RegBeginBurstTransferNext_S <= RegBeginBurstTransferPres_S;
                RegBurstCountNext_D <= RegBurstCountPres_D;
                RegDataNext_D <= RegDataPres_D;
                RegWriteDataNext_D <= RegWriteDataPres_D;
                RegWriteCmdNext_D <= RegWriteCmdPres_D; 
                
                if(BurstStreamCountPres_D > BurstCountPres_D)then
                    WaitReq_SO <= '1';
                    RegDataNext_D <= BurstStream_D(to_integer(unsigned(BurstCountPres_D)));
                    
                    StateNext_D <= StateEvalData;
                else
                    WaitReq_SO <= '0';
                    RegDataNext_D <= (others => '0');
                    StateNext_D <= StateNextBurstItem;
                end if;
                
            when StateEvalData =>
                --! evaluate data from CPU
                IdleCountNext_D <= std_logic_vector(to_unsigned(2, 32));
                BurstCountNext_D <= BurstCountPres_D;    
                
                WaitReq_SO <= '0';
                
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                LcdReset_NRO <= '1';                
                DC_NSO <= '0';
                DB_DIO <= (others => '0');
                
                BurstCountNext_D <= BurstCountPres_D;
                
                RegAddressNext_D <= RegAddressPres_D;
                RegRxDataNext_D <= RegRxDataPres_D;
                RegByteEnableNext_D <= RegByteEnablePres_D;
                RegBeginBurstTransferNext_S <= RegBeginBurstTransferPres_S;
                RegBurstCountNext_D <= RegBurstCountPres_D;
                RegDataNext_D <= RegDataPres_D;
                RegWriteDataNext_D <= RegWriteDataPres_D;
                RegWriteCmdNext_D <= RegWriteCmdPres_D; 
                
                case RegAddressPres_D is
                    when RegWriteDataAddr =>
                        RegDataNext_D <= RegRxDataPres_D;
                        StateNext_D <= StatePrepareTx;
                    when RegWriteCmdAddr =>
                        RegDataNext_D <= RegRxDataPres_D;
                        StateNext_D <= StatePrepareTx;
                    when others =>
                        StateNext_D <= StateIdle;
                end case;
                
            when StatePrepareTx =>
                WaitReq_SO <= '0';
                
                Rd_NSO <= '1';   
                Wr_NSO <= '0';              
                Cs_NSO <= '0';               
                LcdReset_NRO <= '1';                
                
                DB_DIO <= RegDataPres_D and BitEnable_D;
                
                BurstCountNext_D <= BurstCountPres_D;
                
                RegAddressNext_D <= RegAddressPres_D;
                RegRxDataNext_D <= RegRxDataPres_D;
                RegByteEnableNext_D <= RegByteEnablePres_D;
                RegBeginBurstTransferNext_S <= RegBeginBurstTransferPres_S;
                RegBurstCountNext_D <= RegBurstCountPres_D;
                RegDataNext_D <= RegDataPres_D;
                RegWriteDataNext_D <= RegWriteDataPres_D;
                RegWriteCmdNext_D <= RegWriteCmdPres_D; 
                
                case RegAddressPres_D is
                    when RegWriteDataAddr =>
                        DC_NSO <= '1';
                    when RegWriteCmdAddr =>
                        DC_NSO <= '0';
                    when others =>
                        DC_NSO <= '1';
                end case;
                
                if(to_integer(unsigned(IdleCountPres_D)) > 0)then
                    IdleCountNext_D <= std_logic_vector(unsigned(IdleCountPres_D) - to_unsigned(1, 32));
                    StateNext_D <= StatePrepareTx;
                else
                    IdleCountNext_D <= std_logic_vector(to_unsigned(3, 32));                    
                    StateNext_D <= StateTx;
                end if;

                
            when StateTx =>
                RegAddressNext_D <= RegAddressPres_D;
                RegRxDataNext_D <= RegRxDataPres_D;
                RegByteEnableNext_D <= RegByteEnablePres_D;
                RegBeginBurstTransferNext_S <= RegBeginBurstTransferPres_S;
                RegBurstCountNext_D <= RegBurstCountPres_D;
                RegDataNext_D <= RegDataPres_D;
                RegWriteDataNext_D <= RegWriteDataPres_D;
                RegWriteCmdNext_D <= RegWriteCmdPres_D; 
                
                WaitReq_SO <= '0';
                
                case RegAddressPres_D is
                    when RegWriteDataAddr => 
                        DC_NSO <= '1';
                    when RegWriteCmdAddr =>
                        DC_NSO <= '0';
                    when others =>
                        DC_NSO <= '1';
                end case;

                case RegByteEnablePres_D is
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
                
                DB_DIO <= RegDataPres_D and BitEnable_D;
                
                LcdReset_NRO <= '1';  
                Rd_NSO <= '1';
                Cs_NSO <= '0';
                Wr_NSO <= '1';
                
                if(to_integer(unsigned(IdleCountPres_D)) > 0)then
                    IdleCountNext_D <= std_logic_vector(unsigned(IdleCountPres_D) - to_unsigned(1, 32));
                    BurstCountNext_D <= BurstCountPres_D;
                
                    StateNext_D <= StateTx;
                elsif(to_integer(unsigned(BurstCountPres_D)) > 0)then
                    BurstCountNext_D <= std_logic_vector(unsigned(BurstCountPres_D) - to_unsigned(1, PICSIZE_BIN-1));                    
                    IdleCountNext_D <= (others => '0');
                    
                    StateNext_D <= StateNextBurstItem;

                else    
                    BurstCountNext_D <= (others => '0');                    
                    IdleCountNext_D <= (others => '0');
                    StateNext_D <= StateResetIntRegData;
                end if;
                
            when others =>
                --! this state should not occur
                WaitReq_SO <= '0';
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '1';                
                
                RegAddressNext_D <= (others => '0');
                RegRxDataNext_D <= (others => '0');
                RegByteEnableNext_D <= (others => '0');
                RegBeginBurstTransferNext_S <= '0';
                RegBurstCountNext_D <= (others => '0');
                RegDataNext_D <= (others => '0');
                RegWriteDataNext_D <= (others => '0');
                RegWriteCmdNext_D <= (others => '0');
                
                BurstCountNext_D <= (others => '0');
                IdleCountNext_D <= (others => '0');
                
                StateNext_D <= StateReset;
        end case;
    end process logic; 
end LCD;