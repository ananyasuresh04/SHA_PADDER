

module pipo_512 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        load,
    input  wire [511:0] data_in,
    output reg  [511:0] data_out,
    output reg         valid_out
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out  <= 512'd0;
        valid_out <= 1'b0;
    end
    else if (load) begin
        data_out  <= data_in;
        valid_out <= 1'b1;
    end
    else
        valid_out <= 1'b0;
end

endmodule

