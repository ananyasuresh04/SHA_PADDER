`timescale 1ns/1ps

module sha256_padder_tb;

    reg clk;
    reg rst_n;
    reg msg_valid;
    reg msg_last;
    reg [1:0] msg_last_bytes;
    reg [31:0] msg_data;

    wire [511:0] block_out;
    wire block_valid;

    integer blk_count;

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

    initial clk = 0;
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (block_valid) begin
            blk_count = blk_count + 1;
            $display("BLOCK %0d @ %0t", blk_count, $time);
            $display("%h", block_out);
        end
    end

    task send_word(input [31:0] w, input last, input [1:0] lb);
        begin
            msg_valid <= 1;
            msg_data <= w;
            msg_last <= last;
            msg_last_bytes <= lb;
            @(posedge clk);
        end
    endtask

    initial begin
        msg_valid = 0;
        msg_last = 0;
        msg_last_bytes = 0;
        msg_data = 0;
        blk_count = 0;

        rst_n = 0;
        repeat (2) @(posedge clk);
        rst_n = 1;

        $display("TEST: MULTI-BLOCK (>3 blocks)");

        send_word(32'h61626364,0,0);
        send_word(32'h62636465,0,0);
        send_word(32'h63646566,0,0);
        send_word(32'h64656667,0,0);
        send_word(32'h65666768,0,0);
        send_word(32'h66676869,0,0);
        send_word(32'h6768696a,0,0);
        send_word(32'h68696a6b,0,0);
        send_word(32'h696a6b6c,0,0);
        send_word(32'h6a6b6c6d,0,0);
        send_word(32'h6b6c6d6e,0,0);
        send_word(32'h6c6d6e6f,0,0);
        send_word(32'h6d6e6f70,0,0);

        // LAST WORD — CORRECT
        send_word(32'h6e6f7071,1,2'd0);

        msg_valid <= 0;

        repeat (20) @(posedge clk);
        $finish;
    end

endmodule


 /* ============================================================
           TEST 2: exactly 64 bytes ? 2 BLOCKS
           Length = 512 bits (0x200)
        ============================================================ */
       blk_count = 0;
        $display("\nTEST 2: 64 bytes");
        repeat (16)
            send_word(32'hAAAAAAAA, 0, 0);
        send_word(32'h00000000, 1, 0);
        repeat (20) @(posedge clk);
        $display("EXPECTED BLOCKS = 2\n");

        /* ============================================================
           TEST 3: 20 BLOCK MESSAGE
           80 words + 3 bytes = 323 bytes
           Length = 2584 bits (0xA18)
        ============================================================ */
       blk_count = 0;
        $display("\nTEST 3: 20 BLOCK MESSAGE");
        repeat (80)
            send_word(32'hBBBBBBBB, 0, 0);
        send_word(32'hCCCCCC00, 1, 2'd3);
        repeat (40) @(posedge clk);
        $display("EXPECTED BLOCKS = 7\n");


     
        blk_count=0;
        $display("\nTEST 3: 20 BLOCK MESSAGE");
        repeat (80)
            send_word(32'hBBBBBBBB, 0, 0);
        send_word(32'hCCCCCC00, 1, 2'd3);
        repeat (40) @(posedge clk);
        $display("EXPECTED BLOCKS = 7\n");


        /* ============================================================
           TEST 4: 100 BLOCK MESSAGE
           1600 words = 6400 bytes
           Length = 51200 bits (0xC800)
        ============================================================ */
       blk_count = 0;
        $display("\nTEST 4: 100 BLOCK MESSAGE");
        repeat (1600)
            send_word(32'hDDDDDDDD, 0, 0);
        send_word(32'h00000000, 1, 0);
        repeat (100) @(posedge clk);
        $display("EXPECTED BLOCKS = 101\n");

       /* ============================================================
           TEST 5: BACK-TO-BACK MESSAGES (NO RESET)
        ============================================================ */
        blk_count = 0;
        $display("\nTEST 5: BACK-TO-BACK");

        // Message A (5 blocks)
        repeat (80)
            send_word(32'h11111111, 0, 0);
        send_word(32'h00000000, 1, 0);

        // Message B (12 blocks)
        repeat (192)
            send_word(32'h22222222, 0, 0);
        send_word(32'h00000000, 1, 0);

        repeat (200) @(posedge clk);
        $display("EXPECTED BLOCKS = 19\n");

