// Code your design here

`timescale 1ns/1ps

//`include "sha256_mux16_1.v"

module sha256_msg_schedule_top(
  input clk_in,
  input rst_n_in,
  input [511:0] block_data_in,
  input 		block_valid_in,
  output reg [127:0] msg_data_out,
  output reg		 msg_valid_out
);
  
  reg [31:0] buff [0:15];
  
//  wire sel0,sel1,sel2,sel3,sel4,sel5,sel6,sel7,sel8,sel9,sel10;
  wire [31:0] w0,w1,w2,w3;
  wire [31:0] temp0,temp1,temp2,temp3,temp4,temp5,temp6,temp7,temp8,temp9,temp10;
  
  
  localparam IDLE = 2'd0, LOAD = 2'd1, GEN = 2'd2, LAST = 2'd3;
    reg [1:0] state, nxt_state;
  
  integer i;
      // Word index
    reg [6:0] t;

    // Sequential FSM
    always @(posedge clk_in or negedge rst_n_in) begin
        if(!rst_n_in)
            state <= IDLE;
        else
            state <= nxt_state;
      
      if(!rst_n_in) begin
            msg_data_out <= 128'd0;
            msg_valid_out <= 1'b0;
            t <= 0;
            for(i=0;i<16;i=i+1)
                buff[i] <= 32'd0;
        end else begin
            msg_valid_out <= 1'b0;
            case(state)
                IDLE: t <= 0;

                LOAD: begin
                    // Load 16 input words into buffer
                    for(i=0;i<16;i=i+1)
                    begin
                      buff[i] <= block_data_in[511-32*i -:32];
//                        $display("\t MSG FSM buff[%d] = %h\t\n", i, buff[i]);
                    end

                    t <= 0;
                end

                GEN, LAST: begin
/*                    out_word0 <= w0;
                    out_word1 <= w1;
                    out_word2 <= w2;
                    out_word3 <= w3;*/
                    msg_data_out <= {w0,w1,w2,w3};
                    msg_valid_out <= 1'b1;

                    // Only write back computed words for t >= 16
                    if(t >= 16) begin
                        buff[buf_idx(t+0)] <= w0;
                        buff[buf_idx(t+1)] <= w1;
                        buff[buf_idx(t+2)] <= w2;
                        buff[buf_idx(t+3)] <= w3;
                    end

                    // Increment t only in GEN
                    if(state==GEN)
                        t <= t + 4;
                end
            endcase
        end
    end



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


