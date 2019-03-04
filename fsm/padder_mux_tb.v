module tb_padder_mux;
    reg [1:0] mux_sel;
    reg [31:0] msg_data, padded_last_data, zero_data, length_data;
    wire [31:0] mux_out;

    padder_mux dut (
        .mux_sel(mux_sel),
        .msg_data(msg_data),
        .padded_last_data(padded_last_data),
        .zero_data(zero_data),
        .length_data(length_data),
        .mux_out(mux_out)
    );

    initial begin
        msg_data         = 32'h61626300;
        padded_last_data = 32'h61626380;
        zero_data        = 32'h00000000;
        length_data      = 32'h00000018;

        mux_sel = 2'b00; #10 $display("MSG    = %h", mux_out);
        mux_sel = 2'b01; #10 $display("PADDED = %h", mux_out);
        mux_sel = 2'b10; #10 $display("ZERO   = %h", mux_out);
        mux_sel = 2'b11; #10 $display("LEN    = %h", mux_out);

        $finish;
    end
endmodule
