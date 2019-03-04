`timescale 1ns/1ps

module sha256_padder_fsm (
    input  wire       clk,
    input  wire       reset,
    input  wire       msg_valid,
    input  wire       msg_last,
    input  wire [3:0] word_cnt,

    output reg  [1:0] mux_sel,       // 00=data, 01=pad80, 10=zero, 11=length
    output reg        shift_en,
    output reg        block_valid,
    output reg        clear_block,
    output reg        final_block
);

    localparam IDLE      = 3'd0,
               READ      = 3'd1,
               PAD80     = 3'd2,
               PAD_ZERO  = 3'd3,
               LEN_H     = 3'd4,
               LEN_L     = 3'd5,
               OUT_BLK   = 3'd6;

    reg [2:0] state, next;
    reg overflow;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            overflow <= 1'b0;
        end else begin
            state <= next;
            if (state == IDLE)
                overflow <= 1'b0;
            else if (state == PAD80 && word_cnt >= 4'd14)
                overflow <= 1'b1;
        end
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
                if (msg_valid)
                    next = READ;

            READ:
                if (msg_valid) begin
                    shift_en = 1'b1;
                    if (msg_last)
                        next = PAD80;
                end

            PAD80: begin
                mux_sel  = 2'b01;
                shift_en = 1'b1;
                next     = PAD_ZERO;
            end

            PAD_ZERO:
                if (overflow && word_cnt == 4'd15)
                    next = OUT_BLK;
                else if (!overflow && word_cnt == 4'd13)
                    next = LEN_H;
                else begin
                    mux_sel  = 2'b10;
                    shift_en = 1'b1;
                end

            LEN_H: begin
                mux_sel  = 2'b11;
                shift_en = 1'b1;
                next     = LEN_L;
            end

            LEN_L: begin
                mux_sel  = 2'b11;
                shift_en = 1'b1;
                final_block = 1'b1;
                next     = OUT_BLK;
            end

            OUT_BLK: begin
                block_valid = 1'b1;
                clear_block = 1'b1;
                if (overflow)
                    next = PAD_ZERO;
                else
                    next = IDLE;
            end
        endcase
    end
endmodule
