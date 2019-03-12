module word_tb;
reg clk;
reg rst;
reg msg_start;
reg word_en;
//reg msg_stall;
wire [4:0] word_cnt;
wire block_full;
wire space_left;

word_counter dut(.clk(clk),
                 .rst(rst),
                 .msg_start(msg_start),
                .word_en(word_en),
               // .msg_stall(msg_stall),
                .word_cnt(word_cnt),
                .block_full(block_full),
                .space_left(space_left));

             initial begin
                 $shm_open("word_counter.shm");
                 $shm_probe("ACTMF");
             end

             always begin
                 clk = 0;
                 forever #5 clk = ~clk;
             end

             initial begin
                 rst = 1'b1;
#10
                rst = 1'b0;
#10
                msg_start = 1'b0;
#10
               // msg_stall = 1'b0;
#10
                word_en = 1'b1;
#50
                msg_start = 1'b1;
#10
                word_en = 1'b0;
              //  msg_stall = 1'b1;
                
#200
$finish();
             end
endmodule
