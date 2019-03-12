`timescale 1ns/1ps

module tb_pipo_word_buffer;

    reg         clk;
    reg         rst;
    reg         pipo_load;
    reg [511:0] block_in;

    wire [31:0] w0;
    wire [31:0] w1;
    wire [31:0] w2;
    wire [31:0] w3;
    wire [31:0] w4;
    wire [31:0] w5;
    wire [31:0] w6;
    wire [31:0] w7;
    wire [31:0] w8;
    wire [31:0] w9;
    wire [31:0] w10;
    wire [31:0] w11;
    wire [31:0] w12;
    wire [31:0] w13;
    wire [31:0] w14;
    wire [31:0] w15;

    // DUT
    pipo_word_buffer dut (
        .clk(clk),
        .rst(rst),
        .pipo_load(pipo_load),
        .block_in(block_in),
        .w0(w0), .w1(w1), .w2(w2), .w3(w3),
        .w4(w4), .w5(w5), .w6(w6), .w7(w7),
        .w8(w8), .w9(w9), .w10(w10), .w11(w11),
        .w12(w12), .w13(w13), .w14(w14), .w15(w15)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        pipo_load = 0;
        block_in = 0;

        #20 rst = 0;

        // Example block (16 x 32-bit words)
        block_in = {
            32'h11111111, 32'h22222222, 32'h33333333, 32'h44444444,
            32'h55555555, 32'h66666666, 32'h77777777, 32'h88888888,
            32'h99999999, 32'hAAAAAAAA, 32'hBBBBBBBB, 32'hCCCCCCCC,
            32'hDDDDDDDD, 32'hEEEEEEEE, 32'hFFFFFFFF, 32'h12345678
        };

        #10 pipo_load = 1;
        #10 pipo_load = 0;

        #10;
        $display("\n--- PIPO OUTPUT WORDS ---");
        $display("W0  = %h", w0);
        $display("W1  = %h", w1);
        $display("W2  = %h", w2);
        $display("W3  = %h", w3);
        $display("W4  = %h", w4);
        $display("W5  = %h", w5);
        $display("W6  = %h", w6);
        $display("W7  = %h", w7);
        $display("W8  = %h", w8);
        $display("W9  = %h", w9);
        $display("W10 = %h", w10);
        $display("W11 = %h", w11);
        $display("W12 = %h", w12);
        $display("W13 = %h", w13);
        $display("W14 = %h", w14);
        $display("W15 = %h", w15);

        #20 $finish;
    end

endmodule
