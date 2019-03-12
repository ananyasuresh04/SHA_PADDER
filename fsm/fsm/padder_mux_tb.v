`timescale 1ns/1ps

module tb_padder_mux;

    // Inputs to DUT
    reg  [31:0] msg_in;
    reg  [63:0] bit_length;
    reg  [2:0]  mux_sel;

    // Output from DUT
    wire [31:0] mux_out;

    // Instantiate DUT
    padder_mux dut (
        .msg_in(msg_in),
        .bit_length(bit_length),
        .mux_sel(mux_sel),
        .mux_out(mux_out)
    );

    // Test sequence
    initial begin
        // Initialize signals
        msg_in     = 32'hAABB_CCDD;
        bit_length = 64'h0000_0000_0000_0050; // 80 bits
        mux_sel    = 3'b000;

        #10 mux_sel = 3'b000; // select message
        #10 $display("SEL=000  mux_out=%h  (MSG)", mux_out);

        #10 mux_sel = 3'b001; // select delimiter
        #10 $display("SEL=001  mux_out=%h  (DELIMITER)", mux_out);

        #10 mux_sel = 3'b010; // select zero padding
        #10 $display("SEL=010  mux_out=%h  (ZERO)", mux_out);

        #10 mux_sel = 3'b011; // select length high
        #10 $display("SEL=011  mux_out=%h  (LENGTH HIGH)", mux_out);

        #10 mux_sel = 3'b100; // select length low
        #10 $display("SEL=100  mux_out=%h  (LENGTH LOW)", mux_out);

        #20 $finish;
    end

endmodule
