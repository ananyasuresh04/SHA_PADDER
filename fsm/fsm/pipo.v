`timescale 1ns/1ps

module pipo_word_buffer (
    input  wire         clk,
    input  wire         rst,
    input  wire         pipo_load,
    input  wire [511:0] block_in,

    output wire [31:0]  w0,
    output wire [31:0]  w1,
    output wire [31:0]  w2,
    output wire [31:0]  w3,
    output wire [31:0]  w4,
    output wire [31:0]  w5,
    output wire [31:0]  w6,
    output wire [31:0]  w7,
    output wire [31:0]  w8,
    output wire [31:0]  w9,
    output wire [31:0]  w10,
    output wire [31:0]  w11,
    output wire [31:0]  w12,
    output wire [31:0]  w13,
    output wire [31:0]  w14,
    output wire [31:0]  w15
);

    reg [511:0] pipo_reg;

    always @(posedge clk or posedge rst) begin
        if (rst)
            pipo_reg <= 512'd0;
        else if (pipo_load)
            pipo_reg <= block_in;   // Parallel load
    end

    assign w0  = pipo_reg[511:480];
    assign w1  = pipo_reg[479:448];
    assign w2  = pipo_reg[447:416];
    assign w3  = pipo_reg[415:384];
    assign w4  = pipo_reg[383:352];
    assign w5  = pipo_reg[351:320];
    assign w6  = pipo_reg[319:288];
    assign w7  = pipo_reg[287:256];
    assign w8  = pipo_reg[255:224];
    assign w9  = pipo_reg[223:192];
    assign w10 = pipo_reg[191:160];
    assign w11 = pipo_reg[159:128];
    assign w12 = pipo_reg[127:96];
    assign w13 = pipo_reg[95:64];
    assign w14 = pipo_reg[63:32];
    assign w15 = pipo_reg[31:0];

endmodule

