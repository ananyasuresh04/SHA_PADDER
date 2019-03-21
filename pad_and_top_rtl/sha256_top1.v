
`timescale 1ns/1ps
module sha256_top1(
        input              clk_in,
        input              rst_n_in,
        input              padder_start,
        input      [31:0]  msg_data,
        input              msg_valid,
        input              msg_last,
        input      [1:0]   msg_last_bytes,
        output     [255:0] digest_out,
        output             msg_stall,
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
        wire [511:0]    pad_out_512;
        wire            last_block;
        wire            sched_ready_out;
//        wire            fsm2comp_msg_init_in;
//
//        padder block
    wire [31:0]blk0_data_in, blk4_data_in, blk8_data_in, blk12_data_in;
    wire [31:0]blk1_data_in, blk5_data_in, blk9_data_in, blk13_data_in;
    wire [31:0]blk2_data_in, blk6_data_in, blk10_data_in, blk14_data_in;
    wire [31:0]blk3_data_in, blk7_data_in, blk11_data_in, blk15_data_in;

    sha256_padder padder(
                         .clk(clk_in),
                         .rst_n(rst_n_in),
                         .padder_start(padder_start),
                         .msg_valid(msg_valid),
                         .msg_data(msg_data),
                         .msg_last(msg_last),
                         .msg_last_bytes(msg_last_bytes),
                         .schedule_ready(sched_ready_out),
                         .msg_stall(msg_stall),
                         .block_valid(block_valid_in),
                         .final_block(last_block),
                         .blk0_out(blk0_data_in),
                         .blk1_out(blk1_data_in),
                         .blk2_out(blk2_data_in),
                         .blk3_out(blk3_data_in),
                         .blk4_out(blk4_data_in),
                         .blk5_out(blk5_data_in),
                         .blk6_out(blk6_data_in),
                         .blk7_out(blk7_data_in),
                         .blk8_out(blk8_data_in),
                         .blk9_out(blk9_data_in),
                         .blk10_out(blk10_data_in),
                         .blk11_out(blk11_data_in),
                         .blk12_out(blk12_data_in),
                         .blk13_out(blk13_data_in),
                         .blk14_out(blk14_data_in),
                         .blk15_out(blk15_data_in)
    );

//      msg_scheduler
/*    wire blk0_data_in, blk4_data_in, blk8_data_in, blk12_data_in;
    wire blk1_data_in, blk5_data_in, blk9_data_in, blk13_data_in;
    wire blk2_data_in, blk6_data_in, blk10_data_in, blk14_data_in;
    wire blk3_data_in, blk7_data_in, blk11_data_in, blk15_data_in;
    
    assign blk0_data_in = pad_out_512[511:480];
    assign blk1_data_in = pad_out_512[479:448];
    assign blk2_data_in = pad_out_512[447:416];
    assign blk3_data_in = pad_out_512[415:384];
    assign blk4_data_in = pad_out_512[383:352];
    assign blk5_data_in = pad_out_512[351:320];
    assign blk6_data_in = pad_out_512[319:288];
    assign blk7_data_in = pad_out_512[287:256];
    assign blk8_data_in = pad_out_512[255:224];
    assign blk9_data_in = pad_out_512[223:192];
    assign blk10_data_in = pad_out_512[191:160];
    assign blk11_data_in = pad_out_512[159:128];
    assign blk12_data_in = pad_out_512[127:96];
    assign blk13_data_in = pad_out_512[95:64];
    assign blk14_data_in = pad_out_512[63:32];
    assign blk15_data_in = pad_out_512[31:0];
    */

    sha256_msg_schedule_top msg_schedule  (
    .clk_in(clk_in),
    .rst_n_in(rst_n_in),
//  .block_data_in(block_data_in),

    .blk0_data_in(blk0_data_in),
    .blk1_data_in(blk1_data_in),
    .blk2_data_in(blk2_data_in),
    .blk3_data_in(blk3_data_in),
    .blk4_data_in(blk4_data_in),
    .blk5_data_in(blk5_data_in),
    .blk6_data_in(blk6_data_in),
    .blk7_data_in(blk7_data_in),
    .blk8_data_in(blk8_data_in),
    .blk9_data_in(blk9_data_in),
    .blk10_data_in(blk10_data_in),
    .blk11_data_in(blk11_data_in),
    .blk12_data_in(blk12_data_in),
    .blk13_data_in(blk13_data_in),
    .blk14_data_in(blk14_data_in),
    .blk15_data_in(blk15_data_in),

    .block_valid_in(block_valid_in),
    .msg_data_out(msg_sched2comp_data),
    .sched_ready_out(sched_ready_out),
    .msg_valid_out(msg_sched2fsm_valid)
  );
  
  //counter for constant address update
    sha256_k_count k_counter(
                            .clk_in(clk_in),
                            .rst_n_in(rst_n_in),
                            .en(msg_sched2fsm_valid),        // 1-bit control input

                            .k_addr_out(cnt_k_addr)
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
                                        .last_block(last_block),
                                        .msg_sched_valid(sched_ready_out),
                                       

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
