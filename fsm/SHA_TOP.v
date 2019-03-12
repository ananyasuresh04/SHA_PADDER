`timescale 1ns/1ps

module sha256_padder_top (
    input  wire        clk,
    input  wire        reset,
    input  wire        msg_valid,
    input  wire        msg_last,
    input  wire [31:0] msg_word,
    input  wire [1:0]  last_bytes,

    output reg  [511:0] block_out,
    output reg          block_valid,
    output reg          final_block
);

    reg [3:0]  word_cnt;
    reg [63:0] bit_len;
    reg [511:0] shreg;

    wire [1:0] mux_sel;
    wire shift_en, clear_block, fsm_block, fsm_final;

    reg [31:0] mux_out, pad80;

    always @(*) begin
        case (last_bytes)
            2'd1: pad80 = {msg_word[31:24],8'h80,16'h0};
            2'd2: pad80 = {msg_word[31:16],8'h80,8'h0};
            2'd3: pad80 = {msg_word[31:8],8'h80};
            default: pad80 = 32'h80000000;
        endcase

        case (mux_sel)
            2'b00: mux_out = msg_word;
            2'b01: mux_out = pad80;
            2'b10: mux_out = 32'h0;
            2'b11: mux_out = (word_cnt==4'd14) ? bit_len[63:32] : bit_len[31:0];
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset || clear_block) begin
            shreg <= 0;
            word_cnt <= 0;
            bit_len <= 0;
        end else begin
            if (shift_en) begin
                shreg <= {shreg[479:0], mux_out};
                word_cnt <= word_cnt + 1'b1;
            end
            if (msg_valid)
                bit_len <= bit_len + (msg_last ? (last_bytes<<3) : 32);
        end
    end

    // CAPTURE ONE CYCLE AFTER FSM ASSERTS
    always @(posedge clk) begin
        block_valid <= fsm_block;
        if (fsm_block) begin
            block_out <= shreg;
            final_block <= fsm_final;
        end
    end

    sha256_padder_fsm fsm (
        .clk(clk), .reset(reset),
        .msg_valid(msg_valid), .msg_last(msg_last),
        .word_cnt(word_cnt),
        .mux_sel(mux_sel), .shift_en(shift_en),
        .block_valid(fsm_block),
        .clear_block(clear_block),
        .final_block(fsm_final)
    );
endmodule
