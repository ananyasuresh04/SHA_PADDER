module tb_word_counter;
    reg clk = 0, rst_n = 0, padder_start, shift_en;
    wire [4:0] word_cnt;

    word_counter dut (clk, rst_n, padder_start, shift_en, word_cnt);
    always #5 clk = ~clk;

    initial begin
        rst_n = 0; padder_start = 0; shift_en = 0;
        #20 rst_n = 1;

        padder_start = 1; #10 padder_start = 0;
        repeat (5) begin shift_en = 1; #10; end
        shift_en = 0;

        $display("WORD_CNT = %d", word_cnt);
        $finish;
    end
endmodule
