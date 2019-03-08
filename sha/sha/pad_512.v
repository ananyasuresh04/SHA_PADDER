`timescale 1ns/1ps
module sha256_padder #(
    parameter SHA_WORD_WIDTH  = 32,
//              SHA_BLOCK_WIDTH = 512,
              SHA_MSG_LENGTH  = SHA_WORD_WIDTH*2,
              SHA_LAST_BYTE   = 2
    )(
    input wire          clk,
    input wire          rst_n,
    input wire          padder_start,

    // Input Stream
    input wire          msg_valid,
    input wire [SHA_WORD_WIDTH-1:0]   msg_data,
    input wire          msg_last,
    input wire [SHA_LAST_BYTE-1:0]    msg_last_bytes, // 00=4B, 01=1B, 10=2B, 11=3B

    // Output
    input wire          schedule_ready,
    output reg          msg_stall,    // CHANGED: Now an output    
    output reg          block_valid,
    output reg          final_block,
   // output reg [511:0]  block_out
   output          [SHA_WORD_WIDTH-1:0]  blk0_out,
   output          [SHA_WORD_WIDTH-1:0]  blk1_out,
   output          [SHA_WORD_WIDTH-1:0]  blk2_out,
   output          [SHA_WORD_WIDTH-1:0]  blk3_out,
   output          [SHA_WORD_WIDTH-1:0]  blk4_out,
   output          [SHA_WORD_WIDTH-1:0]  blk5_out,
   output          [SHA_WORD_WIDTH-1:0]  blk6_out,
   output          [SHA_WORD_WIDTH-1:0]  blk7_out,
   output          [SHA_WORD_WIDTH-1:0]  blk8_out,
   output          [SHA_WORD_WIDTH-1:0]  blk9_out,
   output          [SHA_WORD_WIDTH-1:0]  blk10_out,
   output          [SHA_WORD_WIDTH-1:0]  blk11_out,
   output          [SHA_WORD_WIDTH-1:0]  blk12_out,
   output          [SHA_WORD_WIDTH-1:0]  blk13_out,
   output          [SHA_WORD_WIDTH-1:0]  blk14_out,
   output          [SHA_WORD_WIDTH-1:0]  blk15_out
);

    // Internal Signals
    reg [SHA_WORD_WIDTH-1:0] buffer [0:15];
    reg [3:0]  word_ptr;
    reg [SHA_MSG_LENGTH-1:0] total_bits;
    reg        spill_80;
    
    // This MUST be reg for the always @(*) block, but acts as a wire
    reg [SHA_MSG_LENGTH-1:0] calc_final_length;

    wire [SHA_WORD_WIDTH-2:0] const0;

    // State Machine
    localparam S_IDLE      = 3'd0;
    localparam S_STREAM    = 3'd1;
    localparam S_EMIT_MID  = 3'd2;
    localparam S_EMIT_LAST = 3'd3;
    localparam S_EMIT_OVF  = 3'd4;
    localparam S_EXTRA_PAD = 3'd5;

    reg [2:0] state;
    integer i;

    // -------------------------------------------------------------------------
    // COMBINATORIAL BLOCK: Calculates length INSTANTLY
    // -------------------------------------------------------------------------
`ifdef SHA512

    always @(*) begin
        // Use the current register value of total_bits
        // + add the bits from the current input word immediately
        case (msg_last_bytes)
            3'b000: calc_final_length = total_bits + 128'd64; // 8 bytes
            3'b001: calc_final_length = total_bits + 128'd8;  // 1 byte
            3'b010: calc_final_length = total_bits + 128'd16; // 2 bytes
            3'b011: calc_final_length = total_bits + 128'd24; // 3 bytes
            3'b100: calc_final_length = total_bits + 128'd32; // 4 bytes
            3'b101: calc_final_length = total_bits + 128'd40; // 5 bytes
            3'b110: calc_final_length = total_bits + 128'd48; // 6 bytes
            3'b111: calc_final_length = total_bits + 128'd56; // 7 bytes

