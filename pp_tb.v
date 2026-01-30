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

    /* Clock */
    initial clk = 0;
    always #5 clk = ~clk;

    /* Count blocks */
    always @(posedge clk) begin
        if (block_valid) begin
            blk_count = blk_count + 1;
            $display("\n==============================");
            $display("BLOCK %0d @ %0t", blk_count, $time);
            $display("==============================");
            $display("%h", block_out);
        end
    end

    /* TASK TO SEND ONE WORD */
    task send_word(input [31:0] w, input last, input [1:0] lb);
        begin
            msg_data  <= w;
            msg_last  <= last;
            msg_last_bytes <= lb;
            msg_valid <= 1;
            @(posedge clk);
            msg_valid <= 0;
            msg_last  <= 0;
        end
    endtask

    /* MAIN TEST SEQUENCE */
    initial begin
        msg_valid = 0;
        msg_last = 0;
        msg_last_bytes = 0;
        msg_data = 0;
        blk_count = 0;

        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);

        /* ============================================================
              TEST 1: MULTI-BLOCK
           ============================================================ */
        blk_count = 0;
        $display("\nTEST 1: MULTI-BLOCK (>3 blocks)");

        send_word(32'h61626364,0,0);
        send_word(32'h62636465,0,0);
        send_word(32'h63646566,0,0);
        send_word(32'h64656667,0,0);
        send_word(32'h65666768,0,0);
        send_word(32'h66676869,0,0);
        send_word(32'h6768696A,0,0);
        send_word(32'h68696A6B,0,0);
        send_word(32'h696A6B6C,0,0);
        send_word(32'h6A6B6C6D,0,0);
        send_word(32'h6B6C6D6E,0,0);
        send_word(32'h6C6D6E6F,0,0);
        send_word(32'h6D6E6F70,0,0);
        send_word(32'h6E6F7071,1,0);

        repeat(20) @(posedge clk);

        /* ============================================================
              TEST 2: EXACTLY 64 BYTES → 2 BLOCKS
           ============================================================ */
        blk_count = 0;
        $display("\nTEST 2: EXACTLY 64 bytes");

        repeat (16)
            send_word(32'hAAAAAAAA, 0, 0);

        send_word(32'h00000000, 1, 0);

        repeat(30) @(posedge clk);
        $display("EXPECTED BLOCKS = 2");

        /* ============================================================
              TEST 3: 20 BLOCK MESSAGE
           ============================================================ */
        blk_count = 0;
        $display("\nTEST 3: 20 BLOCK MESSAGE");

        repeat (80)
            send_word(32'hBBBBBBBB, 0, 0);

        send_word(32'hCCCCCC00, 1, 3); // last 3 bytes valid

        repeat(60) @(posedge clk);
        $display("EXPECTED BLOCKS = 7");

        /* ============================================================
             TEST 4: 100 BLOCK MESSAGE
           ============================================================ */
        blk_count = 0;
        $display("\nTEST 4: 100 BLOCK MESSAGE");

        repeat (1600)
            send_word(32'hDDDDDDDD, 0, 0);

        send_word(32'h00000000, 1, 0);

        repeat(100) @(posedge clk);
        $display("EXPECTED BLOCKS = 101");

        /* ============================================================
             TEST 5: BACK-TO-BACK MESSAGES
           ============================================================ */
        blk_count = 0;
        $display("\nTEST 5: BACK-TO-BACK");

        repeat (80)
            send_word(32'h11111111,0,0);

        send_word(32'h00000000,1,0);

        repeat (192)
            send_word(32'h22222222,0,0);

        send_word(32'h00000000,1,0);

        repeat(200) @(posedge clk);
        $display("EXPECTED BLOCKS = 19");

        $finish;
    end
endmodule
