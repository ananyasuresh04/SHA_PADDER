module padder_top (
    input         clk,
    input         rst,
    input  [31:0] msg_in,
    input         msg_start,
    input         msg_valid,
    input         msg_end,
    input  [2:0]  valid_bytes,

    output        padder_block_valid,
    output [511:0] block_out
);

    //----------------------------------------------------------
    // INTERNAL WIRES
    //----------------------------------------------------------
    wire [4:0] word_count;
    wire       block_full;
    wire [4:0] space_left;

    wire [63:0] bit_length;
    wire        length_ready;
    wire [63:0] byte_count;

    wire        shift_en;
    wire        mux_sel_delim;
    wire        mux_sel_zero;
    wire        mux_sel_len_hi;
    wire        mux_sel_len_lo;
    wire        pipo_load;

    wire [2:0]  mux_sel;

    wire [31:0] mux_out;
    wire [511:0] sipo_out;
    wire [511:0] block_out_int;

    //----------------------------------------------------------
    // MUX SELECT ENCODING
    //----------------------------------------------------------
    assign mux_sel = mux_sel_delim  ? 3'b001 :
                     mux_sel_zero   ? 3'b010 :
                     mux_sel_len_hi ? 3'b011 :
                     mux_sel_len_lo ? 3'b100 :
                     3'b000;     // normal data

    //----------------------------------------------------------
    // BYTE COUNTER
    //----------------------------------------------------------
    byte_counter u_byte_cnt (
        .clk(clk),
        .rst(rst),
        .msg_start(msg_start),
        .msg_valid(msg_valid),
        .valid_bytes(valid_bytes),
        .msg_end(msg_end),
        .word_en(shift_en),

        .byte_count(byte_count),
        .bit_length(bit_length),
        .length_ready(length_ready)
    );

    //----------------------------------------------------------
    // WORD COUNTER
    //----------------------------------------------------------
    word_counter u_word_cnt (
        .clk(clk),
        .rst(rst),
        .msg_start(msg_start),
        .word_en(shift_en),
        .msg_stall(1'b0),       // NO STALL LOGIC
        .word_count(word_count),
        .block_full(block_full),
        .space_left(space_left)
    );

    //----------------------------------------------------------
    // FSM
    //----------------------------------------------------------
    padder_fsm u_fsm (
        .clk(clk),
        .rst(rst),
        .msg_valid(msg_valid),
        .msg_start(msg_start),
        .msg_end(msg_end),
        .word_count(word_count),
        .block_full(block_full),
       .overflow_required(1'b0),   // you are not using it now

        .shift_en(shift_en),
        .mux_sel(mux_sel),
        .pipo_load(pipo_load),
        .state()
    );

    //----------------------------------------------------------
    // MUX
    //----------------------------------------------------------
    padder_mux u_mux (
        .msg_in(msg_in),
        .bit_length(bit_length),
        .mux_sel(mux_sel),
        .mux_out(mux_out)
    );

    //----------------------------------------------------------
    // SIPO SHIFT REGISTER
    //----------------------------------------------------------
    sipo_512 u_sipo (
        .clk(clk),
        .rst(rst),
        .shift_en(shift_en),
        .mux_out(mux_out),
        .block_out(sipo_out)
    );

    //----------------------------------------------------------
    // PIPO OUTPUT BLOCK
    //----------------------------------------------------------
    pipo_word_buffer u_pipo (
        .clk(clk),
        .rst(rst),
        .pipo_load(pipo_load),
        .block_in(sipo_out),

        .w0(block_out_int[511:480]),
        .w1(block_out_int[479:448]),
        .w2(block_out_int[447:416]),
        .w3(block_out_int[415:384]),
        .w4(block_out_int[383:352]),
        .w5(block_out_int[351:320]),
        .w6(block_out_int[319:288]),
        .w7(block_out_int[287:256]),
        .w8(block_out_int[255:224]),
        .w9(block_out_int[223:192]),
        .w10(block_out_int[191:160]),
        .w11(block_out_int[159:128]),
        .w12(block_out_int[127:96]),
        .w13(block_out_int[95:64]),
        .w14(block_out_int[63:32]),
        .w15(block_out_int[31:0])
    );

    assign block_out = block_out_int;
    assign padder_block_valid = pipo_load;

endmodule
