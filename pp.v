/*`timescale 1ns / 1ps

module sha256_padder (
    input  wire        clk,
    input  wire        rst_n,

    // Input Interface (32-bit Word)
    input  wire        msg_valid,
    input  wire        msg_last,
    input  wire [1:0]  msg_last_bytes, // 0=4B, 1=1B, 2=2B, 3=3B
    input  wire [31:0] msg_data,

    // Output Interface (512-bit Block)
    output reg [511:0] block_out,
    output reg         block_valid
);

    // Internal State
    reg [7:0]  buffer [0:63];
    reg [5:0]  buf_ptr;
    reg [63:0] total_bits;
    
    // FSM State Encoding
    localparam S_IDLE      = 3'd0;
    localparam S_RECEIVE   = 3'd1;
    localparam S_PAD_80    = 3'd2; // Append 1-bit (0x80 byte)
    localparam S_PAD_ZEROS = 3'd3; // Fill 0s until pos 56
    localparam S_PAD_LEN   = 3'd4; // Append 64-bit length
    localparam S_OUTPUT    = 3'd5; // Drive output bus
    
    reg [2:0] state;
    reg [2:0] next_state_after_output; // Stores where to go after outputting a full block

    integer i;
    
    // Helper to calculate valid bits in the current word
    reg [5:0] bits_in_word;
    always @(*) begin
        if (msg_last) begin
            case (msg_last_bytes)
                2'd0: bits_in_word = 32;
                2'd1: bits_in_word = 8;
                2'd2: bits_in_word = 16;
                2'd3: bits_in_word = 24;
            endcase
        end else begin
            bits_in_word = 32;
        end
    end

    // Helper to calculate bytes to write
    reg [2:0] bytes_to_write;
    always @(*) begin
        if (msg_last && msg_last_bytes != 0) 
            bytes_to_write = {1'b0, msg_last_bytes};
        else 
            bytes_to_write = 3'd4;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            buf_ptr <= 0;
            total_bits <= 0;
            block_out <= 0;
            block_valid <= 0;
            next_state_after_output <= S_IDLE;
            for (i=0; i<64; i=i+1) buffer[i] <= 8'd0;
        end else begin
            // Default pulse
            block_valid <= 0;

            case (state)
                S_IDLE: begin
                    buf_ptr <= 0;
                    total_bits <= 0;
                    
                    // If valid data arrives in IDLE, start processing immediately
                    if (msg_valid) begin
                        // Write Data
                        buffer[0] <= msg_data[31:24];
                        if (bytes_to_write >= 2) buffer[1] <= msg_data[23:16];
                        if (bytes_to_write >= 3) buffer[2] <= msg_data[15:8];
                        if (bytes_to_write == 4) buffer[3] <= msg_data[7:0];

                        // Update Pointers
                        buf_ptr    <= bytes_to_write;
                        total_bits <= bits_in_word;

                        if (msg_last) begin
                            state <= S_PAD_80;
                        end else begin
                            state <= S_RECEIVE;
                        end
                    end
                end

                S_RECEIVE: begin
                    if (msg_valid) begin
                        // 1. Write Data to Buffer
                        // We use non-blocking assignments carefully here
                        if (buf_ptr <= 60) begin 
                           buffer[buf_ptr]   <= msg_data[31:24];
                           if (bytes_to_write >= 2) buffer[buf_ptr+1] <= msg_data[23:16];
                           if (bytes_to_write >= 3) buffer[buf_ptr+2] <= msg_data[15:8];
                           if (bytes_to_write == 4) buffer[buf_ptr+3] <= msg_data[7:0];
                        end

                        // 2. Update Total Length
                        total_bits <= total_bits + bits_in_word;

                        // 3. Update Pointer & Check Transitions
                        if (msg_last) begin
                            // This is the last word.
                            // Logic: Add bytes. Check if full.
                            // If full -> Output, then come back to PAD_80 in next block.
                            // If not full -> Go to PAD_80 immediately.
                            
                            if (buf_ptr + bytes_to_write == 64) begin
                                state <= S_OUTPUT;
                                next_state_after_output <= S_PAD_80; // Must pad in new block
                            end else begin
                                buf_ptr <= buf_ptr + bytes_to_write;
                                state <= S_PAD_80;
                            end
                        end else begin
                            // Not last word (always 4 bytes)
                            if (buf_ptr == 60) begin
                                // Filled exactly 64 bytes
                                state <= S_OUTPUT;
                                next_state_after_output <= S_RECEIVE; // Continue receiving
                            end else begin
                                buf_ptr <= buf_ptr + 4;
                            end
                        end
                    end
                end

                // Append the single '1' bit (Byte 0x80)
                S_PAD_80: begin
                    buffer[buf_ptr] <= 8'h80;
                    
                    if (buf_ptr == 63) begin
                        // Block is full just after padding byte
                        state <= S_OUTPUT;
                        next_state_after_output <= S_PAD_ZEROS;
                    end else begin
                        buf_ptr <= buf_ptr + 1;
                        state <= S_PAD_ZEROS;
                    end
                end

                // Fill with Zeros until byte 56
                S_PAD_ZEROS: begin
                    if (buf_ptr == 56) begin
                        state <= S_PAD_LEN;
                    end else if (buf_ptr > 56) begin
                        // Not enough space for length in this block
                        if (buf_ptr == 63) begin
                            buffer[63] <= 8'd0;
                            state <= S_OUTPUT;
                            next_state_after_output <= S_PAD_ZEROS; // Continue padding 0s in next block
                        end else begin
                            buffer[buf_ptr] <= 8'd0;
                            buf_ptr <= buf_ptr + 1;
                        end
                    end else begin
                        // Standard padding
                        buffer[buf_ptr] <= 8'd0;
                        buf_ptr <= buf_ptr + 1;
                    end
                end

                // Append 64-bit Length (Big Endian)
                S_PAD_LEN: begin
                    {buffer[56], buffer[57], buffer[58], buffer[59], 
                     buffer[60], buffer[61], buffer[62], buffer[63]} <= total_bits;
                    state <= S_OUTPUT;
                    next_state_after_output <= S_IDLE;
                end

                S_OUTPUT: begin
                    // Flatten buffer to output bus
                    block_out <= {
                        buffer[0], buffer[1], buffer[2], buffer[3], buffer[4], buffer[5], buffer[6], buffer[7],
                        buffer[8], buffer[9], buffer[10], buffer[11], buffer[12], buffer[13], buffer[14], buffer[15],
                        buffer[16], buffer[17], buffer[18], buffer[19], buffer[20], buffer[21], buffer[22], buffer[23],
                        buffer[24], buffer[25], buffer[26], buffer[27], buffer[28], buffer[29], buffer[30], buffer[31],
                        buffer[32], buffer[33], buffer[34], buffer[35], buffer[36], buffer[37], buffer[38], buffer[39],
                        buffer[40], buffer[41], buffer[42], buffer[43], buffer[44], buffer[45], buffer[46], buffer[47],
                        buffer[48], buffer[49], buffer[50], buffer[51], buffer[52], buffer[53], buffer[54], buffer[55],
                        buffer[56], buffer[57], buffer[58], buffer[59], buffer[60], buffer[61], buffer[62], buffer[63]
                    };
                    block_valid <= 1;
                    
                    // Reset buffer logic
                    buf_ptr <= 0;
                    // Note: We don't necessarily need to clear the buffer array as 
                    // subsequent states S_RECEIVE or S_PAD_ZEROS will overwrite it, 
                    // but it is good practice for security/debug.
                    for (i=0; i<64; i=i+1) buffer[i] <= 8'd0;
                    
                    state <= next_state_after_output;
                end
            endcase
        end
    end

endmodule*/

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


