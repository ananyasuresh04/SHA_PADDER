`timescale 1ns / 1ps

module sha256_padder (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        msg_valid,
    input  wire        msg_last,
    input  wire [1:0]  msg_last_bytes, 
    input  wire [31:0] msg_data,
    
    output reg [511:0] o_block_512,
    output reg         o_block_valid
);

    reg [31:0] block [0:15];
    reg [63:0] total_len; 
    reg [3:0]  ptr;       
    reg [4:0]  out_cnt;   
    
    reg spillover;   
    reg pad_pushed; 
    reg msg_done_latched; // New flag to track if we saw msg_last

    localparam S_IDLE       = 3'd0;
    localparam S_RECEIVE    = 3'd1;
    localparam S_STREAM     = 3'd2;
    localparam S_EXTRA      = 3'd3;

    reg [2:0] state;
    integer i;

    // Word padding logic
    reg [31:0] word_with_pad;
    always @(*) begin
        case (msg_last_bytes)
           2'd1: word_with_pad = {msg_data[31:24], 8'h80, 16'h0000};// 2'd1:    word_with_pad = (msg_data & 32'hFF000000) | 32'h00800000;
           2'd2: word_with_pad = {msg_data[31:16], 8'h80, 8'h00};// 2'd2:    word_with_pad = (msg_data & 32'hFFFF0000) | 32'h00008000;
           2'd3: word_with_pad = {msg_data[31:8],  8'h80}; // 2'd3:    word_with_pad = (msg_data & 32'hFFFFFF00) | 32'h00000080;
            default: word_with_pad = 32'h80000000; 
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            ptr <= 0;
            total_len <= 0; 
            out_cnt <= 0;
            spillover <= 0; 
            pad_pushed <= 0; 
            msg_done_latched <= 0;
            o_block_512 <= 0; 
            o_block_valid <= 0;
            
            for (i=0; i<16; i=i+1) block[i] <= 32'd0;
        end
    else 
    begin
            o_block_valid <= 0;

            case (state)
                S_IDLE: begin
           
                    ptr <= 0; 
                    total_len <= 0; // Only reset length here (Start of new msg)
                    spillover <= 0; 
                    pad_pushed <= 0;
                    msg_done_latched <= 0;
                    
                    if (msg_valid) begin
                        block[0] <= (msg_last && msg_last_bytes != 0) ? word_with_pad : msg_data;
                        total_len <= (msg_last) ? (msg_last_bytes == 0 ? 32 : (msg_last_bytes << 3)) : 32;
                        
                        if (msg_last)
                        begin
                            msg_done_latched <= 1; // Mark done
                            if (msg_last_bytes == 0) 
                            begin
                                block[1] <= 32'h80000000;
                                for (i=2; i<14; i=i+1) block[i] <= 0;
                            end
                        else 
                        begin
                                for (i=1; i<14; i=i+1) block[i] <= 0;
                            end
                            block[14] <= 0;
                            block[15] <= (msg_last_bytes == 0) ? 32 : (msg_last_bytes << 3);
                            state <= S_STREAM;
                        end
                        else 
                        begin
                            ptr <= 1;
                            state <= S_RECEIVE;
                        end
                    end
                end

                S_RECEIVE: begin
                    if (msg_valid) begin
                        total_len <= total_len + (msg_last ? (msg_last_bytes == 0 ? 32 : (msg_last_bytes << 3)) : 32);
                        
                        if (msg_last) begin
                            msg_done_latched <= 1; // Mark done
                            if (msg_last_bytes == 0) begin
                                block[ptr] <= msg_data;
                                // Spillover check
                                if (ptr >= 13) begin
                                    spillover <= 1;
                                    if (ptr < 15) block[ptr+1] <= 32'h80000000;
                                    else pad_pushed <= 1;
                                    for (i=0; i<16; i=i+1) if (i > ptr+1) block[i] <= 0;
                                end 
                            else 
                            begin
                                    block[ptr+1] <= 32'h80000000;
                                    for (i=ptr+2; i<14; i=i+1) block[i] <= 0;
                                    block[14] <= 0; 
                                    block[15] <= total_len + (msg_last_bytes == 0 ? 32 : (msg_last_bytes << 3));
                                end
                            end
                            else 
                            begin
                                block[ptr] <= word_with_pad;
                                if (ptr >= 14) begin
                                    spillover <= 1;
                                    for (i=ptr+1; i<16; i=i+1) block[i] <= 0;
                                end
                            else
                            begin
                                    for (i=ptr+1; i<14; i=i+1) block[i] <= 0;
                                    block[14] <= 0;
                                    block[15] <= total_len + (msg_last_bytes << 3);
                                end
                            end
                            state <= S_STREAM;
                        end
                        else 
                        begin
                            block[ptr] <= msg_data;
                            if (ptr == 15) begin 
                                state <= S_STREAM; 
                            end
                            else ptr <= ptr + 1;
                        end
                    end
                end

              /*  S_STREAM: begin
                   // if (out_cnt == 0) begin
                        o_block_valid <= 1;
                        o_block_512   <= {block[0],  block[1],  block[2],  block[3], 
                                          block[4],  block[5],  block[6],  block[7], 
                                          block[8],  block[9],  block[10], block[11], 
                                          block[12], block[13], block[14], block[15]};
                    end

                   if (out_cnt == 15) begin
                        out_cnt <= 0;
                        if (spillover) begin
                            state <= S_EXTRA;
                        end else if (msg_done_latched) begin
                            state <= S_IDLE; // Finished message, reset
                        end else begin
                            // Not finished, go back to receive next block
                            ptr <= 0; 
                            state <= S_RECEIVE; 
                        end
                    end 
                    else out_cnt <= out_cnt + 1;
                end*/
                 
               
               S_STREAM: begin
                    // 1. Output Immediately
                    o_block_valid <= 1;
                    o_block_512   <= {block[0], block[1], block[2], block[3], 
                                      block[4], block[5], block[6], block[7], 
                                      block[8], block[9], block[10], block[11], 
                                      block[12], block[13], block[14], block[15]};

                    // 2. Transition Immediately (Don't wait 16 cycles)
                    out_cnt <= 0; 
                    
                    if (spillover) begin
                        state <= S_EXTRA;
                    end else if (msg_done_latched) begin
                        state <= S_IDLE; 
                    end else begin
                        ptr <= 0; 
                        state <= S_RECEIVE; 
                    end
                end
              
                S_EXTRA: begin
                    spillover <= 0;
                    if (pad_pushed) begin 
                        block[0] <= 32'h80000000; 
                        for (i=1; i<14; i=i+1) block[i] <= 0; 
                    end 
                else begin 
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
