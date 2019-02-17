/*`timescale 1ns/1ps

module sha256_padder_stream_tb;

    reg clk;
    reg rst_n;

    reg        msg_valid;
    reg        msg_last;
    reg [1:0]  msg_last_bytes;
    reg [31:0] msg_data;

    wire [511:0] block_out;
    wire         block_valid;

    integer i;



initial
begin
$shm_open("padder.shm");
$shm_probe("ACTMF");
end


    // DUT instance
    sha256_padder dut (
        .clk(clk),
        .rst_n(rst_n),
        .msg_valid(msg_valid),
        .msg_last(msg_last),
        .msg_last_bytes(msg_last_bytes),
        .msg_data(msg_data),
        .block_out(block_out),
        .block_valid(block_valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Watchdog
    initial begin
        #50000;
        $display("Error: Simulation Timeout");
        $finish;
    end

    // Print block output
    reg [31:0] blk_cnt;
    always @(posedge clk) begin
        if (block_valid) begin
            $display("\n-------------------------------------------------------");
            $display(" BLOCK OUTPUT #%0d @ time %0t", blk_cnt + 1, $time);
            $display("-------------------------------------------------------");
            // Display as 16 words for readability
            for(i=0; i<16; i=i+1) begin
                $write("%h ", block_out[511-(i*32) -: 32]);
                if (i % 4 == 3) $display(""); // Newline every 4 words
            end
            $display("Length Field (Last 64 bits): %h", block_out[63:0]);
            $display("-------------------------------------------------------\n");
            blk_cnt = blk_cnt + 1;
        end
    end

    // Task to send 1 word
    task send_word;
        input [31:0] w;
        input last;
        input [1:0] last_bytes;
    begin
        wait(!block_valid); // Wait if currently outputting
        @(posedge clk);
        msg_valid      <= 1;
        msg_last       <= last;
        msg_last_bytes <= last_bytes;
        msg_data       <= w;

        @(posedge clk);
        msg_valid      <= 0;
        msg_last       <= 0;
        msg_last_bytes <= 0;
        msg_data       <= 32'h0;
    end
    endtask


    initial begin
        // Init
        msg_valid = 0;
        msg_last = 0;
        msg_last_bytes = 2'd0;
        msg_data = 32'h0;
        blk_cnt = 0;

        rst_n = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;

        // ------------------------------------------------------
        // TEST 1: "abc"
        // Expected Length = 24 bits (0x18)
        // ------------------------------------------------------
        $display("\n====== TEST 1: MESSAGE = \"abc\" ======");
        $display("Sending 'abc' (3 bytes valid in word)...");
        blk_cnt = 0;
        // 'abc' is 0x616263. Padded in input word 0x616263xx.
        // last_bytes=3 implies top 3 bytes are valid.
        send_word(32'h61626300, 1, 3);

        wait(block_valid); @(posedge clk); 
        repeat(10) @(posedge clk);

        // ------------------------------------------------------
        // TEST 2: Multi-Block (56 Bytes)
        // 56 Bytes = 448 bits. This fills exactly up to the Length field.
        // But SHA256 requires 1 bit padding (0x80).
        // 448 + 8 (padding) = 456 bits. This > 448.
        // So this requires TWO BLOCKS.
        // Block 1: Data + 0x80 padding.
        // Block 2: Zeros + Length.
        // ------------------------------------------------------
        $display("\n====== TEST 2: 56-BYTE MSG (Splits to 2 blocks) ======");
        blk_cnt = 0;
        // Send 13 Full words (13 * 4 = 52 bytes)
        for (i = 0; i < 13; i = i + 1)
            send_word(32'hAAAAAAAA, 0, 0);
        
        // Send 14th word (4 bytes) -> Total 56 bytes
        // last=1, last_bytes=0 (Full word)
        send_word(32'hBBBBBBBB, 1, 0);

        wait(block_valid); @(posedge clk); // Wait for Block 1
        while(block_valid) @(posedge clk);
        wait(block_valid); @(posedge clk); // Wait for Block 2
        
        repeat(20) @(posedge clk);
        $finish;
    end

endmodule*/

