`timescale 1ns/1ps

module tb_sha256_padder;

    reg clk;
    reg reset;
    reg msg_valid;
    reg msg_last;
    reg [31:0] msg_data;
    reg [1:0] valid_bytes;

    wire [511:0] padded_block;
    wire block_ready;

    sha256_padder_top dut (
        .clk(clk),
        .reset(reset),
        .msg_valid(msg_valid),
        .msg_last(msg_last),
        .msg_data(msg_data),
        .valid_bytes(valid_bytes),
        .padded_block(padded_block),
        .block_ready(block_ready)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        msg_valid = 0;
        msg_last  = 0;
        msg_data  = 0;
        valid_bytes = 0;

        #20 reset = 0;

        // ======================================================
        // TEST 1 : "abc"
        // ======================================================
        $display("\n==============================");
        $display("TEST 1 : abc");
        $display("==============================");

        @(posedge clk);
        msg_valid = 1;
        msg_last  = 1;
        msg_data  = 32'h61626300;
        valid_bytes = 2'b11;

        @(posedge clk);
        msg_valid = 0;
        msg_last  = 0;

        // ? CORRECT WAY TO WAIT FOR OUTPUT
        @(posedge block_ready);
        $display("BLOCK  : %h", padded_block);

        // ======================================================
        // RESET BETWEEN TESTS (MANDATORY)
        // ======================================================
        $display("\n--- RESET DUT ---\n");
        reset = 1;
        #20 reset = 0;

        // ======================================================
        // TEST 2 : OVERFLOW (> 13 words)
        // ======================================================
        $display("==============================");
        $display("TEST 2 : OVERFLOW");
        $display("==============================");

        // 14 FULL WORDS
        @(posedge clk); msg_valid=1; msg_data=32'hAAAAAAAA; msg_last=0; valid_bytes=0;
        @(posedge clk); msg_data=32'hAAAAAAAA;
        @(posedge clk); msg_data=32'hAAAAAAAA;
        @(posedge clk); msg_data=32'hAAAAAAAA;
        @(posedge clk); msg_data=32'hAAAAAAAA;
        @(posedge clk); msg_data=32'hAAAAAAAA;
        @(posedge clk); msg_data=32'hAAAAAAAA;
        @(posedge clk); msg_data=32'hAAAAAAAA;
        @(posedge clk); msg_data=32'hAAAAAAAA;
        @(posedge clk); msg_data=32'hAAAAAAAA;
        @(posedge clk); msg_data=32'hAAAAAAAA;
        @(posedge clk); msg_data=32'hAAAAAAAA;
        @(posedge clk); msg_data=32'hAAAAAAAA;
        @(posedge clk); msg_data=32'hAAAAAAAA;

        // LAST PARTIAL WORD (OVERFLOW TRIGGER)
        @(posedge clk);
        msg_data = 32'hBBBB0000;
        msg_last = 1;
        valid_bytes = 2'b10;

        @(posedge clk);
        msg_valid = 0;
        msg_last  = 0;

        // -------- BLOCK 1 (NO LENGTH)
        @(posedge block_ready);
        $display("BLOCK 1: %h", padded_block);

        // -------- BLOCK 2 (LENGTH BLOCK)
        @(posedge block_ready);
        $display("BLOCK 2: %h", padded_block);

        $display("\nALL TESTS DONE");
        $finish;
    end
endmodule

