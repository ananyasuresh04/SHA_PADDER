`timescale 1ns/1ps

module sha256_padder_fsm (
    input  wire       clk,
    input  wire       reset,
    input  wire       msg_valid,
    input  wire       msg_last,
    input  wire [3:0] word_cnt,

    output reg  [1:0] mux_sel,     // 00=data, 01=0x80, 10=zero, 11=length
    output reg        shift_en,
    output reg        block_valid,
    output reg        clear_block,
    output reg        final_block
);

    localparam IDLE      = 4'd0,
               READ      = 4'd1,
               PAD80     = 4'd2,
               PAD_ZERO0 = 4'd3,
               OUT_BLK0  = 4'd4,
               PAD_ZERO1 = 4'd5,
               LEN_H     = 4'd6,
               LEN_L     = 4'd7,
               OUT_BLK1  = 4'd8;

    reg [3:0] state, next;
    reg overflow;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            overflow <= 1'b0;
        end else begin
            state <= next;
        end
    end

    // Detect overflow ONCE
    always @(posedge clk) begin
        if (state == PAD80 && word_cnt >= 4'd14)
            overflow <= 1'b1;
        else if (state == IDLE)
            overflow <= 1'b0;
    end

    always @(*) begin
        mux_sel     = 2'b00;
        shift_en    = 1'b0;
        block_valid = 1'b0;
        clear_block = 1'b0;
        final_block = 1'b0;
        next        = state;

        case (state)

            IDLE:
                if (msg_valid) next = READ;

            READ:
                if (msg_valid) begin
                    shift_en = 1;
                    if (msg_last) next = PAD80;
                end

            PAD80:
                begin
                    mux_sel  = 2'b01;
                    shift_en = 1;
                    next     = PAD_ZERO0;
                end

            // ---------- BLOCK 0 ----------
            PAD_ZERO0:
                if (overflow && word_cnt == 4'd15)
                    next = OUT_BLK0;
                else if (!overflow && word_cnt == 4'd13)
                    next = LEN_H;
                else begin
                    mux_sel  = 2'b10;
                    shift_en = 1;
                end

            OUT_BLK0:
                begin
                    block_valid = 1;
                    clear_block = 1;
                    if (overflow)
                        next = PAD_ZERO1;
                    else begin
                        final_block = 1;
                        next = IDLE;
                    end
                end

            // ---------- BLOCK 1 ----------
            PAD_ZERO1:
                if (word_cnt == 4'd14)
                    next = LEN_H;
                else begin
                    mux_sel  = 2'b10;
                    shift_en = 1;
                end

            LEN_H:
                begin
                    mux_sel  = 2'b11;
                    shift_en = 1;
                    next     = LEN_L;
                end

            LEN_L:
                begin
                    mux_sel  = 2'b11;
                    shift_en = 1;
                    next     = OUT_BLK1;
                end

            OUT_BLK1:
                begin
                    block_valid = 1;
                    final_block = 1;
                    clear_block = 1;
                    next = IDLE;
                end
        endcase
    end
    endmodule
