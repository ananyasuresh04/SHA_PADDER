module tb_byte_counter;

    reg  clk;                    
    reg rst;                     
    reg msg_start;               
    reg msg_valid;             
    reg [2:0] valid_bytes;
    reg  msg_end;        

    wire [63:0] byte_count;  
    wire [63:0] bit_length;  
    wire  length_ready ;              
    
    byte_counter dut (
        .clk(clk),
        .rst(rst),
        .msg_start(msg_start),
        .msg_valid(msg_valid),
        .valid_bytes(valid_bytes),
        .msg_end(msg_end),
        .byte_count(byte_count),
        .bit_length(bit_length),
        .length_ready(length_ready)
    );

     initial begin
                 $shm_open("word_counter.shm");
                 $shm_probe("ACTMF");
             end

             always begin
                 clk = 0;
                 forever #5 clk = ~clk;
             end

    initial begin
        // init
       clk = 0;
        rst = 1;
        msg_start = 0;
        msg_valid = 0;
        valid_bytes = 0;
        msg_end = 0;

        // RESET
        #20;
        rst = 0;

        // START MESSAGE
        #10;
        msg_start = 1;
        #10;
        msg_start = 0;

        // WORD 1 (4 bytes)
        #10;
        msg_valid = 1;
        valid_bytes = 3'd4;
        #10;
        msg_valid = 0;

        // WORD 2 (4 bytes)
        #10;
        msg_valid = 1;
        valid_bytes = 3'd4;
        #10;
        msg_valid = 0;

        // LAST WORD (2 bytes)
        #10;
        msg_valid = 1;
        valid_bytes = 3'd2;
        #10;
        msg_valid = 0;

        // END MESSAGE
        #10;
        msg_end = 1;
        #10;
        msg_end = 0;


        // WAIT & FINISH
        #20;
        $display("BYTE COUNT  = %0d", byte_count);
        $display("BIT LENGTH  = %0d", bit_length);
        $display("READY FLAG  = %b", length_ready);

        #20;
        $finish;
    end

endmodule 