`timescale 1ns / 1ps

module sha256_padder_tb;
    reg clk, rst_n, msg_valid, msg_last;
    reg [1:0] msg_last_bytes;
    reg [31:0] msg_data;
    wire o_ready, o_word_valid, o_last_word;
    wire [31:0] o_word;


    initial
begin
$shm_open("padder.shm");
$shm_probe("ACTMF");
end
    
    // Instantiate the fast padder
    sha256_padder dut (
        .clk(clk), .rst_n(rst_n), 
        .msg_valid(msg_valid), .msg_last(msg_last),
        .msg_last_bytes(msg_last_bytes), .msg_data(msg_data), 
        .o_ready(o_ready), .o_word(o_word), 
        .o_word_valid(o_word_valid), .o_last_word(o_last_word)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    // Task to send a 32-bit word
    task send_word(input [31:0] data, input last, input [1:0] bytes);
    begin
        wait(o_ready); @(posedge clk);
        msg_valid <= 1; msg_data <= data; msg_last <= last; msg_last_bytes <= bytes;
        @(posedge clk); msg_valid <= 0; msg_last <= 0;
    end
    endtask

    // Display Logic
    integer w_cnt = 0, b_cnt = 0;
    always @(posedge clk) if (o_word_valid) begin
        if (w_cnt == 0) $display("\n--- Block %0d Output ---", b_cnt);
        $display("W[%02d] = %h", w_cnt, o_word);
        w_cnt <= (w_cnt == 15) ? 0 : w_cnt + 1;
        if (o_last_word) b_cnt <= b_cnt + 1;
    end

    initial begin
        rst_n = 0; msg_valid = 0; #20 rst_n = 1;
        
        // --- TEST 1: "abc" (3 Bytes) ---
        $display("\nTEST 1: 'abc'");
        b_cnt = 0;
        send_word(32'h61626300, 1, 3); // 'a'=61, 'b'=62, 'c'=63. 3 bytes valid.
        wait(b_cnt == 1);
        #100;

        // --- TEST 2: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" (45 Bytes) ---
        // 45 bytes = 11 words of 'aaaa' + 1 byte of 'a'
        $display("\nTEST 2: 45 'a's");
        b_cnt = 0;
        repeat(11) send_word(32'h61616161, 0, 0); 
        send_word(32'h61000000, 1, 1); // 12th word, only 1 'a' valid
        wait(b_cnt == 1);
        #100;

        // --- TEST 3: Long FIPS string (56 Bytes) ---
        // "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
        $display("\nTEST 3: FIPS Multi-block (56 Bytes)");
        b_cnt = 0;
        send_word(32'h61626364, 0, 0); // abcd
        send_word(32'h62636465, 0, 0); // bcde
        send_word(32'h63646566, 0, 0); // cdef
        send_word(32'h64656667, 0, 0); // defg
        send_word(32'h65666768, 0, 0); // efgh
        send_word(32'h66676869, 0, 0); // fghi
        send_word(32'h6768696a, 0, 0); // ghij
        send_word(32'h68696a6b, 0, 0); // hijk
        send_word(32'h696a6b6c, 0, 0); // ijkl
        send_word(32'h6a6b6c6d, 0, 0); // jklm
        send_word(32'h6b6c6d6e, 0, 0); // klmn
        send_word(32'h6c6d6e6f, 0, 0); // lmno
        send_word(32'h6d6e6f70, 0, 0); // mnop
        send_word(32'h6e6f7071, 1, 0); // nopq (56th byte, msg_last)
        
        wait(b_cnt == 2); // Should trigger two blocks
        #100;

        $display("\nAll Tests Complete.");
        $finish;
    end
endmodule