//            default: calc_final_length = total_bits;
        endcase
    end

 `else
    always @(*) begin
        // Use the current register value of total_bits
        // + add the bits from the current input word immediately
        case (msg_last_bytes)
            2'b00: calc_final_length = total_bits + 64'd32; // 4 bytes
            2'b01: calc_final_length = total_bits + 64'd8;  // 1 byte
            2'b10: calc_final_length = total_bits + 64'd16; // 2 bytes
            2'b11: calc_final_length = total_bits + 64'd24; // 3 bytes
//            default: calc_final_length = total_bits;
        endcase
    end
`endif
    // -------------------------------------------------------------------------
    // STALL LOGIC: Drive the output msg_stall
    // -------------------------------------------------------------------------
    always @(*) begin
        // Stall the input if we are NOT in IDLE or STREAM mode (busy processing),
        // OR if the current output block is valid but hasn't been accepted yet.
        if (state != S_IDLE && state != S_STREAM)
            msg_stall = 1'b1;
        else if (block_valid && !schedule_ready)
            msg_stall = 1'b1;
        else
            msg_stall = 1'b0;
    end

    // -------------------------------------------------------------------------
    // Output Mapping
    // -------------------------------------------------------------------------
/*    always @(*) begin
        for (i = 0; i < 16; i = i + 1) begin
            block_out[511 - (32*i) -: 32] = buffer[i];
        end
    end*/


    // -------------------------------------------------------------------------
    // Main Sequential Logic
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= S_IDLE;
            word_ptr    <= 4'd0;
            total_bits  <= {SHA_MSG_LENGTH{1'b0}};
            block_valid <= 1'b0;
            final_block <= 1'b0;
            spill_80    <= 1'b0;
            for(i=0; i<16; i=i+1) buffer[i] <= {SHA_WORD_WIDTH{1'b0}};
        end else begin
            
            // Handshake Reset
            if (block_valid && schedule_ready) begin
                block_valid <= 1'b0;
            end

            case (state)
                S_IDLE: begin
                    if (padder_start) begin
                        state      <= S_STREAM;
                        word_ptr   <= 4'd0;
                        total_bits <= {SHA_MSG_LENGTH{1'B0}};

                        spill_80   <= 1'b0;
                        final_block <= 1'b0;                        
                        for(i=0; i<16; i=i+1) buffer[i] <= {SHA_WORD_WIDTH{1'b0}};

                    end
                end

                S_STREAM: begin
                    // Only accept data if we are NOT holding a valid block that hasn't been read
                    if (msg_valid && !block_valid) begin
                        
                        // --- A. Normal Middle Word ---
                        if (!msg_last) begin
                            buffer[word_ptr] <= msg_data;
                            `ifdef SHA512
                                total_bits       <= total_bits + 128'd64; // Updates for NEXT cycle
                            `else
                                total_bits <= total_bits + 64'd32;
                            `endif

                            if (word_ptr == 15) begin
                                block_valid <= 1'b1;
                                final_block <= 1'b0;
                                state       <= S_EMIT_MID;
                            end else begin
                                word_ptr    <= word_ptr + 1'b1;
                            end
                        end
                        
                        // --- B. Last Word (Data + Padding) ---
                        else begin
                            // 1. Write Data + 0x80 Padding
                         `ifdef SHA512
                            case (msg_last_bytes)
                                3'd0: buffer[word_ptr] <= msg_data;
                                3'd1: buffer[word_ptr] <= {msg_data[63:56], 8'h80, 48'h0};
                                3'd2: buffer[word_ptr] <= {msg_data[63:48], 8'h80, 40'h0};
                                3'd3: buffer[word_ptr] <= {msg_data[63:40], 8'h80, 32'h0};
                                3'd4: buffer[word_ptr] <= {msg_data[63:32], 8'h80, 24'h0};
                                3'd5: buffer[word_ptr] <= {msg_data[63:24], 8'h80, 16'h0};
                                3'd6: buffer[word_ptr] <= {msg_data[63:16], 8'h80, 8'h0};                
                                3'd7: buffer[word_ptr] <= {msg_data[63:8], 8'h80};
                                                            endcase
                                                            $display("SHA512");



                         `else
                            case (msg_last_bytes)
                                2'b00: buffer[word_ptr] <= msg_data;
                                2'b01: buffer[word_ptr] <= {msg_data[31:24], 8'h80, 16'h0000};
                                2'b10: buffer[word_ptr] <= {msg_data[31:16], 8'h80, 8'h00};
                                2'b11: buffer[word_ptr] <= {msg_data[31:8],  8'h80};
                                
                            endcase
                                $display("SHA256");
                            
                        `endif

                            // Clear remaining words
                            for (i=0; i<16; i=i+1) begin
                                if (i > word_ptr) buffer[i] <= {SHA_WORD_WIDTH{1'b0}};
                            end

                            // 2. Overflow Check
                            // We use 'calc_final_length' which is VALID NOW
                            if ((msg_last_bytes == 0 && word_ptr >= 13) || (msg_last_bytes != 0 && word_ptr >= 14)) begin
                                // Overflow Logic
                                final_block <= 1'b0;                                
                                if (msg_last_bytes == 0 && word_ptr == 15)
                                    spill_80 <= 1'b1;
                                else if (msg_last_bytes == 0) begin
                                    buffer[word_ptr+1] <= {1'b1, const0}; //(SHA_WORD_WIDTH-1){1'b0}};
                                    spill_80 <= 1'b0;
                                end else
                                    spill_80 <= 1'b0;

                                // Save calculated length for the EXTRA block
                                total_bits  <= calc_final_length;
                                block_valid <= 1'b1;
                                final_block <= 1'b0;
                                state       <= S_EMIT_OVF;
                            end
                            else begin
                                // Fits Logic
                                if (msg_last_bytes == 0) buffer[word_ptr+1] <= {1'b1, const0}; //(SHA_WORD_WIDTH-1){1'b0}};
                                
                                // Write Length IMMEDIATELY
                                buffer[14] <= calc_final_length[SHA_MSG_LENGTH-1:SHA_WORD_WIDTH];
                                buffer[15] <= calc_final_length[SHA_WORD_WIDTH-1:0];
                                
                                block_valid <= 1'b1;
                                final_block <= 1'b1;
                                state       <= S_EMIT_LAST;
                            end
                        end
                    end
                end

                S_EMIT_MID: begin
                    if (schedule_ready) begin
                        word_ptr <= 4'd0;
                        for(i=0; i<16; i=i+1) buffer[i] <= {SHA_WORD_WIDTH{1'b0}};
                        state    <= S_STREAM;
                    end
                end

                S_EMIT_LAST: begin
                    if (schedule_ready) state <= S_IDLE;
                end

                S_EMIT_OVF: begin
                    if (schedule_ready) state <= S_EXTRA_PAD;
                end

                S_EXTRA_PAD: begin
                    for(i=0; i<14; i=i+1) buffer[i] <= {SHA_WORD_WIDTH{1'b0}};

                    
                    if (spill_80) buffer[0] <= {1'b1, const0}; //(SHA_WORD_WIDTH-1){1'b0}}; //32'h80000000;
                    else          buffer[0] <= {SHA_WORD_WIDTH{1'b0}};

                    // Write Length (from total_bits saved in S_STREAM)
                    buffer[14] <= total_bits[SHA_MSG_LENGTH-1:SHA_WORD_WIDTH];
                    buffer[15] <= total_bits[SHA_WORD_WIDTH-1:0];

                    block_valid <= 1'b1;
                   // final_block <= 1'b1;
                    state       <= S_EMIT_LAST;
                end
            endcase
        end
    end

    assign const0 = {(SHA_WORD_WIDTH-1){1'b0}};

   assign blk0_out = buffer[0]; 
   assign blk1_out = buffer[1]; 
   assign blk2_out = buffer[2]; 
   assign blk3_out = buffer[3]; 
   assign blk4_out = buffer[4];     
   assign blk5_out = buffer[5]; 
   assign blk6_out = buffer[6]; 
   assign blk7_out = buffer[7]; 
   assign blk8_out = buffer[8]; 
   assign blk9_out = buffer[9]; 
   assign blk10_out = buffer[10]; 
   assign blk11_out = buffer[11]; 
   assign blk12_out = buffer[12]; 
   assign blk13_out = buffer[13];     
   assign blk14_out = buffer[14];     
   assign blk15_out = buffer[15];  

endmodule
