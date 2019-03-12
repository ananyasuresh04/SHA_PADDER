
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

    initial begin
        // init
        rst_n=0; start=0; msg_valid=0; msg_last=0; msg_byte=0;
        #20 rst_n=1;

        // ===== TEST 1 : "a"
        start_msg();
        send(8'h61,1);
        @(posedge block_valid);
        $display("T1 'a'    : %h", block_out);

        // ===== TEST 2 : "ab"
        start_msg();
        send(8'h61,0);
        send(8'h62,1);
        @(posedge block_valid);
        $display("T2 'ab'   : %h", block_out);

        // ===== TEST 3 : "abc"
        start_msg();
        send(8'h61,0);
        send(8'h62,0);
        send(8'h63,1);
        @(posedge block_valid);
        $display("T3 'abc'  : %h", block_out);

        // ===== TEST 4 : "abcd"
        start_msg();
        send(8'h61,0);
        send(8'h62,0);
        send(8'h63,0);
        send(8'h64,1);
        @(posedge block_valid);
        $display("T4 'abcd' : %h", block_out);

        // ===== TEST 5 : "hello"
        start_msg();
        send(8'h68,0);
        send(8'h65,0);
        send(8'h6c,0);
        send(8'h6c,0);
        send(8'h6f,1);
        @(posedge block_valid);
        $display("T5 'hello': %h", block_out);

        #20 $finish;
    end

    // ---- helpers ----
    task start_msg;
        begin
            @(posedge clk); start=1;
            @(posedge clk); start=0;
        end
    endtask

    task send(input [7:0] b, input last);
        begin
            @(posedge clk);
            msg_valid=1; msg_byte=b; msg_last=last;
            @(posedge clk);
            msg_valid=0; msg_last=0;
        end
    endtask

endmodule
 
