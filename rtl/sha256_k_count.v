
`timescale 1ns/1ps

module sha256_k_count(
    input       clk_in,
    input       rst_n_in,
    input       valid_in,
    output reg [5:0] k_addr_out
);

    always@(posedge clk_in or  negedge rst_n_in)
    begin
        if(!rst_n_in)
            k_addr_out <= 6'd0;
        else if(valid_in)
            k_addr_out <= k_addr_out + 6'd1;
    end

endmodule
