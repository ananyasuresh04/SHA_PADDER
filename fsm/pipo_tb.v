`timescale 1ns/1ps

module tb_pipo_512;

    reg clk;
    reg rst_n;

    reg         load;
    reg [511:0] data_in;
    wire [511:0] data_out;
    wire        valid_out;

    always #5 clk = ~clk;

    pipo_512 dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .load     (load),
        .data_in  (data_in),
        .data_out (data_out),
        .valid_out(valid_out)
    );

    always @(posedge clk) begin
        if (valid_out) begin
            $display("PIPO BLOCK = %h", data_out);
        end
    end

    initial begin
        clk = 0;
        rst_n = 0;
        load = 0;
        data_in = 512'd0;

        #20 rst_n = 1;

        @(posedge clk);
        load <= 1'b1;
        data_in <= {
            32'hAAAA_AAAA,
            32'hBBBB_BBBB,
            32'hCCCC_CCCC,
            32'hDDDD_DDDD,
            384'h0
        };

        @(posedge clk);
        load <= 1'b0;

        #50;
        $finish;
    end

endmodule
