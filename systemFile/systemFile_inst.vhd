	component systemFile is
		port (
			altpll_0_c2_clk            : out   std_logic;                                        -- clk
			clk_clk                    : in    std_logic                     := 'X';             -- clk
			lcd_conduit_end_cs_n       : out   std_logic;                                        -- cs_n
			lcd_conduit_end_data       : inout std_logic_vector(15 downto 0) := (others => 'X'); -- data
			lcd_conduit_end_dc_n       : out   std_logic;                                        -- dc_n
			lcd_conduit_end_im0        : out   std_logic;                                        -- im0
			lcd_conduit_end_lcdreset_n : out   std_logic;                                        -- lcdreset_n
			lcd_conduit_end_rd_n       : out   std_logic;                                        -- rd_n
			lcd_conduit_end_wr_n       : out   std_logic;                                        -- wr_n
			reset_reset_n              : in    std_logic                     := 'X';             -- reset_n
			sdram_ctrl_wire_addr       : out   std_logic_vector(11 downto 0);                    -- addr
			sdram_ctrl_wire_ba         : out   std_logic_vector(1 downto 0);                     -- ba
			sdram_ctrl_wire_cas_n      : out   std_logic;                                        -- cas_n
			sdram_ctrl_wire_cke        : out   std_logic;                                        -- cke
			sdram_ctrl_wire_cs_n       : out   std_logic;                                        -- cs_n
			sdram_ctrl_wire_dq         : inout std_logic_vector(15 downto 0) := (others => 'X'); -- dq
			sdram_ctrl_wire_dqm        : out   std_logic_vector(1 downto 0);                     -- dqm
			sdram_ctrl_wire_ras_n      : out   std_logic;                                        -- ras_n
			sdram_ctrl_wire_we_n       : out   std_logic                                         -- we_n
		);
	end component systemFile;

	u0 : component systemFile
		port map (
			altpll_0_c2_clk            => CONNECTED_TO_altpll_0_c2_clk,            --     altpll_0_c2.clk
			clk_clk                    => CONNECTED_TO_clk_clk,                    --             clk.clk
			lcd_conduit_end_cs_n       => CONNECTED_TO_lcd_conduit_end_cs_n,       -- lcd_conduit_end.cs_n
			lcd_conduit_end_data       => CONNECTED_TO_lcd_conduit_end_data,       --                .data
			lcd_conduit_end_dc_n       => CONNECTED_TO_lcd_conduit_end_dc_n,       --                .dc_n
			lcd_conduit_end_im0        => CONNECTED_TO_lcd_conduit_end_im0,        --                .im0
			lcd_conduit_end_lcdreset_n => CONNECTED_TO_lcd_conduit_end_lcdreset_n, --                .lcdreset_n
			lcd_conduit_end_rd_n       => CONNECTED_TO_lcd_conduit_end_rd_n,       --                .rd_n
			lcd_conduit_end_wr_n       => CONNECTED_TO_lcd_conduit_end_wr_n,       --                .wr_n
			reset_reset_n              => CONNECTED_TO_reset_reset_n,              --           reset.reset_n
			sdram_ctrl_wire_addr       => CONNECTED_TO_sdram_ctrl_wire_addr,       -- sdram_ctrl_wire.addr
			sdram_ctrl_wire_ba         => CONNECTED_TO_sdram_ctrl_wire_ba,         --                .ba
			sdram_ctrl_wire_cas_n      => CONNECTED_TO_sdram_ctrl_wire_cas_n,      --                .cas_n
			sdram_ctrl_wire_cke        => CONNECTED_TO_sdram_ctrl_wire_cke,        --                .cke
			sdram_ctrl_wire_cs_n       => CONNECTED_TO_sdram_ctrl_wire_cs_n,       --                .cs_n
			sdram_ctrl_wire_dq         => CONNECTED_TO_sdram_ctrl_wire_dq,         --                .dq
			sdram_ctrl_wire_dqm        => CONNECTED_TO_sdram_ctrl_wire_dqm,        --                .dqm
			sdram_ctrl_wire_ras_n      => CONNECTED_TO_sdram_ctrl_wire_ras_n,      --                .ras_n
			sdram_ctrl_wire_we_n       => CONNECTED_TO_sdram_ctrl_wire_we_n        --                .we_n
		);

