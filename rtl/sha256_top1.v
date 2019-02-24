
`timescale 1ns/1ps
module sha256_top1(
        input              clk_in,
        input              rst_n_in,
        input      [31:0] block_in,
        input              block_valid_in,
        input              last_block_in,
	input	[1:0] msg_last_bytes,
        output     [255:0] digest_out,
        //output            stall, // stall signal for padder
        output             digest_valid_out
        );

        // msg scheduler to compress signal
        wire [127:0]    msg_sched2comp_data;

        // msg scheduler to fsm signal
        wire            msg_sched2fsm_valid;

        // constant address selection signal from counter
        wire [3:0]      cnt_k_addr;

        // signals to connect fsm and the compressor
        wire            fsm2comp_h_load;
        wire            fsm2comp_h_buff_en;
        wire            fsm2comp_comp_done;
        wire            fsm2comp_comp_new_h;

        // hash to comp signal
        wire [255:0]    hash2comp_update_h_update;

        // comp to hash signals
        wire [255:0]    comp2hash_update_c_h0_to_h7;
        wire [255:0]    comp2hash_update_h0_to_h7;

        wire            fsm2hash_update_final_block;
        wire            fsm2hash_update_h_update_en;

        wire            last_block;
        wire            temp2;

//--------------------Padder-----------------------------
	wire [511:0]	pad_out;
	wire		pad_valid;

 

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    /*sha256_padder_fsm padder_fsm(
			.clk(clk_in),
			.rst_n(rst_n_in),
			.msg_valid(block_valid_in),
			.msg_last(last_block_in),
			.msg_last_bytes(msg_last_bytes),
			.msg_data(block_in),
      .msg_last_block(last_block),
      //.stall(stall),
			.o_block_512(pad_out),
			.o_block_valid(pad_valid)
			);*/
//-------------------------------------------------------

    sha256_msg_scheduler msg_sched(
                                    .clk_in(clk_in),
                                    .rst_n_in(rst_n_in),
                                    .block_valid_in(pad_valid),
                                    .last_blk(last_block),
                                    .block_in(pad_out),
/*                                    .out_word0_in,
                                    .out_word1_in,
                                    .out_word2_in,
                                    .out_word3_in,*/

                                    .out_words_out(msg_sched2comp_data),
                                    .temp2(temp2),
                                    .out_valid_out(msg_sched2fsm_valid)
                        );

    //counter for constant address update
    counter_4bit k_counter(
                            .clk(clk_in),
                            .rst_n(rst_n_in),
                            .en(msg_sched2fsm_valid),        // 1-bit control input

                            .count(cnt_k_addr)
                );


    sha256_f4_compress compress(
                                 .clk_in(clk_in),
                                 .rst_n_in(rst_n_in),
                                 .msg_words_in(msg_sched2comp_data),
                                 .k_rd_addr_in(cnt_k_addr),
                                 .h_load_in(fsm2comp_h_load),
                                 .comp_new_h_in(fsm2comp_comp_new_h),
                                 .h_buff_en_in(fsm2comp_h_buff_en),              
                                 .comp_done_in(fsm2comp_comp_done),
                                 .h_update_in(hash2comp_update_h_update),
                                 .msg_init_in(fsm2hash_update_final_block),

                                 .c_h0_to_h7_out(comp2hash_update_c_h0_to_h7),
                                 .h0_to_h7_out(comp2hash_update_h0_to_h7)
                    );

    sha256_comp_fsm_top comp_fsm_top(
                                        .clk(clk_in),
                                        .counter_rst(rst_n_in),
                                        .fsm_rst(rst_n_in),
                                        .count_en(msg_sched2fsm_valid),
                                        .last_block(temp2),

                                        .H_buff_en(fsm2comp_h_buff_en),
                                        .comp_new_h(fsm2comp_comp_new_h),
                                        .H_load_in(fsm2comp_h_load),
                                        .comp_done(fsm2comp_comp_done),
                                        .final_block(fsm2hash_update_final_block),
                                        .H_update_en(fsm2hash_update_h_update_en)
                                    );


    sha256_hash_update hash_update(
                                    .c_h0_to_h7_in(comp2hash_update_c_h0_to_h7),
                                    .h0_to_h7_in(comp2hash_update_h0_to_h7),
                                    .final_blk_in(fsm2hash_update_final_block),
                                    .h_update_en_in(fsm2hash_update_h_update_en),

                                    .digest_out(digest_out),
                                    .h_update_out(hash2comp_update_h_update),
                                    .digest_valid_out(digest_valid_out)
                                );

endmodule
