module padder_mux (
    input  wire [1:0]  mux_sel,
    input  wire [31:0] msg_data,
    input  wire [31:0] padded_last_data,
    input  wire [31:0] zero_data,
    input  wire [31:0] length_data,
    output reg  [31:0] mux_out
);
    always @(*) begin
        case (mux_sel)
            2'b00: mux_out = msg_data;
            2'b01: mux_out = padded_last_data;
            2'b10: mux_out = zero_data;
            2'b11: mux_out = length_data;
            default: mux_out = 32'h0;
        endcase
    end
endmodule
