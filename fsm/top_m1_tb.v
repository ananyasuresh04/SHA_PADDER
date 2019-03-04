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

    // DUT
 /*   sha256_padding_top dut (
        .clk(clk),
        .reset(reset),
        .msg_valid(msg_valid),
        .msg_last(msg_last),
        .msg_data(msg_data),
        .valid_bytes(valid_bytes),
        .padded_block(padded_block),
        .block_ready(block_ready)
    );*/
   sha256_padding_top dut(.*);

    // Clock
    always #5 clk = ~clk;

    initial begin
        // ---------------- INIT ----------------
        clk = 0;
        reset = 1;
        msg_valid = 0;
        msg_last  = 0;
        msg_data  = 0;
        valid_bytes = 0;

        #20;
        reset = 0;

        // ======================================================
        // TEST CASE 1 : "abc"
        // ======================================================
        $display("\n==============================");
        $display("TEST 1 : abc");
        $display("==============================");

        #10;
        msg_valid = 1;
        msg_last  = 1;
        msg_data  = 32'h61626300;   // "abc"
        valid_bytes = 2'b11;        // 3 bytes valid

        #10;
        msg_valid = 0;
        msg_last  = 0;

        // Wait manually for output (fixed delay, no while)
        #200;

        if (block_ready) begin
            $display("BLOCK  : %h", padded_block);
        end else begin
            $display("ERROR : block_ready not asserted");
        end

        // ======================================================
        // RESET BEFORE NEXT TEST (VERY IMPORTANT)
        // ======================================================
        $display("\n--- RESET DUT ---\n");
        reset = 1;
        #20;
        reset = 0;

        // ======================================================
        // TEST CASE 2 : OVERFLOW (message > 13 words)
        // ======================================================
        $display("==============================");
        $display("TEST 2 : OVERFLOW");
        $display("==============================");

        // ---- Word 0
        #10; msg_valid=1; msg_data=32'hAAAAAAAA; msg_last=0; valid_bytes=0;
        #10;

        // ---- Word 1
        msg_data=32'hAAAAAAAA; #10;

        // ---- Word 2
        msg_data=32'hAAAAAAAA; #10;

        // ---- Word 3
        msg_data=32'hAAAAAAAA; #10;

        // ---- Word 4
        msg_data=32'hAAAAAAAA; #10;

        // ---- Word 5
        msg_data=32'hAAAAAAAA; #10;

        // ---- Word 6
        msg_data=32'hAAAAAAAA; #10;

        // ---- Word 7
        msg_data=32'hAAAAAAAA; #10;

        // ---- Word 8
        msg_data=32'hAAAAAAAA; #10;

        // ---- Word 9
        msg_data=32'hAAAAAAAA; #10;

        // ---- Word 10
        msg_data=32'hAAAAAAAA; #10;

        // ---- Word 11
        msg_data=32'hAAAAAAAA; #10;

        // ---- Word 12
        msg_data=32'hAAAAAAAA; #10;

        // ---- Word 13
        msg_data=32'hAAAAAAAA; #10;

        // ---- Last partial word (overflow trigger)
        msg_data=32'hBBBB0000;
        msg_last = 1;
        valid_bytes = 2'b10;   // 2 bytes valid
        #10;

        msg_valid = 0;
        msg_last  = 0;

        // -------- BLOCK 1 (NO LENGTH)
        #200;
        if (block_ready)
            $display("BLOCK 1: %h", padded_block);
        else
            $display("ERROR : BLOCK 1 not generated");

        // -------- BLOCK 2 (LENGTH BLOCK)
        #200;
        if (block_ready)
            $display("BLOCK 2: %h", padded_block);
        else
            $display("ERROR : BLOCK 2 not generated");

        // ======================================================
        $display("\nALL TESTS DONE");
        $finish;
    end
endmodule

