	component systemFile is
		port (
			altpll_0_c2_clk               : out   std_logic;                                        -- clk
			clk_clk                       : in    std_logic                     := 'X';             -- clk
			reset_reset_n                 : in    std_logic                     := 'X';             -- reset_n
			sdram_ctrl_wire_addr          : out   std_logic_vector(11 downto 0);                    -- addr
			sdram_ctrl_wire_ba            : out   std_logic_vector(1 downto 0);                     -- ba
			sdram_ctrl_wire_cas_n         : out   std_logic;                                        -- cas_n
			sdram_ctrl_wire_cke           : out   std_logic;                                        -- cke
			sdram_ctrl_wire_cs_n          : out   std_logic;                                        -- cs_n
			sdram_ctrl_wire_dq            : inout std_logic_vector(15 downto 0) := (others => 'X'); -- dq
			sdram_ctrl_wire_dqm           : out   std_logic_vector(1 downto 0);                     -- dqm
			sdram_ctrl_wire_ras_n         : out   std_logic;                                        -- ras_n
			sdram_ctrl_wire_we_n          : out   std_logic;                                        -- we_n
			mypio_leds_conduit_end_export : inout std_logic_vector(7 downto 0)  := (others => 'X')  -- export
		);
	end component systemFile;

	u0 : component systemFile
		port map (
			altpll_0_c2_clk               => CONNECTED_TO_altpll_0_c2_clk,               --            altpll_0_c2.clk
			clk_clk                       => CONNECTED_TO_clk_clk,                       --                    clk.clk
			reset_reset_n                 => CONNECTED_TO_reset_reset_n,                 --                  reset.reset_n
			sdram_ctrl_wire_addr          => CONNECTED_TO_sdram_ctrl_wire_addr,          --        sdram_ctrl_wire.addr
			sdram_ctrl_wire_ba            => CONNECTED_TO_sdram_ctrl_wire_ba,            --                       .ba
			sdram_ctrl_wire_cas_n         => CONNECTED_TO_sdram_ctrl_wire_cas_n,         --                       .cas_n
			sdram_ctrl_wire_cke           => CONNECTED_TO_sdram_ctrl_wire_cke,           --                       .cke
			sdram_ctrl_wire_cs_n          => CONNECTED_TO_sdram_ctrl_wire_cs_n,          --                       .cs_n
			sdram_ctrl_wire_dq            => CONNECTED_TO_sdram_ctrl_wire_dq,            --                       .dq
			sdram_ctrl_wire_dqm           => CONNECTED_TO_sdram_ctrl_wire_dqm,           --                       .dqm
			sdram_ctrl_wire_ras_n         => CONNECTED_TO_sdram_ctrl_wire_ras_n,         --                       .ras_n
			sdram_ctrl_wire_we_n          => CONNECTED_TO_sdram_ctrl_wire_we_n,          --                       .we_n
			mypio_leds_conduit_end_export => CONNECTED_TO_mypio_leds_conduit_end_export  -- mypio_leds_conduit_end.export
		);

