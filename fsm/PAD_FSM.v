
`timescale 1ns/1ps

module padder_fsm (
    input  wire clk,
    input  wire rst_n,
    input  wire padder_start,
    input  wire msg_valid,
    input  wire msg_last,

    output reg  [1:0] mux_sel,      // 00=data, 01=pad80, 10=zero, 11=length
    output reg        shift_en,
    output reg        byte_cnt_en,
    output reg        block_valid,
    output reg        final_block
);

    localparam IDLE=0, READ=1, PAD80=2, PAD0=3, LEN_HI=4, LEN_LO=5, OUT=6;
    reg [2:0] state, next;

    always @(posedge clk or negedge rst_n)
        if (!rst_n) state <= IDLE;
        else        state <= next;

    always @(*) begin
        mux_sel=0; shift_en=0; byte_cnt_en=0;
        block_valid=0; final_block=0; next=state;

        case (state)

        IDLE:
            if (padder_start) next=READ;

        READ:
            if (msg_valid) begin
                mux_sel=2'b00;
                shift_en=1;
                byte_cnt_en=1;
                if (msg_last) next=PAD80;
            end

        PAD80: begin
            mux_sel=2'b01;
            shift_en=1;
            next=PAD0;
        end

        PAD0: begin
            mux_sel=2'b10;
            shift_en=1;
            next=LEN_HI;
        end

        LEN_HI: begin
            mux_sel=2'b11;
            shift_en=1;
            next=LEN_LO;
        end

        LEN_LO: begin
            mux_sel=2'b11;
            shift_en=1;
            final_block=1;
            next=OUT;
        end

        OUT: begin
            block_valid=1;
            next=IDLE;
        end

        endcase
    end
endmodule

