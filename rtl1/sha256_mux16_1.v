
`timescale 1ns/1ps

module mux16_1(
  input [31:0] w0_in,
  input [31:0] w1_in,
  input [31:0] w2_in,
  input [31:0] w3_in,
  input [31:0] w4_in,
  input [31:0] w5_in,
  input [31:0] w6_in,
  input [31:0] w7_in,
  input [31:0] w8_in,
  input [31:0] w9_in,
  input [31:0] w10_in,
  input [31:0] w11_in,
  input [31:0] w12_in,
  input [31:0] w13_in,
  input [31:0] w14_in,
  input [31:0] w15_in,
  input [3:0]  sel_in,
  
  output reg [31:0] mux_out
);
  
  always@(*)
    begin
      case(sel_in)
        4'b0000: mux_out = w0_in;
        4'b0001: mux_out = w1_in;
        4'b0010: mux_out = w2_in;
        4'b0011: mux_out = w3_in;
        4'b0100: mux_out = w4_in;
        4'b0101: mux_out = w5_in;
        4'b0110: mux_out = w6_in;
        4'b0111: mux_out = w7_in;
        4'b1000: mux_out = w8_in;
        4'b1001: mux_out = w9_in;
        4'b1010: mux_out = w10_in;
        4'b1011: mux_out = w11_in;
        4'b1100: mux_out = w12_in;
        4'b1101: mux_out = w13_in;
        4'b1110: mux_out = w14_in;
        4'b1111: mux_out = w15_in;
      endcase
    end
  
endmodule
