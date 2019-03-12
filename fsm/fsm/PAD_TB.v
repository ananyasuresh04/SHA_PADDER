
`timescale 1ns/1ps

module padder_tb;

    reg clk = 0;
    always #5 clk = ~clk;

    reg rst_n;
    reg start;
    reg msg_valid;
    reg msg_last;
    reg [7:0] msg_byte;

    wire [511:0] block_out;
    wire block_valid;
    wire final_block;

    padder_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .msg_valid(msg_valid),
        .msg_last(msg_last),
        .msg_byte(msg_byte),
        .block_out(block_out),
        .block_valid(block_valid),
        .final_block(final_block)
    );

    // --------------------------------------------------
    initial begin
        rst_n = 0;
        start = 0;
        msg_valid = 0;
        msg_last = 0;
        msg_byte = 0;

        #20 rst_n = 1;

        // ==========================
        run_test_1byte();
/*        run_test_2byte();
        run_test_3byte();
        run_test_4byte();
        run_test_hello();
        run_test_empty();
        run_test_55bytes();*/
        // ==========================

        #50 $finish;
    end

    // --------------------------------------------------
    // TASKS
    // --------------------------------------------------

    task start_msg;
        begin
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
        end
    endtask

    task send_byte(input [7:0] b, input last);
        begin
            @(posedge clk);
            msg_valid = 1;
            msg_byte  = b;
            msg_last  = last;
            @(posedge clk);
            msg_valid = 0;
            msg_last  = 0;
        end
    endtask

    task show_block(input [127:0] name);
        begin
            @(posedge block_valid);
            $display("\n==============================");
            $display("TESTCASE : %s", name);
            $display("%h", block_out[511:480]);
            $display("%h", block_out[479:448]);
            $display("%h", block_out[447:416]);
            $display("%h", block_out[415:384]);
            $display("%h", block_out[383:352]);
            $display("%h", block_out[351:320]);
            $display("%h", block_out[319:288]);
            $display("%h", block_out[287:256]);
            $display("%h", block_out[255:224]);
            
            $display("%h", block_out[223:192]);
            
            $display("%h", block_out[191:160]);
            
            $display("%h", block_out[159:128]);
            $display("%h", block_out[127:96]);
            $display("%h", block_out[95:64]);

            $display("%h", block_out[63:32]);
            $display("%h", block_out[31:0]);
            $display("FINAL BLOCK = %0d", final_block);
            $display("==============================\n");
        end
    endtask

    // --------------------------------------------------
    // TESTCASES
    // --------------------------------------------------

    task run_test_1byte;
        begin
            start_msg();
            send_byte(8'h61, 0); // "a"
//             send_byte(8'h61, 0);
            send_byte(8'h62, 0);
            send_byte(8'h63, 1);
            show_block("abc");
        end
    endtask

    task run_test_2byte;
        begin
            start_msg();
            send_byte(8'h61, 0);
            send_byte(8'h62, 1); // "ab"
            show_block("ab");
        end
    endtask

    task run_test_3byte;
        begin
            start_msg();
            send_byte(8'h61, 0);
            send_byte(8'h62, 0);
            send_byte(8'h63, 1); // "abc"
            show_block("abc");
        end
    endtask

    task run_test_4byte;
        begin
            start_msg();
            send_byte(8'h61, 0);
            send_byte(8'h62, 0);
            send_byte(8'h63, 0);
            send_byte(8'h64, 1); // "abcd"
            show_block("abcd");
        end
    endtask

    task run_test_hello;
        begin
            start_msg();
            send_byte(8'h68, 0);
            send_byte(8'h65, 0);
            send_byte(8'h6c, 0);
            send_byte(8'h6c, 0);
            send_byte(8'h6f, 1); // "hello"
            show_block("hello");
        end
    endtask

    task run_test_empty;
        begin
            start_msg();
            show_block("empty message");
        end
    endtask

    task run_test_55bytes;
        integer i;
        begin
            start_msg();
            for (i = 0; i < 54; i = i + 1)
                send_byte(8'h41, 0); // 'A'
            send_byte(8'h41, 1);     // last byte
            show_block("55 bytes");
        end
    endtask


    initial
    begin
        $shm_open("padd_sha.shm");
        $shm_probe("ACTMF");
    end

endmodule


