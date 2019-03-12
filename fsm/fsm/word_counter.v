/*module word_counter(
    input clk,
    input rst,
    input msg_start,
    input word_en,
   // input msg_stall,
    output reg [4:0] word_cnt,
    output block_full,
    output space_left );

always@(posedge clk or posedge rst)
begin
        if(rst) begin
            word_cnt = 1'd0;
        end
        else begin
                    if (word_en)
                    begin
                        word_cnt = word_cnt + 1'd1;
                    end

                   else if(msg_start)
                    begin
                       word_cnt = 'd0;
                    end
                 /*  else if ( msg_stall)
                    begin
                        word_cnt = word_cnt;
                    end
        end
    end
        assign block_full = (word_cnt == 5'd15);
        assign space_left = 5'd16 - word_cnt - 5'd1;
endmodule*/
`timescale 1ns/1ps

module word_counter (
    input  wire clk,
    input  wire rst,
    input  wire msg_start,
    input  wire word_en,
    input  wire msg_stall,

    output reg [4:0] word_count,
    output wire      block_full,
    output wire [4:0] space_left
);

    always @(posedge clk) begin
        if (rst || msg_start)
            word_count <= 5'd0;
        else if (!msg_stall && word_en)
            word_count <= word_count + 5'd1;
    end

    assign block_full = (word_count == 5'd15);
    assign space_left = 5'd16 - word_count - 5'd1;

endmodule

