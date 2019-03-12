`timescale 1ns/1ps

module tb_sha256_padder;

    reg clk;
    reg reset;
    reg msg_valid;
    reg msg_last;
    reg [31:0] msg_word;
    reg [1:0]  last_bytes;

    wire [511:0] block_out;
    wire block_valid;
    wire final_block;

    sha256_padder_top dut (
        .clk(clk),
        .reset(reset),
        .msg_valid(msg_valid),
        .msg_last(msg_last),
        .msg_word(msg_word),
        .last_bytes(last_bytes),
        .block_out(block_out),
        .block_valid(block_valid),
        .final_block(final_block)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        msg_valid = 0;
        msg_last  = 0;
        msg_word  = 0;
        last_bytes = 0;

        #20 reset = 0;

        // =====================================================
        // TEST 1 : "abc"
        // =====================================================
        $display("\n==============================");
        $display("TEST 1 : abc");
        $display("==============================");

        @(posedge clk);
        msg_valid  = 1;
        msg_last   = 1;
        msg_word   = 32'h61626300;
        last_bytes = 2'd3;

        // ?? CRITICAL FIX: hold valid for 2 cycles
        @(posedge clk);
        @(posedge clk);

        msg_valid = 0;
        msg_last  = 0;

        @(posedge block_valid);
        $display("BLOCK : %h", block_out);
        $display("FINAL : %0d", final_block);

        // =====================================================
        // RESET
        // =====================================================
        $display("\n--- RESET DUT ---\n");
        reset = 1;
        #20 reset = 0;

        // =====================================================
        // TEST 2 : OVERFLOW
        // =====================================================
        $display("==============================");
        $display("TEST 2 : OVERFLOW");
        $display("==============================");

        // 14 FULL WORDS
        @(posedge clk);
        msg_valid = 1;
        msg_last  = 0;
        last_bytes = 0;

        msg_word = 32'hAAAAAAAA; @(posedge clk);
        msg_word = 32'hAAAAAAAA; @(posedge clk);
        msg_word = 32'hAAAAAAAA; @(posedge clk);
        msg_word = 32'hAAAAAAAA; @(posedge clk);
        msg_word = 32'hAAAAAAAA; @(posedge clk);
        msg_word = 32'hAAAAAAAA; @(posedge clk);
        msg_word = 32'hAAAAAAAA; @(posedge clk);
        msg_word = 32'hAAAAAAAA; @(posedge clk);
        msg_word = 32'hAAAAAAAA; @(posedge clk);
        msg_word = 32'hAAAAAAAA; @(posedge clk);
        msg_word = 32'hAAAAAAAA; @(posedge clk);
        msg_word = 32'hAAAAAAAA; @(posedge clk);
        msg_word = 32'hAAAAAAAA; @(posedge clk);
        msg_word = 32'hAAAAAAAA; @(posedge clk);

        // PARTIAL WORD (OVERFLOW)
        msg_word   = 32'hBBBB0000;
        msg_last   = 1;
        last_bytes = 2'd2;

        @(posedge clk);
        @(posedge clk);

        msg_valid = 0;
        msg_last  = 0;

        // BLOCK 1
        @(posedge block_valid);
        $display("BLOCK 1 : %h", block_out);
        $display("FINAL   : %0d", final_block);

        // BLOCK 2
        @(posedge block_valid);
        $display("BLOCK 2 : %h", block_out);
        $display("FINAL   : %0d", final_block);

        $display("\nALL TESTS DONE");
        #20 $finish;
    end
endmodule

