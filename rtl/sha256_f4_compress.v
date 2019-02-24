

`timescale 1ns/1ps


module sha256_f4_compress(
        input              clk_in,
        input              rst_n_in,
        input      [127:0] msg_words_in,
        input      [3:0]   k_rd_addr_in,
        input              h_load_in,
        input              comp_new_h_in,
        input              h_buff_en_in,
        input              comp_done_in,
        input      [255:0] h_update_in,
        input              msg_init_in,
        output reg [255:0] c_h0_to_h7_out,
        output reg [255:0] h0_to_h7_out
);


    wire [255:0] h_load_data;
    wire [255:0] comp_out;  

    wire [255:0] buff_load_data;
    wire [255:0] buff2comp;

    reg [31:0] h_buff [0:7];

//    reg [31:0] k_rom [0:63];

    reg [31:0] k_rom1 [0:15];
    reg [31:0] k_rom2 [0:15];
    reg [31:0] k_rom3 [0:15];
    reg [31:0] k_rom4 [0:15];

    wire [31:0] k_addr_r0;
    wire [31:0] k_addr_r1;
    wire [31:0] k_addr_r2;
    wire [31:0] k_addr_r3;

    reg [31:0] a,b,c,d,e,f,g,h;

    
    wire [31:0] a1,b1,c1,d1,e1,f1,g1,h1;
    wire [31:0] a2,b2,c2,d2,e2,f2,g2,h2;
    wire [31:0] a3,b3,c3,d3,e3,f3,g3,h3;
    wire [31:0] a4,b4,c4,d4,e4,f4,g4,h4;


//    assign buff_load_data = h_load_in ? /*h_load_data*/ (comp_new_h_in ? h_update_in : {h,g,f,e,d,c,b,a}) : buff2comp;

//    assign h_load_data = comp_new_h_in ? h_update_in : {h,g,f,e,d,c,b,a};


    initial
    begin
//        $readmemh("k_rom.hex",k_rom);
          $readmemh("../rtl/k_rom1.hex",k_rom1);
          $readmemh("../rtl/k_rom2.hex",k_rom2);
          $readmemh("../rtl/k_rom3.hex",k_rom3);
          $readmemh("../rtl/k_rom4.hex",k_rom4);
    end


    always@(posedge clk_in or negedge rst_n_in)
    begin
        if((!rst_n_in) || msg_init_in)
        begin
            h_buff[0] <= 32'h6a09e667;
            h_buff[1] <= 32'hbb67ae85;
            h_buff[2] <= 32'h3c6ef372;
            h_buff[3] <= 32'ha54ff53a;
            h_buff[4] <= 32'h510e527f;
            h_buff[5] <= 32'h9b05688c;
            h_buff[6] <= 32'h1f83d9ab;
            h_buff[7] <= 32'h5be0cd19;
        end
        else if(h_buff_en_in)
        begin
            h_buff[0] <= h_update_in[31:0];
            h_buff[1] <= h_update_in[63:32];
            h_buff[2] <= h_update_in[95:64]; 
            h_buff[3] <= h_update_in[127:96]; 
            h_buff[4] <= h_update_in[159:128]; 
            h_buff[5] <= h_update_in[191:160]; 
            h_buff[6] <= h_update_in[223:192]; 
            h_buff[7] <= h_update_in[255:224];
//            for(m=0;m<8;m=m+1)
//                h_buff[m] <= h_update_in[255-32*m -:32];
        end
    end

//    assign buff2comp = {h_buff[7],h_buff[6],h_buff[5],h_buff[4],h_buff[3],h_buff[2],h_buff[1],h_buff[0]};
    wire [255:0] h_buff_concat;

    assign h_buff_concat = {h_buff[7], h_buff[6], h_buff[5], h_buff[4],
                            h_buff[3], h_buff[2], h_buff[1], h_buff[0]
                            };

    assign buff_load_data = (h_load_in == 1'b0) ? h_buff_concat : ((comp_new_h_in) ? h_update_in : {h,g,f,e,d,c,b,a});

/*    
    always@(posedge clk_in or negedge rst_n_in)
    begin
//            buff_load_data = {h_buff[7],h_buff[6],h_buff[5],h_buff[4],h_buff[3],h_buff[2],h_buff[1],h_buff[0]};
        if(!rst_n_in)
        begin
            h0_to_h7_out <= 'd0;
            buff_load_data <= 'd0;
        end
        else if(h_load_in)
        begin
//            buff_load_data = {h_buff[7],h_buff[6],h_buff[5],h_buff[4],h_buff[3],h_buff[2],h_buff[1],h_buff[0]};
            
            h0_to_h7_out <= buff2comp;
            if(comp_new_h_in)
                buff_load_data <= h_update_in;
            else
                buff_load_data <= {h,g,f,e,d,c,b,a};
            
        end
        else
        begin
            buff_load_data <= buff2comp;
            h0_to_h7_out = {h_buff[7],h_buff[6],h_buff[5],h_buff[4],h_buff[3],h_buff[2],h_buff[1],h_buff[0]};
            if(comp_new_h_in)
                buff_load_data = h_update_in;
            else
                buff_load_data = {h,g,f,e,d,c,b,a};

        end
    end
    */

    assign k_addr_r0 = k_rom1[k_rd_addr_in];
    assign k_addr_r1 = k_rom2[k_rd_addr_in];
    assign k_addr_r2 = k_rom3[k_rd_addr_in];
    assign k_addr_r3 = k_rom4[k_rd_addr_in];

    sha256_round r0(buff_load_data[31:0],buff_load_data[63:32],buff_load_data[95:64],buff_load_data[127:96],buff_load_data[159:128],buff_load_data[191:160],buff_load_data[223:192],buff_load_data[255:224], msg_words_in[127:96],k_addr_r0, a1,b1,c1,d1,e1,f1,g1,h1);
    sha256_round r1(a1,b1,c1,d1,e1,f1,g1,h1, msg_words_in[95:64], k_addr_r1, a2,b2,c2,d2,e2,f2,g2,h2);
    sha256_round r2(a2,b2,c2,d2,e2,f2,g2,h2, msg_words_in[63:32], k_addr_r2, a3,b3,c3,d3,e3,f3,g3,h3);
    sha256_round r3(a3,b3,c3,d3,e3,f3,g3,h3, msg_words_in[31:0], k_addr_r3, a4,b4,c4,d4,e4,f4,g4,h4);

    assign comp_out = {h4,g4,f4,e4,d4,c4,b4,a4};

    always@(posedge clk_in or negedge rst_n_in)
    begin
        if(!rst_n_in)
        begin
            {h,g,f,e,d,c,b,a} <= 0;
            c_h0_to_h7_out <= 0;
            h0_to_h7_out <= 0;
        end
        else if(!comp_done_in)
            {h,g,f,e,d,c,b,a} <= comp_out;
        else
        begin
            c_h0_to_h7_out <= comp_out; 
            h0_to_h7_out <= h_buff_concat;
        end
    end

//    assign c_h0_to_h7_out = {h,g,f,e,d,c,b,a};

 endmodule