//  assign sel10 = t<16 ? buff[t-16] : buff;
  
  wire [3:0] sel_t16 = t<16 ? buf_idx(t+0) : buf_idx(t - 7'd16);
  wire [3:0] sel_t15 = t<16 ? buf_idx(t+1) : buf_idx(t - 7'd15);
  wire [3:0] sel_t14 = t<16 ? buf_idx(t+2) : buf_idx(t - 7'd14);
  wire [3:0] sel_t13 = t<16 ? buf_idx(t+3) : buf_idx(t - 7'd13);
  wire [3:0] sel_t12 = (t - 7'd12) & 4'hF;
  
  wire [3:0] sel_t7  = (t - 7'd7 ) & 4'hF;
  wire [3:0] sel_t6  = (t - 7'd6 ) & 4'hF;
  wire [3:0] sel_t5  = (t - 7'd5 ) & 4'hF;
  wire [3:0] sel_t4  = (t - 7'd4 ) & 4'hF;
  
  wire [3:0] sel_t2  = (t - 7'd2 ) & 4'hF;
  wire [3:0] sel_t1  = (t - 7'd1 ) & 4'hF;

  
  mux16_1 MUX_1(
    .w0_in(buff[0]),
    .w1_in(buff[1]),
    .w2_in(buff[2]),
    .w3_in(buff[3]),
    .w4_in(buff[4]),
    .w5_in(buff[5]),
    .w6_in(buff[6]),
    .w7_in(buff[7]),
    .w8_in(buff[8]),
    .w9_in(buff[9]),
    .w10_in(buff[10]),
    .w11_in(buff[11]),
    .w12_in(buff[12]),
    .w13_in(buff[13]),
    .w14_in(buff[14]),
    .w15_in(buff[15]),
    .sel_in(sel_t16),
  
    .mux_out(temp0)
  );
  
 
  mux16_1 MUX_2(
    .w0_in(buff[0]),
    .w1_in(buff[1]),
    .w2_in(buff[2]),
    .w3_in(buff[3]),
    .w4_in(buff[4]),
    .w5_in(buff[5]),
    .w6_in(buff[6]),
    .w7_in(buff[7]),
    .w8_in(buff[8]),
    .w9_in(buff[9]),
    .w10_in(buff[10]),
    .w11_in(buff[11]),
    .w12_in(buff[12]),
    .w13_in(buff[13]),
    .w14_in(buff[14]),
    .w15_in(buff[15]),
    .sel_in(sel_t15),
  
    .mux_out(temp1)
  );
  
  mux16_1 MUX_3(
    .w0_in(buff[0]),
    .w1_in(buff[1]),
    .w2_in(buff[2]),
    .w3_in(buff[3]),
    .w4_in(buff[4]),
    .w5_in(buff[5]),
    .w6_in(buff[6]),
    .w7_in(buff[7]),
    .w8_in(buff[8]),
    .w9_in(buff[9]),
    .w10_in(buff[10]),
    .w11_in(buff[11]),
    .w12_in(buff[12]),
    .w13_in(buff[13]),
    .w14_in(buff[14]),
    .w15_in(buff[15]),
    .sel_in(sel_t14),
  
    .mux_out(temp2)
  );
  
  mux16_1 MUX_4(
    .w0_in(buff[0]),
    .w1_in(buff[1]),
    .w2_in(buff[2]),
    .w3_in(buff[3]),
    .w4_in(buff[4]),
    .w5_in(buff[5]),
    .w6_in(buff[6]),
    .w7_in(buff[7]),
    .w8_in(buff[8]),
    .w9_in(buff[9]),
    .w10_in(buff[10]),
    .w11_in(buff[11]),
    .w12_in(buff[12]),
    .w13_in(buff[13]),
    .w14_in(buff[14]),
    .w15_in(buff[15]),
    .sel_in(sel_t13),
  
    .mux_out(temp3)
  );
  
  mux16_1 MUX_5(
    .w0_in(buff[0]),
    .w1_in(buff[1]),
    .w2_in(buff[2]),
    .w3_in(buff[3]),
    .w4_in(buff[4]),
    .w5_in(buff[5]),
    .w6_in(buff[6]),
    .w7_in(buff[7]),
    .w8_in(buff[8]),
    .w9_in(buff[9]),
    .w10_in(buff[10]),
    .w11_in(buff[11]),
    .w12_in(buff[12]),
    .w13_in(buff[13]),
    .w14_in(buff[14]),
    .w15_in(buff[15]),
    .sel_in(sel_t12),
  
    .mux_out(temp4)
  );
  
  
  mux16_1 MUX_6(
    .w0_in(buff[0]),
    .w1_in(buff[1]),
    .w2_in(buff[2]),
    .w3_in(buff[3]),
    .w4_in(buff[4]),
    .w5_in(buff[5]),
    .w6_in(buff[6]),
    .w7_in(buff[7]),
    .w8_in(buff[8]),
    .w9_in(buff[9]),
    .w10_in(buff[10]),
    .w11_in(buff[11]),
    .w12_in(buff[12]),
    .w13_in(buff[13]),
    .w14_in(buff[14]),
    .w15_in(buff[15]),
    .sel_in(sel_t7),
  
    .mux_out(temp5)
  );
  
  
  mux16_1 MUX_7(
    .w0_in(buff[0]),
    .w1_in(buff[1]),
    .w2_in(buff[2]),
    .w3_in(buff[3]),
    .w4_in(buff[4]),
    .w5_in(buff[5]),
    .w6_in(buff[6]),
    .w7_in(buff[7]),
    .w8_in(buff[8]),
    .w9_in(buff[9]),
    .w10_in(buff[10]),
    .w11_in(buff[11]),
    .w12_in(buff[12]),
    .w13_in(buff[13]),
    .w14_in(buff[14]),
    .w15_in(buff[15]),
    .sel_in(sel_t6),
  
    .mux_out(temp6)
  );
  
  
  mux16_1 MUX_8(
    .w0_in(buff[0]),
    .w1_in(buff[1]),
    .w2_in(buff[2]),
    .w3_in(buff[3]),
    .w4_in(buff[4]),
    .w5_in(buff[5]),
    .w6_in(buff[6]),
    .w7_in(buff[7]),
    .w8_in(buff[8]),
    .w9_in(buff[9]),
    .w10_in(buff[10]),
    .w11_in(buff[11]),
    .w12_in(buff[12]),
    .w13_in(buff[13]),
    .w14_in(buff[14]),
    .w15_in(buff[15]),
    .sel_in(sel_t5),
  
    .mux_out(temp7)
  );
  
  
  mux16_1 MUX_9(
    .w0_in(buff[0]),
    .w1_in(buff[1]),
    .w2_in(buff[2]),
    .w3_in(buff[3]),
    .w4_in(buff[4]),
    .w5_in(buff[5]),
    .w6_in(buff[6]),
    .w7_in(buff[7]),
    .w8_in(buff[8]),
    .w9_in(buff[9]),
    .w10_in(buff[10]),
    .w11_in(buff[11]),
    .w12_in(buff[12]),
    .w13_in(buff[13]),
    .w14_in(buff[14]),
    .w15_in(buff[15]),
    .sel_in(sel_t4),
  
    .mux_out(temp8)
  );
  
  mux16_1 MUX_10(
    .w0_in(buff[0]),
    .w1_in(buff[1]),
    .w2_in(buff[2]),
    .w3_in(buff[3]),
    .w4_in(buff[4]),
    .w5_in(buff[5]),
    .w6_in(buff[6]),
    .w7_in(buff[7]),
    .w8_in(buff[8]),
    .w9_in(buff[9]),
    .w10_in(buff[10]),
    .w11_in(buff[11]),
    .w12_in(buff[12]),
    .w13_in(buff[13]),
    .w14_in(buff[14]),
    .w15_in(buff[15]),
    .sel_in(sel_t2),
  
    .mux_out(temp9)
  );
  
  
  mux16_1 MUX_11(
    .w0_in(buff[0]),
    .w1_in(buff[1]),
    .w2_in(buff[2]),
    .w3_in(buff[3]),
    .w4_in(buff[4]),
    .w5_in(buff[5]),
    .w6_in(buff[6]),
    .w7_in(buff[7]),
    .w8_in(buff[8]),
    .w9_in(buff[9]),
    .w10_in(buff[10]),
    .w11_in(buff[11]),
    .w12_in(buff[12]),
    .w13_in(buff[13]),
    .w14_in(buff[14]),
    .w15_in(buff[15]),
    .sel_in(sel_t1),
  
    .mux_out(temp10)
  );
  
  assign w0 = t<16 ? temp0 : SIG1(temp9) + temp5 + SIG0(temp1) + temp0;
  assign w1 = t<16 ? temp1 : SIG1(temp10) + temp6 + SIG0(temp2) + temp1;
  assign w2 = t<16 ? temp2 : SIG1(w0) + temp7 + SIG0(temp3) + temp2;
  assign w3 = t<16 ? temp3 : SIG1(w1) + temp8 + SIG0(temp4) + temp3;

endmodule
