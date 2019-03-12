`timescale 1ns/1ps
    
    module sipo_512 (
    input  wire        clk,
    input  wire        rst,
    input  wire        shift_en,
    input  wire [31:0] mux_out,

    output wire [511:0] block_out
);

    reg [511:0] sipo_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sipo_reg <= 512'd0;
        end
        else if (shift_en) begin
            sipo_reg <= {sipo_reg[511-32:0], mux_out};
        end
    end

    assign block_out = sipo_reg;

endmodule

