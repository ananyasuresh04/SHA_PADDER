
`timescale 1ns/1ps

module padder_top (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        start,
    input  wire        msg_valid,
    input  wire        msg_last,
    input  wire [7:0]  msg_byte,

    output reg  [511:0] block_out,
    output reg          block_valid,
    output reg          final_block
);

    // FSM states
    localparam IDLE=0, DATA=1, PAD80=2, PAD0=3, LEN=4, DONE=5;
    reg [2:0] state;

    // Datapath
    reg [511:0] shreg;
    reg [6:0]   byte_cnt;
    reg [63:0]  bit_len;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            shreg       <= 0;
            byte_cnt    <= 0;
            bit_len     <= 0;
            block_out   <= 0;
            block_valid <= 0;
            final_block <= 0;
        end else begin
            block_valid <= 0;
            final_block <= 0;

            case (state)

            IDLE: begin
                shreg    <= 0;
                byte_cnt <= 0;
                bit_len  <= 0;
                if (start)
                    state <= DATA;
            end

            DATA: begin
                if (msg_valid) begin
                    shreg    <= {shreg[503:0], msg_byte};
                    byte_cnt <= byte_cnt + 1;
                    bit_len  <= bit_len + 8;
                    if (msg_last)
                        state <= PAD80;
                end
            end

            PAD80: begin
                shreg    <= {shreg[503:0], 8'h80};
                byte_cnt <= byte_cnt + 1;
                state    <= PAD0;
            end

            PAD0: begin
                if (byte_cnt < 56) begin
                    shreg    <= {shreg[503:0], 8'h00};
                    byte_cnt <= byte_cnt + 1;
                end else begin
                    state <= LEN;
                end
            end

            LEN: begin
                shreg <= {shreg[447:0], bit_len};
                state <= DONE;
            end

            DONE: begin
                block_out   <= shreg;
                block_valid <= 1'b1;
                final_block <= 1'b1;
                state       <= IDLE;
            end

            endcase
        end
    end
endmodule

