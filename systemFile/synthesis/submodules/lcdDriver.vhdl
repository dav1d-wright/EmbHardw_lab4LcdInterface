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
        BurstCount_DI:              in std_logic_vector (7 downto 0);
        
        --! Wait request signal output
        WaitReq_SO:                 out std_logic;
        --! Read data output
        ReadData_DO:		        out std_logic_vector (15 downto 0);
        --! Read data valid signal output
        ReadDataValid_SO:           out std_logic;
        
        --! Wait request signal input for DMA
        DMA_WaitReq_SI:             in std_logic;
        --! Address data output for DMA
        DMA_Address_DO:             out std_logic_vector (31 downto 0);
        --! Read signal output for DMA
        DMA_Read_SO:                out std_logic;
        --! Read data input for DMA
        DMA_ReadData_DI:            in std_logic_vector (15 downto 0);
        --! Write signal output for DMA
        DMA_Write_SO:               out std_logic;
        --! Write data output for DMA
        DMA_WriteData_DO:           out std_logic_vector (15 downto 0);
        --! Interrupt request output for DMA
        DMA_IRQ_SO:                 out std_logic;
        --! Read data valid signal input for DMA
        DMA_ReadDataValid_SI:       in std_logic;

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
    --! @defgroup reg Registers 
    --! @{
    constant RegWriteData:           std_logic_vector(15 downto 0) := x"0000";
    constant RegWriteCmd:            std_logic_vector(15 downto 0) := x"0002";
    
    constant RegStatusAddr:         std_logic_vector (15 downto 0) := x"0000";
    signal RegStatus:               std_logic_vector (15 downto 0);
    
    constant RegCtrlAddr:           std_logic_vector (15 downto 0) := x"0001";
    signal RegCtrl:                 std_logic_vector (15 downto 0);
    
    constant RegErrorAddr:          std_logic_vector (15 downto 0) := x"0002";
    signal RegError:                std_logic_vector (15 downto 0);
    
    constant RegReservedAddr:       std_logic_vector (15 downto 0) := x"0003";
    signal regReserved:             std_logic_vector (15 downto 0);
    
    constant RegSrcAddr:            std_logic_vector (15 downto 0) := x"0004";
    signal RegSrc:                  std_logic_vector (31 downto 0);
    
    constant ReDestAddr:            std_logic_vector (15 downto 0) := x"0005";
    signal RegDest:                 std_logic_vector (31 downto 0);
    
    constant RegDataAddr:           std_logic_vector (15 downto 0) := x"0006";
    signal RegData:                 std_logic_vector (31 downto 0);
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
                                    StateIdle,
                                    StateNextBurstItem,
                                    StateEvalData,
                                    StateTxCmd,
                                    StateTxData,
                                    StatePostTx);
    
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
    signal BurstCount_D:                std_logic_vector (7 downto 0) := (others => '0');
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
    signal BurstCount_P_D:              std_logic_vector (7 downto 0) := (others => '0');
    --! @}

    --! @defgroup inpPP Input delayed two steps
    --! @{
    
    
    --! @brief Address delayed one step
    signal Address_PP_D:     	        std_logic_vector (15 downto 0) := (others => '0');
    --! @brief Write delayed one step
    signal Write_PP_S:     	            std_logic := '0';
    --! @brief WriteData delayed one step
    signal WriteData_PP_D:		        std_logic_vector (15 downto 0) := (others => '0');
    --! @brief ByteEnable delayed one step
    signal ByteEnable_PP_D:             std_logic_vector (1 downto 0) := (others => '0');
    --! @brief BeginBurstTransfer delayed one step
    signal BeginBurstTransfer_PP_S:     std_logic := '0';
    --! @brief BurstCount delayed one step
    signal BurstCount_PP_D:             std_logic_vector (7 downto 0) := (others => '0');
    --! @}
    
    --! @defgroup myInp Input dedicated for LcdDriver
    --! @{
    
    
    --! @brief Address dedicated for LcdDriver
    signal MyAddress_D:     	        std_logic_vector (15 downto 0) := (others => '0');
    --! @brief WriteData dedicated for LcdDriver
    signal MyWriteData_D:		        std_logic_vector (15 downto 0) := (others => '0');
    --! @brief ByteEnable dedicated for LcdDriver
    signal MyByteEnable_D:              std_logic_vector (1 downto 0) := (others => '0');
    --! @brief BeginBurstTransfer dedicated for LcdDriver
    signal MyBeginBurstTransfer_S:      std_logic := '0';
    --! BurstCount dedicated for LcdDriver
    signal MyBurstCount_D:              std_logic_vector (7 downto 0) := (others => '0');
    --! @}
        
    --! @defgroup cnt counters
    --! @{
    signal BurstCountPres_D:            std_logic_vector (7 downto 0) := (others => '0');
    signal BurstCountNext_D:            std_logic_vector (7 downto 0) := (others => '0');
    signal IdleCountPres_D:             std_logic_vector (31 downto 0) := (others => '0');
    signal IdleCountNext_D:             std_logic_vector (31 downto 0) := (others => '0');
    signal BurstStreamCountPres_D:      std_logic_vector (7 downto 0) := (others => '0');
    signal BurstStreamCountNext_D:      std_logic_vector (7 downto 0) := (others => '0');
    --! @}
    
    --! @brief Burst stream type
    type stream_T                       is array (255 downto 0) of std_logic_vector (15 downto 0);
    --! @brief Burst stream 
    signal BurstStream_D:               stream_T;
