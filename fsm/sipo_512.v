module sipo_512 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        shift_en,
    input  wire [31:0] data_in,
    output reg  [511:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 512'b0;
        else if (shift_en)
            data_out <= {data_out[479:0], data_in};
    end
endmodule

