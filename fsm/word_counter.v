
module word_counter (
    input  wire clk,
    input  wire rst_n,
    input  wire padder_start,
    input  wire shift_en,
    output reg  [4:0] word_cnt
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || padder_start)
            word_cnt <= 0;
        else if (shift_en)
            word_cnt <= word_cnt + 1;
    end
endmodule
