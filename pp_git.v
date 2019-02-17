`timescale 1ns / 1ps

module sha256_padder (
    input  wire        clk,
    input  wire        rst_n,

    // Input Interface
    input  wire        msg_valid,
    input  wire        msg_last,
    input  wire [1:0]  msg_last_bytes, // 0=4B, 1=1B, 2=2B, 3=3B
    input  wire [31:0] msg_data,
    output reg         o_ready,

    // Output Interface (Word Stream)
    output reg [31:0]  o_word,       
    output reg         o_word_valid, 
    output reg         o_last_word   
);

    reg [31:0] block [0:15];
    reg [63:0] total_len; 
    reg [3:0]  ptr;       
    reg [4:0]  out_cnt;   
    
    reg spillover;   
    reg pad_pushed;      

    localparam S_IDLE       = 3'd0;
    localparam S_RECEIVE    = 3'd1;
    localparam S_STREAM     = 3'd2;
    localparam S_EXTRA      = 3'd3;

    reg [2:0] state;
    integer i;

    // Word padding logic: Correctly places 0x80 based on valid bytes
    reg [31:0] word_with_pad;
    always @(*) begin
        case (msg_last_bytes)
            2'd1:    word_with_pad = (msg_data & 32'hFF000000) | 32'h00800000;
            2'd2:    word_with_pad = (msg_data & 32'hFFFF0000) | 32'h00008000;
            2'd3:    word_with_pad = (msg_data & 32'hFFFFFF00) | 32'h00000080;
            default: word_with_pad = 32'h80000000; // Case for 4-byte valid word
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            o_ready <= 0; o_word <= 0; o_word_valid <= 0; o_last_word <= 0;
            ptr <= 0; total_len <= 0; out_cnt <= 0;
            spillover <= 0; pad_pushed <= 0;
            for (i=0; i<16; i=i+1) block[i] <= 32'd0;
        end else begin
            o_word_valid <= 0; o_last_word  <= 0;

            case (state)
                S_IDLE: begin
                    o_ready <= 1;
                    ptr <= 0; total_len <= 0; spillover <= 0; pad_pushed <= 0;
                    if (msg_valid) begin
                        block[0] <= (msg_last && msg_last_bytes != 0) ? word_with_pad : msg_data;
                        total_len <= (msg_last) ? (msg_last_bytes == 0 ? 32 : (msg_last_bytes << 3)) : 32;
                        if (msg_last) begin
                            o_ready <= 0;
                            if (msg_last_bytes == 0) begin
                                block[1] <= 32'h80000000;
                                for (i=2; i<14; i=i+1) block[i] <= 0;
                            end else begin
                                for (i=1; i<14; i=i+1) block[i] <= 0;
                            end
                            block[14] <= 0;
                            block[15] <= (msg_last_bytes == 0) ? 32 : (msg_last_bytes << 3);
                            state <= S_STREAM;
                        end else begin
                            ptr <= 1;
                            state <= S_RECEIVE;
                        end
                    end
                end

                S_RECEIVE: begin
                    o_ready <= 1;
                    if (msg_valid) begin
                        total_len <= total_len + (msg_last ? (msg_last_bytes == 0 ? 32 : (msg_last_bytes << 3)) : 32);
                        if (msg_last) begin
                            o_ready <= 0;
                            if (msg_last_bytes == 0) begin
                                block[ptr] <= msg_data;
                                if (ptr >= 13) begin
                                    spillover <= 1;
                                    if (ptr < 15) block[ptr+1] <= 32'h80000000;
                                    else pad_pushed <= 1;
                                    for (i=0; i<16; i=i+1) if (i > ptr+1) block[i] <= 0;
                                end else begin
                                    block[ptr+1] <= 32'h80000000;
                                    for (i=ptr+2; i<14; i=i+1) block[i] <= 0;
                                    block[14] <= 0; 
                                    block[15] <= total_len + (msg_last_bytes == 0 ? 32 : (msg_last_bytes << 3));
                                end
                            end else begin
                                block[ptr] <= word_with_pad;
                                if (ptr >= 14) begin
                                    spillover <= 1;
                                    for (i=ptr+1; i<16; i=i+1) block[i] <= 0;
                                end else begin
                                    for (i=ptr+1; i<14; i=i+1) block[i] <= 0;
                                    block[14] <= 0;
                                    block[15] <= total_len + (msg_last_bytes << 3);
                                end
                            end
                            state <= S_STREAM;
                        end else begin
                            block[ptr] <= msg_data;
                            if (ptr == 15) begin o_ready <= 0; state <= S_STREAM; end
                            else ptr <= ptr + 1;
                        end
                    end
                end

                S_STREAM: begin
                    o_word_valid <= 1;
                    o_word <= block[out_cnt];
                    if (out_cnt == 15) begin
                        o_last_word <= 1; out_cnt <= 0;
                        state <= spillover ? S_EXTRA : S_IDLE;
                    end else out_cnt <= out_cnt + 1;
                end

                S_EXTRA: begin
                    spillover <= 0;
                    if (pad_pushed) begin 
                        block[0] <= 32'h80000000; 
                        for (i=1; i<14; i=i+1) block[i] <= 0; 
                    end else begin 
                        for (i=0; i<14; i=i+1) block[i] <= 0; 
                    end
                    block[14] <= total_len >> 32;
                    block[15] <= total_len[31:0];
                    pad_pushed <= 0;
                    state <= S_STREAM;
                end
            endcase
        end
    end
endmodule

