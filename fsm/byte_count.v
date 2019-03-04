module byte_counter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        padder_start,

    input  wire        msg_valid,
    input  wire        msg_last,
    input  wire [1:0]  msg_last_bytes,

    output reg  [63:0] byte_cnt
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || padder_start) begin
            byte_cnt <= 64'd0;
        end
        else if (msg_valid) begin
            if (msg_last)
                byte_cnt <= byte_cnt + msg_last_bytes; // last partial word
            else
                byte_cnt <= byte_cnt + 64'd4;          // normal word
        end
    end

endmodule

