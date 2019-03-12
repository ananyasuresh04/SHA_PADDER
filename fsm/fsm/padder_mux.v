`timescale 1ns/1ps
module padder_mux (
    input  wire [31:0] msg_in,
    input  wire [63:0] bit_length,
    input  wire [2:0]  mux_sel,

    output reg  [31:0] mux_out
);

always @(*) begin
    case (mux_sel)
        3'b000: mux_out = msg_in;            // message data
        3'b001: mux_out = 32'h8000_0000;     // delimiter '1' + zeros
        3'b010: mux_out = 32'h00000000;      // zero padding
        3'b011: mux_out = bit_length[63:32]; // length high
        3'b100: mux_out = bit_length[31:0];  // length low
        default: mux_out = 32'h00000000;
    endcase
end

endmodule
                           
