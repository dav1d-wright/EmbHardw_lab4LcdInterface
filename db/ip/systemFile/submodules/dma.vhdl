-------------------------------------------------------
--! @file dma.vhdl
--! @author David Wright
--! @brief DMA driver. Translates avalon bus data and commands to the DMA interface
-------------------------------------------------------

 
--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

--! @brief DMA driver

--! Interface between Avalon bus
--! and DMA
entity DmaMaster is
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
        BurstCount_DI:              in std_logic_vector (16 downto 0);
        
        --! Wait request signal output
        WaitReq_SO:                 out std_logic;
        --! Read data output
        ReadData_DO:		        out std_logic_vector (15 downto 0);
        --! Read data valid signal output
        ReadDataValid_SO:           out std_logic;
        
        --! Wait request signal input for DMA Master
        Master_WaitReq_SI:             in std_logic;
        --! Address data output for DMA Master
        Master_Address_DO:             out std_logic_vector (31 downto 0);
        --! Read signal output for DMA Master
        Master_Read_SO:                out std_logic;
        --! Read data input for DMA Master
        Master_ReadData_DI:            in std_logic_vector (15 downto 0);
        --! Write signal output for DMA Master
        Master_Write_SO:               out std_logic;
        --! Write data output for DMA Master
        Master_WriteData_DO:           out std_logic_vector (15 downto 0);
        --! Interrupt request output for DMA Master
        Master_IRQ_SO:                 out std_logic;
        --! Read data valid signal input for DMA Master
        Master_ReadDataValid_SI:       in std_logic;
        Master_WriteResponseValid_SI:   in std_logic;
        Master_BurstCount_DO:           out std_logic_vector (16 downto 0);
        Master_Response_DI:             in std_logic_vector (1 downto 0)
    );
end DmaMaster;

