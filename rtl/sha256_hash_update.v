
`timescale 1ns/1ps

module sha256_hash_update(
//        input rst_in,
        input       [255:0] c_h0_to_h7_in,
        input       [255:0] h0_to_h7_in,
        input               final_blk_in,
        input               h_update_en_in,
        output reg  [255:0] digest_out,
        output reg  [255:0] h_update_out,
        output              digest_valid_out
);

    wire [255:0] temp_update;

    always@(*)
    begin
/*        if(h_update_en)
        begin
            temp_update[31:0]     = h0_to_h7_in[31:0]    + c_h0_to_h7_in[31:0]   ;
            temp_update[63:32]    = h0_to_h7_in[63:32]   + c_h0_to_h7_in[63:32]  ; 
            temp_update[95:64]    = h0_to_h7_in[95:64]   + c_h0_to_h7_in[95:64]  ; 
            temp_update[127:96]   = h0_to_h7_in[127:96]  + c_h0_to_h7_in[127:96] ; 
            temp_update[159:128]  = h0_to_h7_in[159:128] + c_h0_to_h7_in[159:128]; 
            temp_update[191:160]  = h0_to_h7_in[191:160] + c_h0_to_h7_in[191:160]; 
            temp_update[223:192]  = h0_to_h7_in[223:192] + c_h0_to_h7_in[223:192]; 
            temp_update[255:224]  = h0_to_h7_in[255:224] + c_h0_to_h7_in[255:224];
        end
        else
        begin
            temp_update = 0;
        end
*/
        h_update_out = 0;
        digest_out = 0;

        case(final_blk_in)
            0: h_update_out = temp_update;
            1: digest_out = temp_update;
        endcase
    end

    assign temp_update[31:0]      = h_update_en_in ? h0_to_h7_in[31:0]       + c_h0_to_h7_in[31:0]       : 32'h0;
    assign temp_update[63:32]     = h_update_en_in ? h0_to_h7_in[63:32]      + c_h0_to_h7_in[63:32]      : 32'h0;
    assign temp_update[95:64]     = h_update_en_in ? h0_to_h7_in[95:64]      + c_h0_to_h7_in[95:64]      : 32'h0;
    assign temp_update[127:96]    = h_update_en_in ? h0_to_h7_in[127:96]     + c_h0_to_h7_in[127:96]     : 32'h0;
    assign temp_update[159:128]   = h_update_en_in ? h0_to_h7_in[159:128]    + c_h0_to_h7_in[159:128]    : 32'h0;
    assign temp_update[191:160]   = h_update_en_in ? h0_to_h7_in[191:160]    + c_h0_to_h7_in[191:160]    : 32'h0;
    assign temp_update[223:192]   = h_update_en_in ? h0_to_h7_in[223:192]    + c_h0_to_h7_in[223:192]    : 32'h0;
    assign temp_update[255:224]   = h_update_en_in ? h0_to_h7_in[255:224]    + c_h0_to_h7_in[255:224]    : 32'h0;

    assign digest_valid_out = final_blk_in ? 1'b1 : 1'b0;

endmodule
