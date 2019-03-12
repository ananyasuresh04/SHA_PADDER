`timescale 1ns/1ps

 

module tb_padder_top;

    reg clk = 0;
    reg rst = 1;

    reg [31:0] msg_in = 0;
    reg        msg_start = 0;
    reg        msg_valid = 0;
    reg        msg_end   = 0;
    reg [2:0]  valid_bytes = 0;

    wire [511:0] block_out;
    wire         padder_block_valid;

    // DUT
    padder_top DUT (
        .clk(clk),
        .rst(rst),
        .msg_in(msg_in),
        .msg_start(msg_start),
        .msg_valid(msg_valid),
        .msg_end(msg_end),
        .valid_bytes(valid_bytes),
        .block_out(block_out),
        .padder_block_valid(padder_block_valid)
    );

    // Clock
    always #5 clk = ~clk;

    // MONITOR
    initial begin
        $monitor("TIME=%0t | VALID=%0d | OUT=%h",
                 $time, padder_block_valid, block_out);
    end

    // TEST SEQUENCE
    initial begin

        // RESET
        rst = 1;
        #20;
        rst = 0;

        // ----------------------------------------------------
        // SEND MESSAGE OF 3 WORDS (example message)
        // ----------------------------------------------------

        // WORD 0
        msg_start = 1;
        msg_valid = 1;
        msg_in = 32'h11223344;
        valid_bytes = 3'd4;
        #10;

        msg_start = 0;

        // WORD 1
      /*  msg_in = 32'hAABBCCDD;
        msg_valid = 1;
        valid_bytes = 3'd4;
        #10;

        // WORD 2
        msg_in = 32'h55667788;
        msg_valid = 1;
        valid_bytes = 3'd4;
        #10;

        // END
        msg_valid = 0;
        msg_end = 1;
        #10;

        msg_end = 0;*/

        // allow padding + length insertion + output
        #200;

        $display("\n==============================================");
        $display(" FINAL BLOCK OUT  = %h", block_out);
        $display(" FINAL VALID FLAG = %d", padder_block_valid);
        $display("==============================================\n");

        $finish;
    end

endmodule
