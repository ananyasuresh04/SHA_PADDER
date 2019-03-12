module length_gen (
    input  wire [63:0] byte_cnt,
    output wire [31:0] length_hi,
    output wire [31:0] length_lo
);
    wire [63:0] bit_len = byte_cnt << 3;
    assign length_hi = bit_len[63:32];
    assign length_lo = bit_len[31:0];
endmodule
