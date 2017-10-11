library ieee;
use ieee.std_logic_1164.all;

entity parPort is
    port
    (
        -- communication between CPU and parPort
        Clk_CI:         	in std_logic;
        Reset_BRI:      	in std_logic;
        Address_DI:     	in std_logic_vector (2 downto 0);
        Write_SI:       	in std_logic;
        WriteData_DI:		in std_logic_vector (7 downto 0);
        Read_SI:		    in std_logic;
        ReadData_DO:		out std_logic_vector (7 downto 0);
      
        -- communication from parPort to peripheral block
        ParPort_DIO:		inout std_logic_vector (7 downto 0)
    );
end parPort;

architecture PP of parPort is
	signal RegDir_D: 		std_logic_vector (7 downto 0);
	signal RegPort_D: 		std_logic_vector (7 downto 0);
	signal RegPin_D:		std_logic_vector (7 downto 0);
    
component writer
    port
    (
        Clk_CI:         	in std_logic;
        Address_DI:     	in std_logic_vector (2 downto 0);
        Write_SI:		    in std_logic;
        WriteData_DI:       in std_logic_vector (7 downto 0);
              
        -- Register write from CPU
        RegDir_DO:          out std_logic_vector (7 downto 0);
        RegPort_DIO:        inout std_logic_vector (7 downto 0)
    );
end component;

component reader
    port
    (
        Clk_CI:         	in std_logic;
        Address_DI:     	in std_logic_vector (2 downto 0);
        Read_SI:		    in std_logic;
              
        -- Register write from CPU
        RegDir_DI:          in std_logic_vector (7 downto 0);
        RegPort_DI:         in std_logic_vector (7 downto 0);
        RegPin_DI:          in std_logic_vector (7 downto 0);
        
        -- ReadData output
        ReadData_DO:        out std_logic_vector (7 downto 0)
    );
end component;

begin

    writer1: writer port map(Clk_CI => Clk_CI, Address_DI => Address_DI, Write_SI => Write_SI, WriteData_DI => WriteData_DI, RegDir_DO => RegDir_D, RegPort_DIO => RegPort_D);
                            
    reader1: reader port map(Clk_CI => Clk_CI, Address_DI => Address_DI, Read_SI => Read_SI, RegDir_DI => RegDir_D, RegPort_DI => RegPort_D, RegPin_DI => RegPin_D, ReadData_DO => ReadData_DO);
    
    RegPin_D <= (RegPort_D and RegDir_D);
    ParPort_DIO <= RegPin_D;
end PP;