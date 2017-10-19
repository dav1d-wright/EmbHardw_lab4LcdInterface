
module systemFile (
	altpll_0_c2_clk,
	clk_clk,
	reset_reset_n,
	sdram_ctrl_wire_addr,
	sdram_ctrl_wire_ba,
	sdram_ctrl_wire_cas_n,
	sdram_ctrl_wire_cke,
	sdram_ctrl_wire_cs_n,
	sdram_ctrl_wire_dq,
	sdram_ctrl_wire_dqm,
	sdram_ctrl_wire_ras_n,
	sdram_ctrl_wire_we_n,
	lcd_conduit_end_chipselect,
	lcd_conduit_end_lcdreset,
	lcd_conduit_end_lcddata,
	lcd_conduit_end_read,
	lcd_conduit_end_write,
	lcd_conduit_end_data_cmd_select,
	lcd_conduit_end_im0);	

	output		altpll_0_c2_clk;
	input		clk_clk;
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
	output		lcd_conduit_end_chipselect;
	output		lcd_conduit_end_lcdreset;
	inout	[15:0]	lcd_conduit_end_lcddata;
	output		lcd_conduit_end_read;
	output		lcd_conduit_end_write;
	output		lcd_conduit_end_data_cmd_select;
	output		lcd_conduit_end_im0;
endmodule
