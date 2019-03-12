`timescale 1ns/1ps

module tb_sha256;

    reg clk = 0;
    reg reset;
    reg msg_valid, msg_last;
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

    // PRINT BLOCKS EXACTLY ON VALID
    always @(posedge clk) begin
        if (block_valid) begin
            $display("BLOCK = %h", block_out);
            $display("FINAL = %0d", final_block);
        end
    end

    initial begin
        // INIT
        reset = 1;
        msg_valid = 0;
        msg_last  = 0;
        msg_word  = 0;
        last_bytes = 0;

        #20 reset = 0;

        // =====================================================
        // TEST 1 : "abc"
        // =====================================================
        $display("TEST 1 : abc");
        #10;
        msg_valid  = 1;
        msg_last   = 1;
        msg_word   = 32'h61626300;
        last_bytes = 2'd3;

        #10;
        msg_valid = 0;
        msg_last  = 0;

        // RESET BETWEEN TESTS
        #40;
        reset = 1;
        #20;
        reset = 0;

        // =====================================================
        // TEST 2 : OVERFLOW
        // =====================================================
        $display("TEST 2 : OVERFLOW");

        // 14 full words
        #10 msg_valid = 1;
        msg_word = 32'h41414141;
        last_bytes = 0;
        msg_last = 0;

        #140; // 14 words × 10ns

        // partial last word
        msg_last   = 1;
        msg_word   = 32'h42420000;
        last_bytes = 2'd2;

        #10;
        msg_valid = 0;
        msg_last  = 0;

        #100;
        $finish;
    end
endmodule