architecture DMA of DmaMaster is 
    --! @defgroup DmaAddressableReg DMA Registers addressable from avalon bus
    --! @{    
    constant RegStateAddr:                  std_logic_vector (15 downto 0) := x"0000";
    constant RegStateDone:                  std_logic_vector (15 downto 0) := x"0001";
    constant RegStateBusy:                  std_logic_vector (15 downto 0) := x"0002";
    constant RegStateReop:                  std_logic_vector (15 downto 0) := x"0004";
    constant RegStateWeop:                  std_logic_vector (15 downto 0) := x"0008";
    signal RegStatePres_D:                  std_logic_vector (15 downto 0) := (others => '0');
    signal RegStateNext_D:                  std_logic_vector (15 downto 0) := (others => '0');
            
    constant RegCtrlAddr:                   std_logic_vector (15 downto 0) := x"0002";
    constant RegCtrlDirect:                 std_logic_vector (15 downto 0) := x"0001";
    constant RegCtrlDma:                    std_logic_vector (15 downto 0) := x"0002";
    constant RegCtrlNumEl:                  std_logic_vector (15 downto 0) := x"0004";
    constant RegCtrlGo:                     std_logic_vector (15 downto 0) := x"0008";
    -- constant RegCtrlHW:                     std_logic_vector (15 downto 0) := x"0001";
    -- constant RegCtrlWord:                   std_logic_vector (15 downto 0) := x"0002";
    -- constant RegCtrlGo:                     std_logic_vector (15 downto 0) := x"0004";
    -- constant RegCtrlIRQ:                    std_logic_vector (15 downto 0) := x"0008";
    -- constant RegCtrlReen:                   std_logic_vector (15 downto 0) := x"0010";
    -- constant RegCtrlLeen:                   std_logic_vector (15 downto 0) := x"0020";
    -- constant RegCtrlRcon:                   std_logic_vector (15 downto 0) := x"0040";
    -- constant RegCtrlRWcon:                  std_logic_vector (15 downto 0) := x"0080";
    signal RegCtrlPres_D:                   std_logic_vector (15 downto 0) := (others => '0');
    signal RegCtrlNext_D:                   std_logic_vector (15 downto 0) := (others => '0');
            
    constant RegErrorAddr:                  std_logic_vector (15 downto 0) := x"0004";
    signal RegErrorPres_D:                  std_logic_vector (15 downto 0) := (others => '0');
    signal RegErrorNext_D:                  std_logic_vector (15 downto 0) := (others => '0');
            
    constant RegReservedAddr:               std_logic_vector (15 downto 0) := x"0006";
    --signal regReserved:                     std_logic_vector (15 downto 0) := (others => '0');
    
    constant RegSrcMSWAddr:                std_logic_vector (15 downto 0) := x"0008";
    constant RegSrcLSWAddr:                 std_logic_vector (15 downto 0) := x"000A";
    signal RegSrcPres_D:                    std_logic_vector (31 downto 0) := (others => '0');
    signal RegSrcNext_D:                    std_logic_vector (31 downto 0) := (others => '0');

    constant RegDestMSWAddr:                std_logic_vector (15 downto 0) := x"000C";
    constant RegDestLSWAddr:                std_logic_vector (15 downto 0) := x"000E";
    signal RegDestPres_D:                   std_logic_vector (31 downto 0) := (others => '0');
    signal RegDestNext_D:                   std_logic_vector (31 downto 0) := (others => '0');
    
    constant RegDataAddr:                   std_logic_vector (15 downto 0) := x"0010";
    signal RegDataPres_D:                   std_logic_vector (15 downto 0) := (others => '0');
    signal RegDataNext_D:                   std_logic_vector (15 downto 0) := (others => '0');
    --! @}
    
    --! @defgroup DmaInternalReg DMA Internal registers
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
    --!         <td>StateDMAReset</td><td>DMA reset state </td>
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
                                    StateResetIntRegData,
                                    StateIdle,
                                    StateNextBurstItem,
                                    StateEvalData,
                                    StateRequestRx,
                                    StateRx,
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
    --! @brief Synchronised wait request signal input for DMA Master output
    signal Master_WaitReq_S:               std_logic := '0';
    --! @brief Synchronised read data input for DMA Master output
    signal Master_ReadData_D:              std_logic_vector (15 downto 0) := (others => '0');
    --! @brief Synchronised read data valid signal input for DMA Master output
    signal Master_ReadDataValid_S:         std_logic := '0';
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
    --! @brief Read data input for DMA Master output delayed one step
    signal Master_ReadData_P_D:            std_logic_vector (15 downto 0) := (others => '0');
    --! @brief Synchronised read data valid signal input for DMA Master output delayed one step
    signal Master_ReadDataValid_P_S:       std_logic := '0';
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
    --! @brief Read data input for DMA Master output delayed two steps
    signal Master_ReadData_PP_D:           std_logic_vector (15 downto 0) := (others => '0');
    --! @brief Synchronised read data valid signal input for DMA Master output delayed two steps
    signal Master_ReadDataValid_PP_S:      std_logic := '0';
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
            Master_ReadDataValid_S <= '0';
            Master_ReadData_D <= (others => '0');
            Master_WaitReq_S <= '0';
            
            Address_P_D <= (others => '0');    	    
            Write_P_S <= '0';           	    
            WriteData_P_D <= (others => '0');    		    
            ByteEnable_P_D <= (others => '0');            
            BeginBurstTransfer_P_S <= '0';    
            BurstCount_P_D <= (others => '0');          
            Master_ReadDataValid_P_S <= '0';
            Master_ReadData_P_D <= (others => '0');
            
            Address_PP_D <= (others => '0');    	    
            Write_PP_S <= '0';           	    
            WriteData_PP_D <= (others => '0');    		    
            ByteEnable_PP_D <= (others => '0');            
            BeginBurstTransfer_PP_S <= '0';    
            BurstCount_PP_D <= (others => '0');          
            Master_ReadDataValid_PP_S <= '0';
            Master_ReadData_PP_D <= (others => '0');
            
        elsif(Clk_CI'event and Clk_CI = '1')then
            Address_D <= Address_DI;   	    
            Write_S <= Write_SI;
            WriteData_D <= WriteData_DI;    
            Read_S <= Read_SI;
            ByteEnable_D <= ByteEnable_DI;   
            BeginBurstTransfer_S <= BeginBurstTransfer_SI;
            BurstCount_D <= BurstCount_DI;
            Master_ReadDataValid_S <= Master_ReadDataValid_SI;
            Master_ReadData_D <= Master_ReadData_DI;              	    
            Master_WaitReq_S <= Master_WaitReq_SI;

            Address_P_D <= Address_D;
            Write_P_S <= Write_S;
            WriteData_P_D <= WriteData_D;    
            ByteEnable_P_D <= ByteEnable_D;   
            BeginBurstTransfer_P_S <= BeginBurstTransfer_S;
            BurstCount_P_D <= BurstCount_D;
            Master_ReadDataValid_P_S <= Master_ReadDataValid_S;
            Master_ReadData_P_D <= Master_ReadData_D;              	    
            
            Address_PP_D <= Address_P_D;   	    
            Write_PP_S <= Write_P_S;
            WriteData_PP_D <= WriteData_P_D;    
            ByteEnable_PP_D <= ByteEnable_P_D;   
            BeginBurstTransfer_PP_S <= BeginBurstTransfer_P_S;
            BurstCount_PP_D <= BurstCount_P_D;
            Master_ReadDataValid_PP_S <= Master_ReadDataValid_P_S;
            Master_ReadData_PP_D <= Master_ReadData_P_D;              	    
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
    --! @todo Implement Rx and Tx burst!!
    burstStream: process(Reset_NRI, Clk_CI)
    begin
        if(Reset_NRI = '0')then
            BurstStreamCountNext_D <= (others => '0');
        elsif(Clk_CI'event and Clk_CI = '1')then
            if(StatePres_D = StateRx)then
                if((Master_ReadDataValid_S = '1') and (unsigned(BurstStreamCountPres_D) < unsigned(RegBurstCountPres_D)))then
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
            RegStatePres_D <= (others => '0');
            RegCtrlPres_D <=(others => '0');
            RegErrorPres_D <=(others => '0');
            RegSrcPres_D <=(others => '0');
            RegDestPres_D <= (others => '0');
            RegDataPres_D <= (others => '0');
        elsif(Clk_CI'event and Clk_CI = '1')then
            RegAddressPres_D <= RegAddressNext_D;
            RegRxDataPres_D <= RegRxDataNext_D;
            RegByteEnablePres_D <= RegByteEnableNext_D;
            RegBeginBurstTransferPres_S <= RegBeginBurstTransferNext_S;
            RegBurstCountPres_D <= RegBurstCountPres_D;
            RegStatePres_D <= RegStateNext_D;
            RegCtrlPres_D <= RegCtrlNext_D;
            RegErrorPres_D <= RegErrorNext_D;
            RegSrcPres_D <= RegSrcNext_D;
            RegDestPres_D <= RegDestNext_D;
            RegDataPres_D <= RegDataNext_D;
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
        variable RegTmp16_D:        std_logic_vector (15 downto 0) := (others => '0');
        variable RegTmp32_D:        std_logic_vector (31 downto 0) := (others => '0');
    begin  
        --! State machine implementation
        case StatePres_D is
            --! Label "StateReset"
            when StateReset =>
                --! reset state
                WaitReq_SO <= '0';
                StateNext_D <= StateIdle;
                IdleCountNext_D <= std_logic_vector(to_unsigned(500000000, 32));
                BurstCountNext_D <= (others => '0');
                
                Master_Address_DO <= (others => '0');
                Master_IRQ_SO <= '0';
                Master_Read_SO <= '0';
                Master_Write_SO <= '0';
                Master_WriteData_DO <= (others => '0');
                
                RegAddressNext_D <= (others => '0');
                RegRxDataNext_D <= (others => '0');
                RegByteEnableNext_D <= (others => '0');
                RegBeginBurstTransferNext_S <= '0';
                RegBurstCountNext_D <= (others => '0');
                RegStateNext_D <= (others => '0');
                RegCtrlNext_D <=(others => '0');
                RegErrorNext_D <=(others => '0');
                RegSrcNext_D <=(others => '0');
                RegDestNext_D <= (others => '0');
                RegDataNext_D <= (others => '0');
                
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
                
                WaitReq_SO <= '0';
                
                Master_Address_DO <= (others => '0');
                Master_IRQ_SO <= '0';
                Master_Read_SO <= '0';
                Master_Write_SO <= '0';
                Master_WriteData_DO <= (others => '0');
                
                RegStateNext_D <= RegStatePres_D;
                RegCtrlNext_D <= RegCtrlPres_D;
                RegErrorNext_D <= RegErrorPres_D;
                RegSrcNext_D <= RegSrcPres_D;
                RegDestNext_D <= RegDestPres_D;
                RegDataNext_D <= RegDataPres_D;
                                
                if(Read_Edge_D = '1')then
                    RegAddressNext_D <= Address_P_D;
                    RegBeginBurstTransferNext_S <= BeginBurstTransfer_P_S;
                    RegBurstCountNext_D <= BurstCount_P_D;
                    RegRxDataNext_D <= WriteData_P_D;

                    if(BeginBurstTransfer_P_S = '1')then
                        RegByteEnableNext_D <= (others => '1');
                        BurstCountNext_D <= BurstCount_P_D;
                    else
                        BurstCountNext_D <= BurstCount_P_D;
                        RegByteEnableNext_D <= ByteEnable_P_D;
                    end if;
                    
                    StateNext_D <= StateEvalData;
                elsif((RegCtrlPres_D and RegCtrlGo) /= x"0000")then
                    StateNext_D <= StateRequestRx;
                else
                    StateNext_D <= StateIdle;
                end if;
            
            when StateNextBurstItem =>
                --! wait for next burst data
                IdleCountNext_D <= std_logic_vector(to_unsigned(2, 32));
                BurstCountNext_D <= BurstCountPres_D;
                
                Master_Address_DO <= (others => '0');
                Master_IRQ_SO <= '0';
                Master_Read_SO <= '0';
                Master_Write_SO <= '0';
                Master_WriteData_DO <= (others => '0');
                
                RegAddressNext_D <= RegAddressPres_D;
                RegRxDataNext_D <= RegRxDataPres_D;
                RegByteEnableNext_D <= RegByteEnablePres_D;
                RegBeginBurstTransferNext_S <= RegBeginBurstTransferPres_S;
                RegBurstCountNext_D <= RegBurstCountPres_D;
                RegStateNext_D <= RegStatePres_D;
                RegCtrlNext_D <= RegCtrlPres_D;
                RegErrorNext_D <= RegErrorPres_D;
                RegSrcNext_D <= RegSrcPres_D;
                RegDestNext_D <= RegDestPres_D;
                RegDataNext_D <= RegDataPres_D;
                
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

                Master_Address_DO <= (others => '0');
                Master_IRQ_SO <= '0';
                Master_Read_SO <= '0';
                Master_Write_SO <= '0';
                Master_WriteData_DO <= (others => '0');
                
                BurstCountNext_D <= BurstCountPres_D;
                
                RegAddressNext_D <= RegAddressPres_D;
                RegRxDataNext_D <= RegRxDataPres_D;
                RegByteEnableNext_D <= RegByteEnablePres_D;
                RegBeginBurstTransferNext_S <= RegBeginBurstTransferPres_S;
                RegBurstCountNext_D <= RegBurstCountPres_D;
                RegStateNext_D <= RegStatePres_D;
                RegCtrlNext_D <= RegCtrlPres_D;
                RegErrorNext_D <= RegErrorPres_D;
                RegSrcNext_D <= RegSrcPres_D;
                RegDestNext_D <= RegDestPres_D;
                RegDataNext_D <= RegDataPres_D;
                
                case RegAddressPres_D is
                    when RegStateAddr =>
                        RegStateNext_D <= RegRxDataPres_D;
                        StateNext_D <= StateIdle;
                    when RegCtrlAddr =>
                        RegCtrlNext_D <= RegRxDataPres_D;
                        StateNext_D <= StateIdle;
                    when RegErrorAddr =>
                        StateNext_D <= StateIdle;
                    when RegSrcMSWAddr =>
                        RegTmp32_D := RegSrcPres_D and x"0000FFFF";
                        RegSrcNext_D <= RegTmp32_D or std_logic_vector(resize(unsigned(RegRxDataPres_D), 32) sll 16);
                        StateNext_D <= StateIdle;
                    when RegSrcLSWAddr =>
                        RegTmp32_D := RegSrcPres_D and x"FFFF0000";
                        RegSrcNext_D <= RegTmp32_D or std_logic_vector(resize(unsigned(RegRxDataPres_D), 32));
                        StateNext_D <= StateIdle;
                    when RegDestMSWAddr =>
                        RegTmp32_D := RegDestPres_D and x"0000FFFF";
                        RegDestNext_D <= RegTmp32_D or std_logic_vector(resize(unsigned(RegRxDataPres_D), 32) sll 16);
                        StateNext_D <= StateIdle;
                    when RegDestLSWAddr =>
                        RegTmp32_D := RegDestPres_D and x"FFFF0000";
                        RegDestNext_D <= RegTmp32_D or std_logic_vector(resize(unsigned(RegRxDataPres_D), 32));
                        StateNext_D <= StateIdle;
                    when RegDataAddr =>
                        RegDataNext_D <= RegRxDataPres_D;
                        StateNext_D <= StateIdle;
                    when others =>
                        StateNext_D <= StateIdle;
                end case;
                
            when StateRequestRx =>
                -- default values                
                IdleCountNext_D <= std_logic_vector(to_unsigned(2, 32));
                BurstCountNext_D <= BurstCountPres_D;

                Master_Address_DO <= RegSrcPres_D;
                Master_IRQ_SO <= '0';
                Master_Read_SO <= '1';
                Master_Write_SO <= '0';
                Master_WriteData_DO <= (others => '0');
                
                RegAddressNext_D <= RegAddressPres_D;
                RegRxDataNext_D <= RegRxDataPres_D;
                RegByteEnableNext_D <= RegByteEnablePres_D;
                RegBeginBurstTransferNext_S <= RegBeginBurstTransferPres_S;
                RegBurstCountNext_D <= RegBurstCountPres_D;
                RegStateNext_D <= RegStatePres_D;
                RegCtrlNext_D <= RegCtrlPres_D;
                RegErrorNext_D <= RegErrorPres_D;
                RegSrcNext_D <= RegSrcPres_D;
                RegDestNext_D <= RegDestPres_D;
                RegDataNext_D <= RegDataPres_D;
                
                if(Master_WaitReq_S = '1')then
                    StateNext_D <= StateRx;
                else
                    StateNext_D <= StateRequestRx;
                end if;
                
            when StateRx =>
                -- default values                
                IdleCountNext_D <= std_logic_vector(to_unsigned(2, 32));
                BurstCountNext_D <= BurstCountPres_D;

                Master_Address_DO <= RegSrcPres_D;
                Master_IRQ_SO <= '0';
                Master_Read_SO <= '1';
                Master_Write_SO <= '0';
                Master_WriteData_DO <= (others => '0');
                
                RegAddressNext_D <= RegAddressPres_D;
                RegRxDataNext_D <= RegRxDataPres_D;
                RegByteEnableNext_D <= RegByteEnablePres_D;
                RegBeginBurstTransferNext_S <= RegBeginBurstTransferPres_S;
                RegBurstCountNext_D <= RegBurstCountPres_D;
                RegStateNext_D <= RegStatePres_D;
                RegCtrlNext_D <= RegCtrlPres_D;
                RegErrorNext_D <= RegErrorPres_D;
                RegSrcNext_D <= RegSrcPres_D;
                RegDestNext_D <= RegDestPres_D;
                RegDataNext_D <= RegDataPres_D;
                
                if(Master_ReadDataValid_S = '1')then
                    RegDataNext_D <= Master_ReadData_D;
                    StateNext_D <= StateTx;
                else
                    RegDataNext_D <= RegDataPres_D;
                    StateNext_D <= StateRequestRx;
                end if;
                
                
            when StateTx =>
                WaitReq_SO <= '0';

                Master_Address_DO <= RegDestPres_D;
                Master_IRQ_SO <= '0';
                Master_Read_SO <= '0';
                Master_Write_SO <= '1';
                Master_WriteData_DO <= RegDataPres_D;
                
                BurstCountNext_D <= BurstCountPres_D;
                
                RegAddressNext_D <= RegAddressPres_D;
                RegRxDataNext_D <= RegRxDataPres_D;
                RegByteEnableNext_D <= RegByteEnablePres_D;
                RegBeginBurstTransferNext_S <= RegBeginBurstTransferPres_S;
                RegBurstCountNext_D <= RegBurstCountPres_D;
                RegStateNext_D <= RegStatePres_D;
                RegCtrlNext_D <= RegCtrlPres_D;
                RegErrorNext_D <= RegErrorPres_D;
                RegSrcNext_D <= RegSrcPres_D;
                RegDestNext_D <= RegDestPres_D;
                RegDataNext_D <= RegDataPres_D;
                
                if(Master_WaitReq_S = '1')then
                    StateNext_D <= StateTx;
                else
                    StateNext_D <= StateIdle;
                end if;

                
            -- when StateTx =>
                -- Master_Address_DO <= (others => '0');
                -- Master_IRQ_SO <= '0';
                -- Master_Read_SO <= '0';
                -- Master_Write_SO <= '0';
                -- Master_WriteData_DO <= (others => '0');
                
                -- RegAddressNext_D <= RegAddressPres_D;
                -- RegRxDataNext_D <= RegRxDataPres_D;
                -- RegByteEnableNext_D <= RegByteEnablePres_D;
                -- RegBeginBurstTransferNext_S <= RegBeginBurstTransferPres_S;
                -- RegBurstCountNext_D <= RegBurstCountPres_D;
                -- RegStateNext_D <= RegStatePres_D;
                -- RegCtrlNext_D <= RegCtrlPres_D;
                -- RegErrorNext_D <= RegErrorPres_D;
                -- RegSrcNext_D <= RegSrcPres_D;
                -- RegDestNext_D <= RegDestPres_D;
                -- RegDataNext_D <= RegDataPres_D;
                -- RegWriteDataNext_D <= RegWriteDataPres_D;
                -- RegWriteCmdNext_D <= RegWriteCmdPres_D; 
                
                -- WaitReq_SO <= '0';
                
                -- case RegAddressPres_D is
                    -- when RegWriteDataAddr => 
                        -- DC_NSO <= '1';
                    -- when RegWriteCmdAddr =>
                        -- DC_NSO <= '0';
                    -- when others =>
                        -- DC_NSO <= '1';
                -- end case;

                -- case RegByteEnablePres_D is
                    -- when "00" => 
                        -- BitEnable_D := (others => '0');
                    -- when "01" =>
                        -- BitEnable_D := "0000000011111111";
                    -- when "10" =>
                        -- BitEnable_D := "1111111100000000";
                    -- when "11" =>
                        -- BitEnable_D := (others => '1');
                    -- when others =>
                        -- BitEnable_D := (others => '0');
                -- end case;
                
                -- DB_DIO <= RegDataPres_D and BitEnable_D;
                
                -- DMAReset_NRO <= '1';  
                -- Rd_NSO <= '1';
                -- Cs_NSO <= '0';
                -- Wr_NSO <= '1';
                -- IM0_SO <= '0';
                
                -- if(to_integer(unsigned(IdleCountPres_D)) > 0)then
                    -- IdleCountNext_D <= std_logic_vector(unsigned(IdleCountPres_D) - to_unsigned(1, 32));
                    -- BurstCountNext_D <= BurstCountPres_D;
                
                    -- StateNext_D <= StateTx;
                -- elsif(to_integer(unsigned(BurstCountPres_D)) > 0)then
                    -- BurstCountNext_D <= std_logic_vector(unsigned(BurstCountPres_D) - to_unsigned(1, 8));                    
                    -- IdleCountNext_D <= (others => '0');
                    
                    -- StateNext_D <= StateNextBurstItem;

                -- else    
                    -- BurstCountNext_D <= (others => '0');                    
                    -- IdleCountNext_D <= (others => '0');
                    -- StateNext_D <= StateResetIntRegData;
                -- end if;
                
            when others =>
                --! this state should not occur
                WaitReq_SO <= '0';
                Master_Address_DO <= (others => '0');
                Master_IRQ_SO <= '0';
                Master_Read_SO <= '0';
                Master_Write_SO <= '0';
                Master_WriteData_DO <= (others => '0');
                
                RegAddressNext_D <= (others => '0');
                RegRxDataNext_D <= (others => '0');
                RegByteEnableNext_D <= (others => '0');
                RegBeginBurstTransferNext_S <= '0';
                RegBurstCountNext_D <= (others => '0');
                RegStateNext_D <= (others => '0');
                RegCtrlNext_D <=(others => '0');
                RegErrorNext_D <=(others => '0');
                RegSrcNext_D <=(others => '0');
                RegDestNext_D <= (others => '0');
                RegDataNext_D <= (others => '0');
                
                BurstCountNext_D <= (others => '0');
                IdleCountNext_D <= (others => '0');
                
                StateNext_D <= StateReset;
        end case;
    end process logic; 
end DMA;