
`timescale 1ns/1ps

module tb_sha256_padder;

    parameter SHA_WORD_WIDTH = 64,  //32 for sha256, 64 for sha512
              SHA_LAST_BYTE  = 3;   // 2 for sha256, 3 for sha512
            //  SHA_MSG_LENGTH = 64;

    reg clk;
    reg rst_n;
    wire msg_stall;       // CHANGED: Now a wire (output from DUT)
    reg padder_start;
    reg msg_valid;
    reg msg_last;
    reg schedule_ready;
    reg [SHA_WORD_WIDTH-1:0] msg_data;
    reg [SHA_LAST_BYTE-1:0] msg_last_bytes;

    wire block_valid;
    wire final_block;
    wire [SHA_WORD_WIDTH-1:0] blk0_out;
    wire [SHA_WORD_WIDTH-1:0] blk1_out;
    wire [SHA_WORD_WIDTH-1:0] blk2_out;
    wire [SHA_WORD_WIDTH-1:0] blk3_out;
    wire [SHA_WORD_WIDTH-1:0] blk4_out;
    wire [SHA_WORD_WIDTH-1:0] blk5_out;
    wire [SHA_WORD_WIDTH-1:0] blk6_out;
    wire [SHA_WORD_WIDTH-1:0] blk7_out;
    wire [SHA_WORD_WIDTH-1:0] blk8_out;
    wire [SHA_WORD_WIDTH-1:0] blk9_out;
    wire [SHA_WORD_WIDTH-1:0] blk10_out;
    wire [SHA_WORD_WIDTH-1:0] blk11_out;
    wire [SHA_WORD_WIDTH-1:0] blk12_out;
    wire [SHA_WORD_WIDTH-1:0] blk13_out;
    wire [SHA_WORD_WIDTH-1:0] blk14_out;
    wire [SHA_WORD_WIDTH-1:0] blk15_out;
//    wire [511:0] block_out;

    integer i;

    initial
    begin

        $shm_open("sha256_512.shm");
        $shm_probe("ACTMF");
    end

    // Instantiate DUT
    sha256_padder #(
        .SHA_WORD_WIDTH(SHA_WORD_WIDTH),
        .SHA_LAST_BYTE(SHA_LAST_BYTE)
//        .SHA_MSG_LENGTH(SHA_MSG_LENGTH)
        )uut (
        .clk(clk),
        .rst_n(rst_n),
        .msg_stall(msg_stall), // Connected to wire
        .padder_start(padder_start),
        .msg_valid(msg_valid),
        .msg_data(msg_data),
        .msg_last(msg_last),
        .msg_last_bytes(msg_last_bytes),
        .schedule_ready(schedule_ready),
        .block_valid(block_valid),
        .final_block(final_block),
//        .block_out(block_out)
        .blk0_out(blk0_out),
        .blk1_out(blk1_out),
        .blk2_out(blk2_out),
        .blk3_out(blk3_out),
        .blk4_out(blk4_out),
        .blk5_out(blk5_out),
        .blk6_out(blk6_out),
        .blk7_out(blk7_out),
        .blk8_out(blk8_out),
        .blk9_out(blk9_out),
        .blk10_out(blk10_out),
        .blk11_out(blk11_out),
        .blk12_out(blk12_out),
        .blk13_out(blk13_out),
        .blk14_out(blk14_out),
        .blk15_out(blk15_out)

    );

    // CLOCK
    initial clk = 0;
    always #5 clk = ~clk;

    // OUTPUT MONITOR
    always @(posedge clk) begin
        if (block_valid && schedule_ready) begin
            $display("\n[Time %0t] BLOCK VALID (FINAL=%b)", $time, final_block);
            $display("    DATA: %h", {blk0_out,//block_out);
                                      blk1_out,
                                      blk2_out,
                                      blk3_out,
                                      blk4_out,
                                      blk5_out,
                                      blk6_out,
                                      blk7_out,
                                      blk8_out,
                                      blk9_out,
                                      blk10_out,
                                      blk11_out,
                                      blk12_out,
                                      blk13_out,
                                      blk14_out,
                                      blk15_out});


            if (final_block) begin
                $display("    -> LENGTH FIELD: %h %h", blk14_out,blk15_out);
       //                  block_out[63:32], block_out[31:0]);
            end
        end
    end

    // MAIN TEST
    initial begin
        // RESET
        rst_n = 0;
        // stall = 0; // REMOVED: No longer driving stall manually
        padder_start = 0;
        schedule_ready = 1;
        msg_valid = 0;
        msg_last = 0;
        msg_last_bytes = 0;
        msg_data = 0;

        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        // ---------------------------------------------------------------------
        // TEST 1: 'abc' (3 bytes)
        // ---------------------------------------------------------------------
      /*  $display("\n--- Test 1: 'abc' (3 bytes) ---");
        padder_start = 1;
        @(posedge clk);
        padder_start = 0;
        msg_valid = 1;
        msg_last = 1;
        msg_last_bytes = 2'b11; // 3 bytes
        msg_data = 32'h61626300;
        @(posedge clk);
        
        msg_valid = 0;
        msg_last = 0;
        repeat(10) @(posedge clk);

        // ---------------------------------------------------------------------
        // TEST 2: Overflow case
        // ---------------------------------------------------------------------
        $display("\n--- Test 2: Overflow case ---");
        padder_start = 1;
        @(posedge clk);
        padder_start = 0;
        
        for (i=0; i<14; i=i+1) begin
            msg_valid = 1;
            msg_last = 0;
            msg_data = 32'hEEEE_EEEE;
            @(posedge clk);
        end
        
        msg_valid = 1;
        msg_last = 1;
        msg_last_bytes = 2'b00; // full 4 bytes
        msg_data = 32'hFFFF_FFFF;
        @(posedge clk);
        
        msg_valid = 0;
        msg_last = 0;
        repeat(20) @(posedge clk);

        // ---------------------------------------------------------------------
        // TEST 3: Exact 16-word block
        // ---------------------------------------------------------------------
        $display("\n--- Test 3: Exact 16-word block ---");
        padder_start = 1;
        @(posedge clk);
        padder_start = 0;
        
        for (i=0; i<15; i=i+1) begin
            msg_valid = 1;
            msg_last = 0;
            msg_data = 32'hA0000000 + i;
            @(posedge clk);
        end
        
        msg_valid = 1;
        msg_last = 1;
        msg_last_bytes = 2'b00;
        msg_data = 32'hA000000F;
        @(posedge clk);
        
        msg_valid = 0;
        repeat(20) @(posedge clk);
        
        // ---------------------------------------------------------------------
        // TEST 4: Multi-word test (40 words)
        // ---------------------------------------------------------------------
        $display("\n--- Test 4: Multi-word test (40 words) ---");
        padder_start = 1;
        @(posedge clk);
        padder_start = 0;

        for (i=0; i<39; i=i+1) begin
            msg_valid = 1;
            msg_last = 0;
            msg_data = i;
            @(posedge clk);
        end

        msg_valid = 1;
        msg_last = 1;
        msg_last_bytes = 2'b00;
        msg_data = 39;
        @(posedge clk);
        msg_valid = 0;
        msg_last = 0;
        repeat(40) @(posedge clk);

        // ---------------------------------------------------------------------
        // TEST 5: Last word with 1 byte
        // ---------------------------------------------------------------------
        $display("\n--- Test 5: Last word with 1 byte ---");
        padder_start = 1;
        @(posedge clk);
        padder_start = 0;
        
        msg_valid = 1;
        msg_last = 0;
        msg_data = 32'hAABBCCDD;
        @(posedge clk);

        msg_valid = 1;
        msg_last = 1;
        msg_last_bytes = 2'b01; // 1 byte valid
        msg_data = 32'h55000000;
        @(posedge clk);

        msg_valid = 0;
        msg_last = 0;
        repeat(20) @(posedge clk);

        // ---------------------------------------------------------------------
        // TEST 6: Stall behavior
        // ---------------------------------------------------------------------
        $display("\n--- Test 6: Stall behavior ---");
        padder_start = 1;
        @(posedge clk);
        padder_start = 0;
        
        for (i=0; i<5; i=i+1) begin
            msg_valid = 1;
            msg_last = 0;
            msg_data = 32'hABC00000 + i;
            @(posedge clk);
        end
        
        // CRITICAL FIX: Stop sending data before stalling!
        msg_valid = 0; 

        $display("Applying stall (via schedule_ready=0)...");
        schedule_ready = 0; // Simulate backpressure
        repeat(8) @(posedge clk);
        
        $display("Removing stall...");
        schedule_ready = 1;

        msg_valid = 1;
        msg_last = 1;
        msg_last_bytes = 2'b00;
        msg_data = 32'hDEADBEEF;
        @(posedge clk);
        
        msg_valid = 0;
        msg_last = 0;
        repeat(30) @(posedge clk);*/


        // ---------------------------------------------------------------------
        // TEST 7: NIST Standard - "Two Block Message Sample"
        // Input: "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
        // Length: 56 bytes (448 bits) -> Requires 2 blocks due to padding
        // ---------------------------------------------------------------------
        if(SHA_WORD_WIDTH==32) begin
        $display("\n--- Test 7: NIST Two Block Message (56 bytes) ---");
        padder_start = 1;
        @(posedge clk);
        padder_start = 0;

        // Loop for the first 13 words (indices 0 to 12)
        // Pattern logic: Word 'i' is composed of chars starting at 'a' + i
      /*  for (i=0; i<13; i=i+1) begin
            msg_valid = 1;
            msg_last = 0;
            // Construct pattern automatically: e.g., i=0 -> "abcd" (0x61626364)
            msg_data = { (8'h61 + i[7:0]), (8'h62 + i[7:0]), (8'h63 + i[7:0]), (8'h64 + i[7:0]) };
            @(posedge clk);
        end

        // Send the 14th and Final Word (Index 13: "nopq")
        msg_valid = 1;
        msg_last = 1;
        msg_last_bytes = 2'b00; // All 4 bytes are valid
        // i=13 here -> "nopq"
        msg_data = { (8'h61 + 13), (8'h62 + 13), (8'h63 + 13), (8'h64 + 13) }; 
        @(posedge clk);

        msg_valid = 0;
        schedule_ready = 0;
        msg_last = 0;
        repeat(10) @(posedge clk);
        schedule_ready = 1;
        repeat(60) @(posedge clk);    
        schedule_ready = 0; */




        //testcase.............................................................
      
        // =====================================================================
        // EXCEL SHEET TESTS: BOUNDARY ANALYSIS
        // =====================================================================

        // ---------------------------------------------------------------------
        // GROUP A: "In 1st Word" (Short inputs)
        // ---------------------------------------------------------------------

        // Case A1: Pass only 1 byte (0x11)
        $display("\n--- Excel Case A1: 1st Word, 1 Byte (11...) ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        msg_valid = 1; msg_last = 1; msg_last_bytes = 2'b01; 
        msg_data = 32'h11000000;
        @(posedge clk);
        msg_valid = 0; msg_last = 0;
        repeat(10) @(posedge clk);

        // Case A2: Pass only 2 bytes (0x1122)
        $display("\n--- Excel Case A2: 1st Word, 2 Bytes (1122...) ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        msg_valid = 1; msg_last = 1; msg_last_bytes = 2'b10; 
        msg_data = 32'h11220000;
        @(posedge clk);
        msg_valid = 0; msg_last = 0;
        repeat(10) @(posedge clk);

        // Case A3: Pass only 3 bytes (0x112233)
        $display("\n--- Excel Case A3: 1st Word, 3 Bytes (112233...) ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        msg_valid = 1; msg_last = 1; msg_last_bytes = 2'b11; 
        msg_data = 32'h11223300;
        @(posedge clk);
        msg_valid = 0; msg_last = 0;
        repeat(10) @(posedge clk);

        // Case A4: Pass 4 bytes (Full Word 0x11223344)
        // Expectation: Padding 0x80 spills to buffer[1]
        $display("\n--- Excel Case A4: 1st Word, 4 Bytes (11223344) ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        msg_valid = 1; msg_last = 1; msg_last_bytes = 2'b00; 
        msg_data = 32'h11223344;
        @(posedge clk);
        msg_valid = 0; msg_last = 0;
        repeat(10) @(posedge clk);


        // ---------------------------------------------------------------------
        // GROUP B: "In 14th Word" (Boundary of Single Block)
        // ---------------------------------------------------------------------

        // Case B1: 13 words + 1 byte (Should FIT in 1 block)
        $display("\n--- Excel Case B1: 14th Word, 1 Byte ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        // 1. Fill 13 words
        for(i=0; i<13; i=i+1) begin
            msg_valid = 1; msg_last = 0; msg_data = 32'h63636363; @(posedge clk);
        end
        // 2. Send 14th word (partial)
        msg_valid = 1; msg_last = 1; msg_last_bytes = 2'b01; 
        msg_data = 32'h63000000; 
        @(posedge clk);
        msg_valid = 0; msg_last = 0;
        repeat(10) @(posedge clk);

        // Case B2: 13 words + 2 bytes (Should FIT in 1 block)
        $display("\n--- Excel Case B2: 14th Word, 2 Bytes ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        for(i=0; i<13; i=i+1) begin
            msg_valid = 1; msg_last = 0; msg_data = 32'h62626262; @(posedge clk);
        end
        msg_valid = 1; msg_last = 1; msg_last_bytes = 2'b10; 
        msg_data = 32'h62620000; 
        @(posedge clk);
        msg_valid = 0; msg_last = 0;
        repeat(10) @(posedge clk);

        // Case B3: 13 words + 3 bytes (Should FIT in 1 block)
        $display("\n--- Excel Case B3: 14th Word, 3 Bytes ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        for(i=0; i<13; i=i+1) begin
            msg_valid = 1; msg_last = 0; msg_data = 32'h61616161; @(posedge clk);
        end
        msg_valid = 1; msg_last = 1; msg_last_bytes = 2'b11; 
        msg_data = 32'h61616100; 
        @(posedge clk);
        msg_valid = 0; msg_last = 0;
        repeat(10) @(posedge clk);

        // Case B4: 14 Full Words (Should OVERFLOW to 2 blocks)
        // Reason: Padding 0x80 must go to word 14, but word 14 is needed for Length.
        $display("\n--- Excel Case B4: 14 Full Words (Overflow) ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        for(i=0; i<13; i=i+1) begin
            msg_valid = 1; msg_last = 0; msg_data = 32'h61616161; @(posedge clk);
        end
        // 14th word is FULL
        msg_valid = 1; msg_last = 1; msg_last_bytes = 2'b00; 
        msg_data = 32'h61616161; 
        @(posedge clk);
        msg_valid = 0; msg_last = 0;
        repeat(20) @(posedge clk); // Give extra time for 2 blocks









        // ---------------------------------------------------------------------
        // EXCEL SHEET GROUP: "In 16th Word" (Index 15)
        // These tests fill the block to the very end.
        // All cases MUST overflow because there is no room for the Length field.
        // ---------------------------------------------------------------------

        // Case 1: Pass only 1 byte in the 16th word
        // Input: 15 full words + 1 byte
        // Total: 60 + 1 = 61 bytes. Expected Length: 0x1F8 (504 bits)
        $display("\n--- Excel Case: 16th Word, Pass Only 1 Byte ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        
        // 1. Fill first 15 words (indices 0-14)
        for(i=0; i<15; i=i+1) begin
            msg_valid = 1; msg_last = 0; msg_data = 32'h61616161; 
            @(posedge clk);
        end
        
        // 2. Send 16th word (Index 15) with 1 valid byte
        msg_valid = 1; 
        msg_last = 1; 
        msg_last_bytes = 2'b01; // 1 byte valid
        msg_data = 32'h61000000; 
        @(posedge clk);
        
        msg_valid = 0; msg_last = 0;
        repeat(20) @(posedge clk);


        // Case 2: Pass only 2 bytes in the 16th word
        // Input: 15 full words + 2 bytes
        // Total: 60 + 2 = 62 bytes. Expected Length: 0x200 (512 bits)
        $display("\n--- Excel Case: 16th Word, Pass Only 2 Bytes ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        
        for(i=0; i<15; i=i+1) begin
            msg_valid = 1; msg_last = 0; msg_data = 32'h61616161; 
            @(posedge clk);
        end
        
        msg_valid = 1; 
        msg_last = 1; 
        msg_last_bytes = 2'b10; // 2 bytes valid
        msg_data = 32'h61610000; 
        @(posedge clk);
        
        msg_valid = 0; msg_last = 0;
        repeat(20) @(posedge clk);


        // Case 3: Pass only 3 bytes in the 16th word
        // Input: 15 full words + 3 bytes
        // Total: 60 + 3 = 63 bytes. Expected Length: 0x208 (520 bits)
        $display("\n--- Excel Case: 16th Word, Pass Only 3 Bytes ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        
        for(i=0; i<15; i=i+1) begin
            msg_valid = 1; msg_last = 0; msg_data = 32'h61616161; 
            @(posedge clk);
        end
        
        msg_valid = 1; 
        msg_last = 1; 
        msg_last_bytes = 2'b11; // 3 bytes valid
        msg_data = 32'h61616100; 
        @(posedge clk);
        
        msg_valid = 0; msg_last = 0;
        repeat(20) @(posedge clk);


        // Case 4: Pass 4 bytes (Full Word) in the 16th word
        // Input: 16 FULL words (The entire block is data!)
        // Total: 64 bytes. Expected Length: 0x210 (528 bits)
        // **Note**: The padding bit 0x80 must spill to the next block [0].
        $display("\n--- Excel Case: 16th Word, Pass Only 4 Bytes (Full) ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        
        for(i=0; i<15; i=i+1) begin
            msg_valid = 1; msg_last = 0; msg_data = 32'h61616161; 
            @(posedge clk);
        end
        
        msg_valid = 1; 
        msg_last = 1; 
        msg_last_bytes = 2'b00; // 4 bytes valid (Full word)
        msg_data = 32'h61616161; 
        @(posedge clk);
        
        msg_valid = 0; msg_last = 0;
        repeat(20) @(posedge clk);

    end
    else // ==========================SHA512===========================================
    begin
                $display("\n--- Test 7: NIST Two Block Message (56 bytes) ---");
        padder_start = 1;
        @(posedge clk);
        padder_start = 0;

        // Loop for the first 13 words (indices 0 to 12)
        // Pattern logic: Word 'i' is composed of chars starting at 'a' + i
      /*  for (i=0; i<13; i=i+1) begin
            msg_valid = 1;
            msg_last = 0;
            // Construct pattern automatically: e.g., i=0 -> "abcd" (0x61626364)
            msg_data = { (8'h61 + i[7:0]), (8'h62 + i[7:0]), (8'h63 + i[7:0]), (8'h64 + i[7:0]) };
            @(posedge clk);
        end

        // Send the 14th and Final Word (Index 13: "nopq")
        msg_valid = 1;
        msg_last = 1;
        msg_last_bytes = 2'b00; // All 4 bytes are valid
        // i=13 here -> "nopq"
        msg_data = { (8'h61 + 13), (8'h62 + 13), (8'h63 + 13), (8'h64 + 13) }; 
        @(posedge clk);

        msg_valid = 0;
        schedule_ready = 0;
        msg_last = 0;
        repeat(10) @(posedge clk);
        schedule_ready = 1;
        repeat(60) @(posedge clk);    
        schedule_ready = 0; */




        //testcase.............................................................
      
        // =====================================================================
        // EXCEL SHEET TESTS: BOUNDARY ANALYSIS
        // =====================================================================

        // ---------------------------------------------------------------------
        // GROUP A: "In 1st Word" (Short inputs)
        // ---------------------------------------------------------------------

        // Case A1: Pass only 1 byte (0x11)
        $display("\n--- Excel Case A1: 1st Word, 1 Byte (11...) ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        msg_valid = 1; msg_last = 1; msg_last_bytes = 3'd1; 
        msg_data = 64'h1100000000000000;
        @(posedge clk);
        msg_valid = 0; msg_last = 0;
        repeat(10) @(posedge clk);

        // Case A2: Pass only 2 bytes (0x1122)
        $display("\n--- Excel Case A2: 1st Word, 2 Bytes (1122...) ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        msg_valid = 1; msg_last = 1; msg_last_bytes = 3'd2; 
        msg_data = 64'h1122000000000000;
        @(posedge clk);
        msg_valid = 0; msg_last = 0;
        repeat(10) @(posedge clk);

        // Case A3: Pass only 3 bytes (0x112233)
        $display("\n--- Excel Case A3: 1st Word, 3 Bytes (112233...) ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        msg_valid = 1; msg_last = 1; msg_last_bytes = 3'd3; 
        msg_data = 64'h1122330000000000;
        @(posedge clk);
        msg_valid = 0; msg_last = 0;
        repeat(10) @(posedge clk);

        // Case A4: Pass 4 bytes (Full Word 0x11223344)
        // Expectation: Padding 0x80 spills to buffer[1]
        $display("\n--- Excel Case A4: 1st Word, 4 Bytes (1122334455667799) ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        msg_valid = 1; msg_last = 1; msg_last_bytes = 3'd0; 
        msg_data = 64'h1122334455667799;
        @(posedge clk);
        msg_valid = 0; msg_last = 0;
        repeat(10) @(posedge clk);


        // ---------------------------------------------------------------------
        // GROUP B: "In 14th Word" (Boundary of Single Block)
        // ---------------------------------------------------------------------

        // Case B1: 13 words + 1 byte (Should FIT in 1 block)
        $display("\n--- Excel Case B1: 14th Word, 1 Byte ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        // 1. Fill 13 words
        for(i=0; i<13; i=i+1) begin
            msg_valid = 1; msg_last = 0; msg_data = 64'h6363636363636363; @(posedge clk);
        end
        // 2. Send 14th word (partial)
        msg_valid = 1; msg_last = 1; msg_last_bytes = 3'd1; 
        msg_data = 64'h6300000000000000; 
        @(posedge clk);
        msg_valid = 0; msg_last = 0;
        repeat(10) @(posedge clk);

        // Case B2: 13 words + 2 bytes (Should FIT in 1 block)
        $display("\n--- Excel Case B2: 14th Word, 2 Bytes ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        for(i=0; i<13; i=i+1) begin
            msg_valid = 1; msg_last = 0; msg_data = 64'h6262626262626262; @(posedge clk);
        end
        msg_valid = 1; msg_last = 1; msg_last_bytes = 3'd2; 
        msg_data = 64'h6262000000000000; 
        @(posedge clk);
        msg_valid = 0; msg_last = 0;
        repeat(10) @(posedge clk);

        // Case B3: 13 words + 3 bytes (Should FIT in 1 block)
        $display("\n--- Excel Case B3: 14th Word, 5 Bytes ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        for(i=0; i<13; i=i+1) begin
            msg_valid = 1; msg_last = 0; msg_data = 64'h6161616161616161; @(posedge clk);
        end
        msg_valid = 1; msg_last = 1; msg_last_bytes = 3'd5; 
        msg_data = 64'h6262626262000000; 
        @(posedge clk);
        msg_valid = 0; msg_last = 0;
        repeat(10) @(posedge clk);

        // Case B4: 14 Full Words (Should OVERFLOW to 2 blocks)
        // Reason: Padding 0x80 must go to word 14, but word 14 is needed for Length.
        $display("\n--- Excel Case B4: 14 Full Words (Overflow) ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        for(i=0; i<13; i=i+1) begin
            msg_valid = 1; msg_last = 0; msg_data = 64'h6161616161616161; @(posedge clk);
        end
        // 14th word is FULL
        msg_valid = 1; msg_last = 1; msg_last_bytes = 3'b00; 
        msg_data = 64'h6161616161616161; 
        @(posedge clk);
        msg_valid = 0; msg_last = 0;
        repeat(20) @(posedge clk); // Give extra time for 2 blocks









        // ---------------------------------------------------------------------
        // EXCEL SHEET GROUP: "In 16th Word" (Index 15)
        // These tests fill the block to the very end.
        // All cases MUST overflow because there is no room for the Length field.
        // ---------------------------------------------------------------------

        // Case 1: Pass only 1 byte in the 16th word
        // Input: 15 full words + 1 byte
        // Total: 60 + 1 = 61 bytes. Expected Length: 0x1F8 (504 bits)
        $display("\n--- Excel Case: 16th Word, Pass Only 7 Bytes ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        
        // 1. Fill first 15 words (indices 0-14)
        for(i=0; i<15; i=i+1) begin
            msg_valid = 1; msg_last = 0; msg_data = 64'h6161616161616161; 
            @(posedge clk);
        end
        
        // 2. Send 16th word (Index 15) with 1 valid byte
        msg_valid = 1; 
        msg_last = 1; 
        msg_last_bytes = 3'd7; // 1 byte valid
        msg_data = 64'h6363636363636300; 
        @(posedge clk);
        
        msg_valid = 0; msg_last = 0;
        repeat(20) @(posedge clk);


        // Case 2: Pass only 2 bytes in the 16th word
        // Input: 15 full words + 2 bytes
        // Total: 60 + 2 = 62 bytes. Expected Length: 0x200 (512 bits)
        $display("\n--- Excel Case: 16th Word, Pass Only 2 Bytes ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        
        for(i=0; i<15; i=i+1) begin
            msg_valid = 1; msg_last = 0; msg_data = 64'h6161616161616161; 
            @(posedge clk);
        end
        
        msg_valid = 1; 
        msg_last = 1; 
        msg_last_bytes = 3'd2; // 2 bytes valid
        msg_data = 64'h6161000000000000; 
        @(posedge clk);
        
        msg_valid = 0; msg_last = 0;
        repeat(20) @(posedge clk);


        // Case 3: Pass only 3 bytes in the 16th word
        // Input: 15 full words + 3 bytes
        // Total: 60 + 3 = 63 bytes. Expected Length: 0x208 (520 bits)
        $display("\n--- Excel Case: 16th Word, Pass Only 4 Bytes ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        
        for(i=0; i<15; i=i+1) begin
            msg_valid = 1; msg_last = 0; msg_data = 64'h6161616161616161; 
            @(posedge clk);
        end
        
        msg_valid = 1; 
        msg_last = 1; 
        msg_last_bytes = 3'd4; // 3 bytes valid
        msg_data = 64'h6161616100000000; 
        @(posedge clk);
        
        msg_valid = 0; msg_last = 0;
        repeat(20) @(posedge clk);


        // Case 4: Pass 4 bytes (Full Word) in the 16th word
        // Input: 16 FULL words (The entire block is data!)
        // Total: 64 bytes. Expected Length: 0x210 (528 bits)
        // **Note**: The padding bit 0x80 must spill to the next block [0].
        $display("\n--- Excel Case: 16th Word, Pass Only 6 Bytes (Full) ---");
        padder_start = 1; @(posedge clk); padder_start = 0;
        
        for(i=0; i<15; i=i+1) begin
            msg_valid = 1; msg_last = 0; msg_data = 64'h6161616161616161; 
            @(posedge clk);
        end
        
        msg_valid = 1; 
        msg_last = 1; 
        msg_last_bytes = 3'd6; // 4 bytes valid (Full word)
        msg_data = 64'h6161616161610000; 
        @(posedge clk);
        
        msg_valid = 0; msg_last = 0;
        repeat(20) @(posedge clk);


        end

        $display("\nAll tests completed.");
        $finish;
    end
endmodule
