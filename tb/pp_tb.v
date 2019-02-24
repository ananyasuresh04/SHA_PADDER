/*
module tb_sha256_top1;

    reg             clk_in;
    reg             rst_n_in;
    reg     [31:0]  msg_data;
    reg             msg_valid;
    reg             msg_last;
    reg     [1:0]   msg_last_bytes;

    wire    [255:0] o_block_512;
    wire            o_block_valid;

    */
   `timescale 1ns / 1ps
    module sha256_padder_tb;

    reg clk_in, rst_n_in, msg_valid, msg_last;
    reg [1:0] msg_last_bytes;
    reg [31:0] msg_data;

    wire [511:0] o_block_512;
    wire o_block_valid;
    wire msg_last_block;

    sha256_padder_fsm dut (
        .clk(clk), .rst_n(rst_n),
        .msg_valid(msg_valid), .msg_last(msg_last),
        .msg_last_bytes(msg_last_bytes), .msg_data(msg_data),
        .o_block_512(o_block_512), .o_block_valid(o_block_valid),
        .msg_last_block(msg_last_block)
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
        msg_data        = 0;
        msg_valid  = 0;
        msg_last   = 0;
        msg_last_bytes  = 0;

        #10;
        rst_n_in = 1;

        // =================================================
        // TEST 1 : "abc"
        // =================================================
        // ASCII: 61 62 63
        // =================================================
        msg_data        = 32'h61626300;
        msg_valid  = 1'b1;
        msg_last   = 1'b1;
        msg_last_bytes  = 2'b11;

        #10;
        msg_valid  = 1'b0;
        //msg_last   = 1'b0;
        msg_last_bytes  = 0;

        #250;

        // =================================================
        // TEST 2 : Two-block message
        // "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
        // =================================================

        // First 16 words
        msg_valid = 1'b1;
        msg_last  = 1'b0;

        msg_data = 32'h61626364; #10;
        msg_data = 32'h62636465; #10;
        msg_data = 32'h63646566; #10;
        msg_data = 32'h64656667; #10;
        msg_data = 32'h65666768; #10;
        msg_data = 32'h66676869; #10;
        msg_data = 32'h6768696A; #10;
        msg_data = 32'h68696A6B; #10;
        msg_data = 32'h696A6B6C; #10;
        msg_data = 32'h6A6B6C6D; #10;
        msg_data = 32'h6B6C6D6E; #10;
        msg_data = 32'h6C6D6E6F; #10;
        msg_data = 32'h6D6E6F70; #10; //msg_last = 1'b1; #10;
        msg_data = 32'h6E6F7071;// #10; //msg_last = 1'b1; #10;
        msg_last  = 1'b1; #10;

        msg_valid = 1'b0;
        #1000;
        msg_last  = 1'b0; #10;

      /*  // Last word of message (no padding here)
        msg_data        = 32'h71727374; // continues message
        msg_valid  = 1'b1;
        msg_last   = 1'b1;
        msg_last_bytes  = 2'b11;

        #10;
        msg_valid = 1'b0;
       // msg_last  = 1'b0;
        msg_last_bytes = 0;

        #250;
        msg_last   = 1'b0;*/
/*
        // =================================================
        // TEST 3 : Long stream ("a" repeated)
        // =================================================
        for (i = 0; i < (15625 * 16); i = i + 1) begin
            msg_data        = 32'h61616161;
            msg_valid  = 1'b1;
            //msg_last   = 1'b0;
            msg_last_bytes  = 0;
            if(i == 15624) msg_last = 1;
            else msg_last = 0;
            #10;
            //msg_valid  = 1'b0;
            
            //#190;
        end

        // Final partial word
        //msg_data        = 32'h61000000;
       // msg_valid  = 1'b1;
        msg_last   = 1'b1;
        //msg_last_bytes  = 2'b01; // 1 valid byte

        #10;
        msg_valid = 1'b0;
//        msg_last  = 1'b0;
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
            "T=%0t | out_valid=%b | pad_out=%h | last_blk=%b",
            $time, o_block_valid, o_block_512, msg_last_block
        );
        $shm_open("padder.shm");
        $shm_probe("ACTMF");
    end

endmodule
