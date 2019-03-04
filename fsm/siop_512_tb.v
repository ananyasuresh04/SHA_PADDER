module tb_sipo_512;
    reg clk = 0, rst_n = 0, shift_en;
    reg [31:0] data_in;
    wire [511:0] data_out;

    sipo_512 dut (clk, rst_n, shift_en, data_in, data_out);

    always #5 clk = ~clk;

    integer i;
    initial begin
        rst_n = 0; shift_en = 0; data_in = 0;
        #20 rst_n = 1;

        for (i = 0; i < 16; i = i + 1) begin
            shift_en = 1;
            data_in = i;
            #10;
        end

        shift_en = 0;
        $display("SIPO OUT = %h", data_out);
        $finish;
    end
endmodule
