module sha256_comp_fsm_top(
    input  wire         clk,
    input  wire         counter_rst,
    input  wire         fsm_rst,
    input  wire         count_en,
    input  wire         last_block,

    output wire         H_buff_en,
    output wire         comp_new_h,
    output wire         H_load_in,
    output wire         comp_done,
    output wire         final_block,
    output wire         H_update_en
);

wire [4:0]count;

counter_4bit counter(
	.clk(clk),
	.rst_n(counter_rst),
	.en(count_en),
	.count(count)
);

sha256_compress_fsm fsm(
	.clk(clk),
	.rst_n(fsm_rst),
	.count(count),
	.last_block(last_block),
	.H_buff_en(H_buff_en),
	.comp_new_h(comp_new_h),
	.H_load_in(H_load_in),
	.comp_done(comp_done),
	.final_block(final_block),
	.H_update_en(H_update_en)
);

endmodule