begin
    --! @brief This process synchronises input data with the clock 
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
            if(MyBeginBurstTransfer_S = '1')then
                if((Write_PP_S = '1') and (unsigned(BurstStreamCountPres_D) < unsigned(MyBurstCount_D)))then
                    BurstStream_D(to_integer(unsigned(BurstStreamCountPres_D))) <= WriteData_PP_D;
                    BurstStreamCountNext_D <= std_logic_vector(unsigned(BurstStreamCountPres_D) + to_unsigned(1, 8));
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
    end process;
    
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
                BurstCountNext_D <= BurstCountPres_D;

                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '1';                
                IM0_SO <= '0';
                
                LcdReset_NRO <= '0';
                
                DMA_Address_DO <= (others => '0');
                DMA_IRQ_SO <= '0';
                DMA_Read_SO <= '0';
                
            when StateLcdReset =>
                --! reset LCD
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '0';                
                IM0_SO <= '0';
                WaitReq_SO <= '1';
                BurstCountNext_D <= BurstCountPres_D;


                if(to_integer(unsigned(IdleCountPres_D)) > 0)then
                    IdleCountNext_D <= std_logic_vector(unsigned(IdleCountPres_D) - to_unsigned(1, 32));
                    StateNext_D <= StateLcdReset;
                else
                    IdleCountNext_D <= (others => '0');
                    StateNext_D <= StateIdle;
                end if;
                
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
                IM0_SO <= '0';
                
                WaitReq_SO <= '0';

                if(Write_Edge_D = '1')then
                    MyAddress_D <= Address_PP_D;
                    MyBeginBurstTransfer_S <= BeginBurstTransfer_PP_S;
                    MyBurstCount_D <= BurstCount_PP_D;
                    MyWriteData_D <= WriteData_PP_D;

                    -- if(BeginBurstTransfer_PP_S = '1')then
                        -- MyByteEnable_D <= (others => '1');
                        -- BurstCountNext_D <= BurstCount_PP_D;
                    -- else
                        BurstCountNext_D <= (others => '0');
                        MyByteEnable_D <= ByteEnable_PP_D;
                    -- end if;
                    
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
                IM0_SO <= '0';
                MyByteEnable_D <= (others => '1');
                

                if(BurstStreamCountPres_D > BurstCountPres_D)then
                    WaitReq_SO <= '1';
                    MyWriteData_D <= BurstStream_D(to_integer(unsigned(BurstCountPres_D)));
                    
                    StateNext_D <= StateEvalData;
                else
                    WaitReq_SO <= '0';
                    MyWriteData_D <= (others => '0');
                    StateNext_D <= StateNextBurstItem;
                end if;
                
            when StateEvalData =>
                --! evaluate data from CPU

                WaitReq_SO <= '0';
                
                Rd_NSO <= '1';   
                Wr_NSO <= '0';              
                Cs_NSO <= '0';               
                LcdReset_NRO <= '1';                
                IM0_SO <= '0';
                
                DB_DIO <= MyWriteData_D and BitEnable_D;

                BurstCountNext_D <= BurstCountPres_D;
                
                if(to_integer(unsigned(IdleCountPres_D)) > 0)then
                    IdleCountNext_D <= std_logic_vector(unsigned(IdleCountPres_D) - to_unsigned(1, 32));
                    StateNext_D <= StateEvalData;
                else
                    IdleCountNext_D <= std_logic_vector(to_unsigned(3, 32));
                    IdleCountNext_D <= (others => '0');
                    case MyAddress_D is
                        when RegWriteData =>
                            DC_NSO <= '1';
                            StateNext_D <= StateTxData;
                        when RegWriteCmd =>
                            DC_NSO <= '0';
                            StateNext_D <= StateTxCmd;
                        when others =>
                            StateNext_D <= StateIdle;
                    end case;
                end if;

                
            when StateTxCmd =>
                --! transfer command identifier to LCD
                WaitReq_SO <= '0';
                case MyByteEnable_D is
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
                Wr_NSO <= '1';
                IM0_SO <= '0';
                
                IdleCountNext_D <= std_logic_vector(to_unsigned(3, 32));
                BurstCountNext_D <= BurstCountPres_D;
                
                DB_DIO <= MyWriteData_D and BitEnable_D;
                
                StateNext_D <= StatePostTx;

            when StateTxData =>             
                --! transfer data to LCD
                WaitReq_SO <= '0';
                case MyByteEnable_D is
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
                Wr_NSO <= '1';
                IM0_SO <= '0';
                
                IdleCountNext_D <= std_logic_vector(to_unsigned(3, 32));
                BurstCountNext_D <= BurstCountPres_D;

                DB_DIO <= MyWriteData_D and BitEnable_D;

                StateNext_D <= StatePostTx;
                
            when StatePostTx =>
                --! wait for idle count to finish, then if this is a burst transfer, continue burst or go to idle
                case MyAddress_D is
                    when RegWriteData => 
                        DC_NSO <= '1';
                    when RegWriteCmd =>
                        DC_NSO <= '0';
                    when others =>
                        DC_NSO <= '1';
                end case;

                WaitReq_SO <= '0';
                case MyByteEnable_D is
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
                
                DB_DIO <= MyWriteData_D and BitEnable_D;
                
                LcdReset_NRO <= '1';  
                Rd_NSO <= '1';
                Cs_NSO <= '0';
                Wr_NSO <= '1';
                IM0_SO <= '0';
                
                if(to_integer(unsigned(IdleCountPres_D)) > 0)then
                    IdleCountNext_D <= std_logic_vector(unsigned(IdleCountPres_D) - to_unsigned(1, 32));
                    BurstCountNext_D <= BurstCountPres_D;
                
                    StateNext_D <= StatePostTx;
                elsif(to_integer(unsigned(BurstCountPres_D)) > 0)then
                    BurstCountNext_D <= std_logic_vector(unsigned(BurstCountPres_D) - to_unsigned(1, 8));                    
                    IdleCountNext_D <= (others => '0');
                    
                    StateNext_D <= StateNextBurstItem;

                else
                    MyAddress_D <= (others => '1');
                    MyBeginBurstTransfer_S <= '0';
                    MyBurstCount_D <= (others => '0');
                    MyByteEnable_D <= (others => '0');
                    MyWriteData_D <= (others => '0');
                    BurstCountNext_D <= (others => '0');
                    IdleCountNext_D <= (others => '0');
                
                    StateNext_D <= StateIdle;
                end if;
                
            when others =>
                --! this state should not occur
                WaitReq_SO <= '0';
                StateNext_D <= StateLcdReset;
                DB_DIO <= (others => '0');     
                Rd_NSO <= '1';   
                Wr_NSO <= '1';              
                Cs_NSO <= '1';               
                DC_NSO <= '1';
                LcdReset_NRO <= '1';                
                IM0_SO <= '0';      
                BurstCountNext_D <= (others => '0');
                IdleCountNext_D <= (others => '0');
                LcdReset_NRO <= '0';
                
                StateNext_D <= StateReset;
        end case;
    end process logic; 
end LCD;