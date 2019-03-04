module tb_byte_counter;

    reg clk = 0;
    reg rst_n = 0;
    reg padder_start;
    reg msg_valid;
    reg msg_last;
    reg [1:0] msg_last_bytes;

    wire [63:0] byte_cnt;

    byte_counter dut (
        .clk(clk),
        .rst_n(rst_n),
        .padder_start(padder_start),
        .msg_valid(msg_valid),
        .msg_last(msg_last),
        .msg_last_bytes(msg_last_bytes),
        .byte_cnt(byte_cnt)
    );

    always #5 clk = ~clk;

    initial begin
        // init
        padder_start = 0;
        msg_valid = 0;
        msg_last = 0;
        msg_last_bytes = 0;

        // reset
        #10 rst_n = 0;
        #10 rst_n = 1;

        // start message
        padder_start = 1;
        #10 padder_start = 0;

        // word 1 (4 bytes)
        msg_valid = 1;
        msg_last = 0;
        #10;

        // word 2 (4 bytes)
        msg_valid = 1;
        msg_last = 0;
        #10;

        // last word (3 bytes: "abc")
        msg_valid = 1;
        msg_last = 1;
        msg_last_bytes = 3;
        #10;

        msg_valid = 0;
        msg_last = 0;

        #10;
        $display("BYTE_CNT = %0d", byte_cnt);
        $finish;
    end

endmodule
