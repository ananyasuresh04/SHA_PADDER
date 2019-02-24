`timescale 1ns/1ps

module tb_sha256_top1;

    reg             clk_in;
    reg             rst_n_in;
    reg     [31:0]  block_in;
    reg             block_valid_in;
    reg             last_block_in;
    reg     [1:0]   msg_last_bytes;

    wire    [255:0] digest_out;
    wire            digest_valid_out;
   // wire stall;
    // -------------------------------------------------
    // DUT
    // -------------------------------------------------
    sha256_top1 dut (
        .clk_in(clk_in),
        .rst_n_in(rst_n_in),
        .block_in(block_in),
        .block_valid_in(block_valid_in),
        .last_block_in(last_block_in),
        .msg_last_bytes(msg_last_bytes),
        .digest_out(digest_out),
        //.stall(stall),
        .digest_valid_out(digest_valid_out)
    );

    integer i;

    // -------------------------------------------------
    // Clock
    // -------------------------------------------------
    initial begin
        clk_in = 1'b0;
        forever #5 clk_in = ~clk_in;
    end

    // -------------------------------------------------
    // Stimulus
    // -------------------------------------------------
    initial begin
        rst_n_in        = 0;
        block_in        = 0;
        block_valid_in  = 0;
        last_block_in   = 0;
        msg_last_bytes  = 0;

        #10;
        rst_n_in = 1;

        // =================================================
        // TEST 1 : "abc"
        // =================================================
        // ASCII: 61 62 63
        // =================================================
        block_in        = 32'h61626300;
        block_valid_in  = 1'b1;
        last_block_in   = 1'b1;
        msg_last_bytes  = 2'b11;

        #10;
        block_valid_in  = 1'b0;
        last_block_in   = 1'b0;
        msg_last_bytes  = 0;

        #250;

        // =================================================
        // TEST 2 : Two-block message
        // "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
        // =================================================

        // First 16 words
        block_valid_in = 1'b1;
        last_block_in  = 1'b0;

        block_in = 32'h61626364; #10;
        block_in = 32'h62636465; #10;
        block_in = 32'h63646566; #10;
        block_in = 32'h64656667; #10;
        block_in = 32'h65666768; #10;
        block_in = 32'h66676869; #10;
        block_in = 32'h6768696A; #10;
        block_in = 32'h68696A6B; #10;
        block_in = 32'h696A6B6C; #10;
        block_in = 32'h6A6B6C6D; #10;
        block_in = 32'h6B6C6D6E; #10;
        block_in = 32'h6C6D6E6F; #10;
        block_in = 32'h6D6E6F70; #10; //last_block_in = 1'b1; #10;
        block_in = 32'h6E6F7071;// #10; //last_block_in = 1'b1; #10;
        last_block_in  = 1'b1; #10;
        last_block_in  = 1'b0; #10;

        block_valid_in = 1'b0;
        #1000;
        last_block_in  = 1'b0; #10;

      /*  // Last word of message (no padding here)
        block_in        = 32'h71727374; // continues message
        block_valid_in  = 1'b1;
        last_block_in   = 1'b1;
        msg_last_bytes  = 2'b11;

        #10;
        block_valid_in = 1'b0;
       // last_block_in  = 1'b0;
        msg_last_bytes = 0;

        #250;
        last_block_in   = 1'b0;*/
/*
        // =================================================
        // TEST 3 : Long stream ("a" repeated)
        // =================================================
        for (i = 0; i < (15625 * 16); i = i + 1) begin
            block_in        = 32'h61616161;
            block_valid_in  = 1'b1;
            //last_block_in   = 1'b0;
            msg_last_bytes  = 0;
            if(i == 15624) last_block_in = 1;
            else last_block_in = 0;
            #10;
            //block_valid_in  = 1'b0;
            
            //#190;
        end

        // Final partial word
        //block_in        = 32'h61000000;
       // block_valid_in  = 1'b1;
        last_block_in   = 1'b1;
        //msg_last_bytes  = 2'b01; // 1 valid byte

        #10;
        block_valid_in = 1'b0;
//        last_block_in  = 1'b0;
        msg_last_bytes = 0;
*/
        #200;
        $finish;
    end

    // -------------------------------------------------
    // Monitor
    // -------------------------------------------------
    initial begin
        $monitor(
            "T=%0t | digest_valid=%b | digest=%h",
            $time, digest_valid_out, digest_out
        );
        $shm_open("sha256_with_padder.shm");
        $shm_probe("ACTMF");
    end

endmodule

