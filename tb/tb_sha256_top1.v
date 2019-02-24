
`timescale 1ns/1ps

module tb_sha256_top1;
        reg              clk_in;
        reg              rst_n_in;
        reg      [511:0] block_in;
        reg              block_valid_in;
        reg              last_block_in;
        wire     [255:0] digest_out;
        wire             digest_valid_out;



    sha256_top1 dut(
                        .clk_in(clk_in),
                        .rst_n_in(rst_n_in),
                        .block_in(block_in),
                        .block_valid_in(block_valid_in),
                        .last_block_in(last_block_in),
                        .digest_out(digest_out),
                        .digest_valid_out(digest_valid_out)
        );


        initial
        begin
            clk_in = 1'b0;
            forever #5 clk_in = ~ clk_in;
        end


        initial
        begin
            rst_n_in = 0;
            block_in = 0;
            block_valid_in = 0;
            last_block_in = 0;

            #10;
            rst_n_in = 1;
            block_in = {32'h61626380,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h00000018};
            block_valid_in = 1'b1;
            last_block_in = 1'b1;
            #190;
//            #200;
//            block_in = {

    /*        rst_n_in = 0;
            #10;
            rst_n_in = 1;
            */
#10;
            block_in = {
              32'h61626364,
              32'h62636465,
              32'h63646566,
              32'h64656667,
              32'h65666768,
              32'h66676869,
              32'h6768696a,
              32'h68696a6b,
              32'h696a6b6c,
              32'h6a6b6c6d,
              32'h6b6c6d6e,
              32'h6c6d6e6f,
              32'h6d6e6f70,
              32'h6e6f7071,
              32'h80000000,
              32'h00000000
            };

            block_valid_in = 1'b1;
            last_block_in = 1'b0;
            #10;
            block_valid_in = 1'b0;
            #190;

            block_in = {
              32'h00000000,
              32'h00000000,
              32'h00000000,
              32'h00000000,
              32'h00000000,
              32'h00000000,
              32'h00000000,
              32'h00000000,
              32'h00000000,
              32'h00000000,
              32'h00000000,
              32'h00000000,
              32'h00000000,
              32'h00000000,
              32'h00000000,
              32'h000001c0
            };
            block_valid_in = 1'b1;
            last_block_in = 1'b1;
            #10;
            block_valid_in = 1'b0;
            #190;
            

                
            $finish;
        end

        initial
        begin
            $monitor("\t digest_valid_out = %d  digest_out = %h", digest_valid_out, digest_out);
            $shm_open("sha256_except_padder.shm");
            $shm_probe("ACTMF");
        end

endmodule
