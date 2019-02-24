`timescale 1ns/1ps
/*module sha256_padder (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          stall,
    input  wire          padder_start,
    
    // Input Stream
    input  wire          msg_valid,
    input  wire [31:0]   msg_data,
    input  wire          msg_last,
    input  wire [1:0]    msg_last_bytes, // 00=4B, 01=1B, 10=2B, 11=3B
    
    // Output
    input  wire          schedule_ready,
    output reg           block_valid,
    output reg           final_block,
    output reg  [511:0]  block_out
);

    // Internal Registers
    reg [31:0]  buffer [0:15];
    reg [3:0]   word_ptr;
    reg [63:0]  total_bits;
    
    // State Machine
    localparam S_IDLE        = 2'd0;
    localparam S_STREAM      = 2'd1;
    localparam S_WAIT_OUTPUT = 2'd2;
    localparam S_EXTRA_PAD   = 2'd3;
    
    reg [1:0] state;
    reg [1:0] return_state; // Remembers where to go after S_WAIT_OUTPUT
    reg       spill_80;     // Remembers if '1' bit spills to the extra block

    integer i;

    // -------------------------------------------------------------------------
    // Output Mapping (Concatenate Buffer to 512-bit bus)
    // -------------------------------------------------------------------------
    always @(*) begin
        for (i = 0; i < 16; i = i + 1) begin
            block_out[511 - (32*i) -: 32] = buffer[i];
        end
    end

    // -------------------------------------------------------------------------
    // Main Logic
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= S_IDLE;
            word_ptr        <= 4'd0;
            total_bits      <= 64'd0;
            block_valid     <= 1'b0;
            final_block     <= 1'b0;
            return_state    <= S_IDLE;
            spill_80        <= 1'b0;
            for(i=0; i<16; i=i+1) buffer[i] <= 32'd0;
        end 
        else if (!stall) begin
            
            // 1. Handshake Reset
            if (block_valid && schedule_ready) begin
                block_valid <= 1'b0;
            end

            case (state)
                // -------------------------------------------------------------
                // IDLE
                // -------------------------------------------------------------
                S_IDLE: begin
                    block_valid <= 1'b0;
                    if (padder_start) begin
                        state       <= S_STREAM;
                        word_ptr    <= 4'd0;
                        total_bits  <= 64'd0;
                        spill_80    <= 1'b0;
                        for(i=0; i<16; i=i+1) buffer[i] <= 32'd0;
                    end
                end

                // -------------------------------------------------------------
                // S_STREAM: Process Input Words
                // -------------------------------------------------------------
                S_STREAM: begin
                    if (msg_valid && !block_valid) begin
                        
                        // --- CASE A: Normal Middle Word ---
                        if (!msg_last) begin
                            buffer[word_ptr] <= msg_data;
                            total_bits       <= total_bits + 64'd32;
                            
                            if (word_ptr == 15) begin
                                // Block Full -> Emit
                                block_valid  <= 1'b1;
                                final_block  <= 1'b0;
                                state        <= S_WAIT_OUTPUT;
                                return_state <= S_STREAM; // Come back for more data
                            end else begin
                                word_ptr <= word_ptr + 1'b1;
                            end
                        end 
                        
                        // --- CASE B: Last Word (Padding & Length) ---
                        else begin
                            // 1. Update Final Length
                            // Note: We use a temporary variable calculation logic here by adding directly
                            if (msg_last_bytes == 2'b00)      total_bits <= total_bits + 64'd32;
                            else if (msg_last_bytes == 2'b01) total_bits <= total_bits + 64'd8;
                            else if (msg_last_bytes == 2'b10) total_bits <= total_bits + 64'd16;
                            else                              total_bits <= total_bits + 64'd24;

                            // 2. Write Data + Padding '1' (0x80)
                            case (msg_last_bytes)
                                2'b01: buffer[word_ptr] <= {msg_data[31:24], 8'h80, 16'h0000};
                                2'b10: buffer[word_ptr] <= {msg_data[31:16], 8'h80, 8'h00};
                                2'b11: buffer[word_ptr] <= {msg_data[31:8],  8'h80};
                                2'b00: buffer[word_ptr] <= msg_data;
                            endcase

                            // Clear future words in this block
                            for (i=0; i<16; i=i+1) begin
                                if (i > word_ptr) buffer[i] <= 32'd0;
                            end

                            // 3. Check for Overflow (Do we need an extra block?)
                            // We need words 14 and 15 free for length.
                            if ((msg_last_bytes != 2'b00 && word_ptr < 14) || 
                                (msg_last_bytes == 2'b00 && word_ptr < 13)) begin
                                
                                // --- FITS IN CURRENT BLOCK ---
                                if (msg_last_bytes == 2'b00) buffer[word_ptr+1] <= 32'h80000000;
                                
                                // WRITE LENGTH NOW (Using the updated value logic)
                                // Since total_bits is a reg, we must add the increment manually for this cycle
                                buffer[14] <= (total_bits + ((msg_last_bytes==0)?32:((msg_last_bytes==1)?8:((msg_last_bytes==2)?16:24)))) >> 32;
                                buffer[15] <= (total_bits + ((msg_last_bytes==0)?32:((msg_last_bytes==1)?8:((msg_last_bytes==2)?16:24))));

                                block_valid  <= 1'b1;
                                final_block  <= 1'b1;
                                state        <= S_WAIT_OUTPUT;
                                return_state <= S_IDLE; // Done
                            end 
                            else begin
                                // --- OVERFLOW: NEEDS EXTRA BLOCK ---
                                // Handle the '1' bit
                                if (msg_last_bytes == 2'b00 && word_ptr == 15) begin
                                    spill_80 <= 1'b1; // '1' bit goes to next block index 0
                                end else if (msg_last_bytes == 2'b00) begin
                                    buffer[word_ptr+1] <= 32'h80000000; // '1' bit fits here
                                    spill_80 <= 1'b0;
                                end else begin
                                    spill_80 <= 1'b0; // '1' bit was inside sub-word
                                end

                                block_valid  <= 1'b1;
                                final_block  <= 1'b0;
                                state        <= S_WAIT_OUTPUT;
                                return_state <= S_EXTRA_PAD; // Go to Extra Pad state
                            end
                        end
                    end
                end

                // -------------------------------------------------------------
                // S_WAIT_OUTPUT: Handshake State
                // -------------------------------------------------------------
                S_WAIT_OUTPUT: begin
                    if (schedule_ready) begin
                        state <= return_state;
                        // Reset for next block
                        if (return_state == S_STREAM) begin
                            word_ptr <= 4'd0;
                            for(i=0; i<16; i=i+1) buffer[i] <= 32'd0;
                        end
                    end
                end

                // -------------------------------------------------------------
                // S_EXTRA_PAD: Emit Final Overflow Block
                // -------------------------------------------------------------
                S_EXTRA_PAD: begin
                    // 1. Clear Block
                    for(i=0; i<14; i=i+1) buffer[i] <= 32'd0;
                    
                    // 2. Insert Spilled '1' bit if needed
                    if (spill_80) buffer[0] <= 32'h80000000;

                    // 3. Insert Length
                    buffer[14] <= total_bits[63:32];
                    buffer[15] <= total_bits[31:0];

                    block_valid  <= 1'b1;
                    final_block  <= 1'b1;
                    state        <= S_WAIT_OUTPUT;
                    return_state <= S_IDLE;
                end

            endcase
        end
    end

endmodule */


module sha256_padder (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          stall,
    input  wire          padder_start,
    
    // Input Stream
    input  wire          msg_valid,
    input  wire [31:0]   msg_data,
    input  wire          msg_last,
    input  wire [1:0]    msg_last_bytes, // 00=4B, 01=1B, 10=2B, 11=3B
    
    // Output
    input  wire          schedule_ready,
    output reg           block_valid,
    output reg           final_block,
    output reg  [511:0]  block_out
);

    // -------------------------------------------------------------------------
    // Internal Signals
    // -------------------------------------------------------------------------
    reg [31:0]  buffer [0:15];
    reg [3:0]   word_ptr;
    reg [63:0]  total_bits;
    reg         spill_80;

    // This MUST be reg for the always @(*) block, but acts as a wire
    reg [63:0]  calc_final_length; 

    // State Machine
    localparam S_IDLE       = 3'd0;
    localparam S_STREAM     = 3'd1;
    localparam S_EMIT_MID   = 3'd2;
    localparam S_EMIT_LAST  = 3'd3;
    localparam S_EMIT_OVF   = 3'd4;
    localparam S_EXTRA_PAD  = 3'd5;

    reg [2:0] state;
    integer i;

    // -------------------------------------------------------------------------
    // COMBINATORIAL BLOCK: Calculates length INSTANTLY
    // (Ensure this is OUTSIDE the always @(posedge clk) block!)
    // -------------------------------------------------------------------------
    always @(*) begin
        // Use the current register value of total_bits
        // + add the bits from the current input word immediately
        case (msg_last_bytes)
            2'b00: calc_final_length = total_bits + 64'd32; // 4 bytes
            2'b01: calc_final_length = total_bits + 64'd8;  // 1 byte
            2'b10: calc_final_length = total_bits + 64'd16; // 2 bytes
            2'b11: calc_final_length = total_bits + 64'd24; // 3 bytes
        endcase
    end

    // -------------------------------------------------------------------------
    // Output Mapping
    // -------------------------------------------------------------------------
    always @(*) begin
        for (i = 0; i < 16; i = i + 1) begin
            block_out[511 - (32*i) -: 32] = buffer[i];
        end
    end

    // -------------------------------------------------------------------------
    // Main Sequential Logic
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            word_ptr     <= 4'd0;
            total_bits   <= 64'd0;
            block_valid  <= 1'b0;
            final_block  <= 1'b0;
            spill_80     <= 1'b0;
            for(i=0; i<16; i=i+1) buffer[i] <= 32'd0;
        end 
        else if (!stall) begin
            
            // Handshake Reset
            if (block_valid && schedule_ready) begin
                block_valid <= 1'b0;
            end

            case (state)
                S_IDLE: begin
                    if (padder_start) begin
                        state       <= S_STREAM;
                        word_ptr    <= 4'd0;
                        total_bits  <= 64'd0;
                        spill_80    <= 1'b0;
                        for(i=0; i<16; i=i+1) buffer[i] <= 32'd0;
                    end
                end

                S_STREAM: begin
                    if (msg_valid && !block_valid) begin
                        
                        // --- A. Normal Middle Word ---
                        if (!msg_last) begin
                            buffer[word_ptr] <= msg_data;
                            total_bits       <= total_bits + 64'd32; // Updates for NEXT cycle
                            
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
                            case (msg_last_bytes)
                                2'b00: buffer[word_ptr] <= msg_data;
                                2'b01: buffer[word_ptr] <= {msg_data[31:24], 8'h80, 16'h0000};
                                2'b10: buffer[word_ptr] <= {msg_data[31:16], 8'h80, 8'h00};
                                2'b11: buffer[word_ptr] <= {msg_data[31:8],  8'h80};
                            endcase

                            // Clear remaining words
                            for (i=0; i<16; i=i+1) begin
                                if (i > word_ptr) buffer[i] <= 32'd0;
                            end

                            // 2. Overflow Check
                            // We use 'calc_final_length' which is VALID NOW
                            if ((msg_last_bytes == 0 && word_ptr >= 13) || (msg_last_bytes != 0 && word_ptr >= 14)) begin
                                // Overflow Logic
                                if (msg_last_bytes == 0 && word_ptr == 15) 
                                    spill_80 <= 1'b1; 
                                else if (msg_last_bytes == 0) begin
                                    buffer[word_ptr+1] <= 32'h80000000;
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
                                if (msg_last_bytes == 0) buffer[word_ptr+1] <= 32'h80000000;

                                // Write Length IMMEDIATELY
                                buffer[14]  <= calc_final_length[63:32];
                                buffer[15]  <= calc_final_length[31:0];

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
                        for(i=0; i<16; i=i+1) buffer[i] <= 32'd0;
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
                    for(i=0; i<14; i=i+1) buffer[i] <= 32'd0;
                    
                    if (spill_80) buffer[0] <= 32'h80000000;
                    else          buffer[0] <= 32'd0;

                    // Write Length (from total_bits saved in S_STREAM)
                    buffer[14] <= total_bits[63:32];
                    buffer[15] <= total_bits[31:0];

                    block_valid <= 1'b1;
                    final_block <= 1'b1;
                    state       <= S_EMIT_LAST;
                end
            endcase
        end
    end

endmodule
