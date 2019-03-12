module tb_length_gen;
    reg [63:0] byte_cnt;
    wire [31:0] hi, lo;

    length_gen dut (byte_cnt, hi, lo);

    initial begin
        byte_cnt = 3;
        #10 $display("LEN = %h_%h", hi, lo);
        $finish;
    end
endmodule
