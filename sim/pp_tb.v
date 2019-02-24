`timescale 1ns/1ps

module sha256_padder_tb;

    reg         clk;
    reg         rst_n;

    reg         msg_valid;
    reg         msg_last;
    reg [1:0]   msg_last_bytes;
    reg [31:0]  msg_data;

    wire [511:0] o_block_512;
    wire         o_block_valid;
    wire         msg_last_block;
    wire         stall;

    // DUT
    sha256_padder_fsm dut (
        .clk(clk),
        .rst_n(rst_n),
        .msg_valid(msg_valid),
        .msg_last(msg_last),
        .msg_last_bytes(msg_last_bytes),
        .msg_data(msg_data),
        .o_block_512(o_block_512),
        .o_block_valid(o_block_valid),
        .msg_last_block(msg_last_block),
        .stall(stall)
    );

    // ----------------------------
    // Clock generation
    // ----------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end
    initial begin
        $shm_open("padder.shm");
        $shm_probe("ACTMF");
    end
    // ----------------------------
    // Helpers
    // ----------------------------

    task wait_not_stall;
        begin
            while (stall == 1'b1) begin
                @(posedge clk);
            end
        end
    endtask

    task send_word;
        input [31:0] wdata;
        input        is_last;
        input [1:0]  last_bytes;
        begin
            wait_not_stall();

            @(posedge clk);
            msg_valid      <= 1'b1;
            msg_data       <= wdata;
            msg_last       <= is_last;
            msg_last_bytes <= last_bytes;

            @(posedge clk);
            msg_valid      <= 1'b0;
            msg_data       <= 32'd0;
            msg_last       <= 1'b0;
            msg_last_bytes <= 2'd0;
        end
    endtask

    // print block
    task print_block;
        input [511:0] blk;
        input         lastflag;
        begin
            $display("--------------------------------------------------");
            $display("Time=%0t ns : BLOCK VALID", $time);
            $display("msg_last_block = %0d", lastflag);
            $display("BLOCK = %h", blk);
            $display("--------------------------------------------------");
        end
    endtask

    // ----------------------------
    // Monitor output blocks
    // ----------------------------
    integer block_count;

    always @(posedge clk) begin
        if (o_block_valid) begin
            block_count = block_count + 1;
            print_block(o_block_512, msg_last_block);
        end
    end

    // ----------------------------
    // Reset + main stimulus
    // ----------------------------
    initial begin
        // init
        msg_valid      = 0;
        msg_last       = 0;
        msg_last_bytes = 0;
        msg_data       = 0;

        block_count = 0;

        // reset
        rst_n = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;

        $display("\n===============================");
        $display("TEST 1: Small message (1 block)");
        $display("===============================\n");

        // Message = 2 words = 8 bytes
        // W0 = 0x61626364 ("abcd")
        // W1 = 0x65666768 ("efgh") last full word
        send_word(32'h61626364, 1'b0, 2'd0);
        send_word(32'h65666768, 1'b1, 2'd0);

        // Wait for padder output
        repeat(10) @(posedge clk);

        $display("\n===============================");
        $display("TEST 2: Spillover message (2 blocks)");
        $display("===============================\n");

        // Spillover case:
        // Need last word such that padding+len doesn't fit.
        // Easiest: fill full block (16 words) and last word full.
        //
        // That forces extra block for length.
        //
        // Send 16 words, last one msg_last=1.
        // total = 16*4 = 64 bytes => spillover required.

        send_word(32'h00000001, 1'b0, 2'd0);
        send_word(32'h00000002, 1'b0, 2'd0);
        send_word(32'h00000003, 1'b0, 2'd0);
        send_word(32'h00000004, 1'b0, 2'd0);
        send_word(32'h00000005, 1'b0, 2'd0);
        send_word(32'h00000006, 1'b0, 2'd0);
        send_word(32'h00000007, 1'b0, 2'd0);
        send_word(32'h00000008, 1'b0, 2'd0);
        send_word(32'h00000009, 1'b0, 2'd0);
        send_word(32'h0000000A, 1'b0, 2'd0);
        send_word(32'h0000000B, 1'b0, 2'd0);
        send_word(32'h0000000C, 1'b0, 2'd0);
        send_word(32'h0000000D, 1'b0, 2'd0);
        send_word(32'h0000000E, 1'b0, 2'd0);
        send_word(32'h0000000F, 1'b0, 2'd0);
        send_word(32'h00000010, 1'b1, 2'd0); // last full word

        // Wait for 2 blocks
        repeat(30) @(posedge clk);

        $display("\n===============================");
        $display("TEST 3: Last word has 1 byte valid");
        $display("===============================\n");

        // Example:
        // word0 = 0x11223344
        // word1 = 0xAA000000 but only 1 byte valid => AA
        send_word(32'h11223344, 1'b0, 2'd0);
        send_word(32'hAA000000, 1'b1, 2'd1);

        repeat(20) @(posedge clk);

        $display("\n===============================");
        $display("ALL TESTS DONE");
        $display("Total blocks emitted = %0d", block_count);
        $display("===============================\n");

        $finish;
    end

endmodule

