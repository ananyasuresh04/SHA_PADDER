`timescale 1ns/1ps

module sha256_padder (

    input  wire        clk,
    input  wire        rst_n,

    input  wire        msg_valid,
    input  wire        msg_last,
    input  wire [1:0]  msg_last_bytes,
    input  wire [31:0] msg_data,

    output reg  [511:0] block_out,
    output reg          block_valid
);

    integer i;

    reg [31:0] block [0:15];
    reg [4:0]  wc;               // word counter 0-15
    reg [63:0] total_bytes;      // message length in bytes
    reg [63:0] bit_len;          // message length in bits
    reg        overflow;         // need extra block

    localparam IDLE = 3'd0,
               PAD  = 3'd1,
               LEN  = 3'd2,
               OUT1 = 3'd3,
               OUT2 = 3'd4;

    reg [2:0] state;

    /* ================= RESET ================= */
    always @(negedge rst_n) begin
        wc <= 0;
        total_bytes <= 0;
        bit_len <= 0;
        overflow <= 0;
        block_valid <= 0;
        state <= IDLE;
        for (i=0;i<16;i=i+1)
            block[i] <= 32'd0;
    end

    /* ================= FSM ================= */
    always @(posedge clk) begin

        block_valid <= 1'b0;

        case (state)

        /* ---------- DATA ---------- */
        IDLE: begin

            if (msg_valid) begin

                // store word first
                block[wc] <= msg_data;

                // count bytes
                total_bytes <= total_bytes + (msg_last ? msg_last_bytes + 1 : 4);
                
                if (msg_last) begin
                    // HANDLE LAST-WORD BASED ON BYTE COUNT
                    case (msg_last_bytes)
                        2'd0: begin
                            // full 4 bytes valid → padding in NEXT word
                            wc <= wc + 1;
                            block[wc+1] <= 32'h80000000;
                        end

                        2'd1: begin
                            // only 1 byte valid
                            block[wc] <= {msg_data[31:24],8'h80,16'h0};
                            wc <= wc + 1;
                        end

                        2'd2: begin
                            block[wc] <= {msg_data[31:16],8'h80,8'h0};
                            wc <= wc + 1;
                        end

                        2'd3: begin
                            block[wc] <= {msg_data[31:8],8'h80};
                            wc <= wc + 1;
                        end
                    endcase

                    // overflow check
                    overflow <= ((msg_last_bytes==0) ? (wc+1 >= 14) : (wc >= 14));

                    state <= PAD;
                end

                // block full on normal streaming
                else if (wc == 15) begin
                    wc <= 0;
                    state <= OUT1;
                end
                else begin
                    wc <= wc + 1;
                end
            end
        end

        /* ---------- PAD ---------- */
        PAD: begin

            if (wc < 14) begin
                block[wc] <= 32'd0;
                wc <= wc + 1;
            end
            else begin
                state <= LEN;
            end
        end

        /* ---------- LENGTH ---------- */
        LEN: begin
            bit_len <= total_bytes << 3;
            block[14] <= bit_len[63:32];
            block[15] <= bit_len[31:0];
            state <= OUT1;
        end

        /* ---------- OUTPUT BLOCK 1 ---------- */
        OUT1: begin
            for (i=0;i<16;i=i+1)
                block_out[511 - i*32 -: 32] <= block[i];

            block_valid <= 1'b1;

            for (i=0;i<16;i=i+1)
                block[i] <= 32'd0;

            wc <= 0;

            if (overflow) begin
                block[14] <= bit_len[63:32];
                block[15] <= bit_len[31:0];
                state <= OUT2;
            end
            else begin
                total_bytes <= 0;
                overflow <= 0;
                state <= IDLE;
            end
        end

        /* ---------- OUTPUT BLOCK 2 ---------- */
        OUT2: begin
            for (i=0;i<16;i=i+1)
                block_out[511 - i*32 -: 32] <= block[i];

            block_valid <= 1'b1;

            total_bytes <= 0;
            overflow <= 0;

            state <= IDLE;
        end

        endcase
    end

endmodule
