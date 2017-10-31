
module systemFile (
	altpll_0_c2_clk,
	altpll_1_c0_clk,
	clk_clk,
	lcd_conduit_end_cs_n,
	lcd_conduit_end_data,
	lcd_conduit_end_data_cmd_n,
	lcd_conduit_end_mode,
	lcd_conduit_end_rd_n,
	lcd_conduit_end_wr_n,
	lcd_conduit_end_lcdreset_n,
	reset_reset_n,
	sdram_ctrl_wire_addr,
	sdram_ctrl_wire_ba,
	sdram_ctrl_wire_cas_n,
	sdram_ctrl_wire_cke,
	sdram_ctrl_wire_cs_n,
	sdram_ctrl_wire_dq,
	sdram_ctrl_wire_dqm,
	sdram_ctrl_wire_ras_n,
	sdram_ctrl_wire_we_n);	

	output		altpll_0_c2_clk;
	output		altpll_1_c0_clk;
	input		clk_clk;
	output		lcd_conduit_end_cs_n;
	inout	[15:0]	lcd_conduit_end_data;
	output		lcd_conduit_end_data_cmd_n;
	output		lcd_conduit_end_mode;
	output		lcd_conduit_end_rd_n;
	output		lcd_conduit_end_wr_n;
	output		lcd_conduit_end_lcdreset_n;
	input		reset_reset_n;
	output	[11:0]	sdram_ctrl_wire_addr;
	output	[1:0]	sdram_ctrl_wire_ba;
	output		sdram_ctrl_wire_cas_n;
	output		sdram_ctrl_wire_cke;
	output		sdram_ctrl_wire_cs_n;
	inout	[15:0]	sdram_ctrl_wire_dq;
	output	[1:0]	sdram_ctrl_wire_dqm;
	output		sdram_ctrl_wire_ras_n;
	output		sdram_ctrl_wire_we_n;
endmodule
