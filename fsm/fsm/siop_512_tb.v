`timescale 1ns/1ps

module tb_sipo_512;

    reg         clk;
    reg         rst;
    reg         shift_en;
    reg  [31:0] mux_out;
    wire [511:0] block_out;

    // DUT
    sipo_512 dut (
        .clk(clk),
        .rst(rst),
        .shift_en(shift_en),
        .mux_out(mux_out),
        .block_out(block_out)
    );

    // Clock
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        shift_en = 0;
        mux_out = 0;

        #20 rst = 0;

        // Shift 4 known words (for testing)
        #10 shift_en = 1; mux_out = 32'h11111111;
        #10 shift_en = 1; mux_out = 32'h22222222;
        #10 shift_en = 1; mux_out = 32'h33333333;
        #10 shift_en = 1; mux_out = 32'h44444444;

        // Stop shifting
        #10 shift_en = 0;

        // Print result
        #10;
        $display("BLOCK OUT = %h", block_out);

        #20 $finish;
    end

endmodule

