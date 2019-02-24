


///=======================================================================================================//


`timescale 1ns/1ps
module sha256_msg_scheduler (
    input           clk_in,
    input           rst_n_in,
    input           block_valid_in,
    input           last_blk,
    input   [511:0] block_in,
/*    output  [31:0]  out_word0_in,
    output  [31:0]  out_word1_in,
    output  [31:0]  out_word2_in,
    output  [31:0]  out_word3_in,*/
    output reg  [127:0] out_words_out,
    output reg temp2,
    output reg          out_valid_out
    
);

    //to identify the last block
    reg temp1;
    
    // FSM states
    localparam IDLE = 2'd0, LOAD = 2'd1, GEN = 2'd2, LAST = 2'd3;
    reg [1:0] state, nxt_state;

    // Sequential FSM
    always @(posedge clk_in or negedge rst_n_in) begin
        if(!rst_n_in)
            state <= IDLE;
        else
            state <= nxt_state;
    end
    
    // Word index
    reg [6:0] t;

    // Next-state logic
    always @(*) begin
        nxt_state = state;
        case(state)
            IDLE:  if(block_valid_in) nxt_state = LOAD;
            LOAD:  nxt_state = GEN;
            GEN:   if(t==7'd60) nxt_state = LAST;
            LAST:  nxt_state = IDLE;
            default: nxt_state = IDLE;
        endcase
    end

    // -------------------------
    // 16-word sliding buffer
    // -------------------------
    reg [31:0] buff [0:15];

    // Circular buffer index
    function [3:0] buf_idx;
        input integer i;
        buf_idx = i[3:0]; // modulo 16
    endfunction

    // SHA small sigma functions
    function [31:0] ROTR(input [31:0] x, input integer n); 
        ROTR = (x >> n) | (x << (32-n)); 
    endfunction

    function [31:0] SHR(input [31:0] x, input integer n);  
        SHR  = x >> n; 
    endfunction

    function [31:0] SIG0(input [31:0] x); 
        SIG0 = ROTR(x,7)^ROTR(x,18)^SHR(x,3); 
    endfunction

    function [31:0] SIG1(input [31:0] x); 
        SIG1 = ROTR(x,17)^ROTR(x,19)^SHR(x,10); 
    endfunction

    // Combinational word generator
    reg [31:0] w0,w1,w2,w3;
    reg [31:0] tmp0,tmp1,tmp2,tmp3;
    always @(*) begin
        if(t < 16) begin
            // load input words
            w0 = buff[buf_idx(t+0)];
            w1 = buff[buf_idx(t+1)];
            w2 = buff[buf_idx(t+2)];
            w3 = buff[buf_idx(t+3)];
//            $display("\tif Msg w0 %h w1 %h w2 %h w3 %h %d %d\t\n", w0,w1,w2,w3,t,buf_idx(t+0));
        end else begin
            // Compute next 4 words using sliding buffer
            tmp0 = SIG1(buff[buf_idx(t-2)]) + buff[buf_idx(t-7)] + SIG0(buff[buf_idx(t-15)]) + buff[buf_idx(t-16)];
            tmp1 = SIG1(buff[buf_idx(t-1)]) + buff[buf_idx(t-6)] + SIG0(buff[buf_idx(t-14)]) + buff[buf_idx(t-15)];
            tmp2 = SIG1(tmp0) + buff[buf_idx(t-5)] + SIG0(buff[buf_idx(t-13)]) + buff[buf_idx(t-14)];
            tmp3 = SIG1(tmp1) + buff[buf_idx(t-4)] + SIG0(buff[buf_idx(t-12)]) + buff[buf_idx(t-13)];

            w0 = tmp0;
            w1 = tmp1;
            w2 = tmp2;
            w3 = tmp3;
//            $display("\telse Msg w0 %h w1 %h w2 %h w3 %h %d %d\t\n", w0,w1,w2,w3,t,buf_idx(t+0));
            
        end
    end
// venkat added it

always @(posedge clk_in or negedge rst_n_in) begin
    if (!rst_n_in)
        temp1 <= 1'b0;
    else if (last_blk)          // temp1 is a 1-cycle pulse
        temp1 <= 1'b1;       // temp2 turns ON and stays ON
    else
        temp1 <= temp1;      // hold value (optional line)
end

    // Sequential datapath
    integer i;
    always @(posedge clk_in or negedge rst_n_in) begin
        //temp1 <= (last_blk)? 1'b1 : 1'b0; //venkat added it
        if(!rst_n_in) begin
            out_words_out <= 128'd0;
      /*      out_word0 <= 32'd0;
            out_word1 <= 32'd0;
            out_word2 <= 32'd0;
            out_word3 <= 32'd0;*/
            out_valid_out <= 1'b0;
            t <= 0;
            for(i=0;i<16;i=i+1)
                buff[i] <= 32'd0;
        end else begin
            out_valid_out <= 1'b0;
            case(state)
              IDLE: begin 
              temp1 <= 0;
              t <= 0; 
            end

                LOAD: begin
                    // Load 16 input words into buffer
                    for(i=0;i<16;i=i+1)
                    begin
                        buff[i] <= block_in[511-32*i -:32];
//                        $display("\t MSG FSM buff[%d] = %h\t\n", i, buff[i]);
                    end
/*                    buff[0] <= block_in[31:0];
                    buff[1] <= block_in[63:32];
                    buff[2] <= block_in[95:64];
                    buff[3] <= block_in[127:96];
                    buff[4] <= block_in[159:128];
                    buff[5] <= block_in[191:160];
                    buff[6] <= block_in[223:192];
                    buff[7] <= block_in[255:224];
                    buff[8] <= block_in[287:256];
                    buff[9] <= block_in[319:288];
                    buff[10] <= block_in[351:320];
                    buff[11] <= block_in[383:352];
                    buff[12] <= block_in[415:384];
                    buff[13] <= block_in[447:416];
                    buff[14] <= block_in[479:448];
                    buff[15] <= block_in[511:480];
                    */
                    t <= 0;
                end

                GEN, LAST: begin
/*                    out_word0 <= w0;
                    out_word1 <= w1;
                    out_word2 <= w2;
                    out_word3 <= w3;*/
                    out_words_out <= {w0,w1,w2,w3};
                    out_valid_out <= 1'b1;

                    // Only write back computed words for t >= 16
                    if(t >= 16) begin
                        buff[buf_idx(t+0)] <= w0;
                        buff[buf_idx(t+1)] <= w1;
                        buff[buf_idx(t+2)] <= w2;
                        buff[buf_idx(t+3)] <= w3;
                    end

                    // Increment t only in GEN
                    if(state==GEN) begin
                      temp2 <= 1'b0;
                      t <= t + 4; end
                    else if ((state == LAST) && temp1)
                      temp2 <= 1'b1;
                end
            endcase
        end
    end

endmodule

