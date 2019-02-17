`timescale 1ns / 1ps
/*
module sha256_padder_tb;
    reg clk, rst_n, msg_valid, msg_last;
    reg [1:0] msg_last_bytes;
    reg [31:0] msg_data;
    wire o_ready, o_word_valid, o_last_word, o_block_valid;
    wire [31:0] o_word;
    wire [511:0] o_block_512;

    initial
begin
$shm_open("padder.shm");
$shm_probe("ACTMF");
end
    

    sha256_padder dut (
        .clk(clk), .rst_n(rst_n), 
        .msg_valid(msg_valid), .msg_last(msg_last),
        .msg_last_bytes(msg_last_bytes), .msg_data(msg_data), 
        .o_ready(o_ready), .o_word(o_word), 
        .o_word_valid(o_word_valid), .o_last_word(o_last_word),
        .o_block_512(o_block_512), .o_block_valid(o_block_valid)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    task send_word(input [31:0] data, input last, input [1:0] bytes);
    begin
        wait(o_ready); @(posedge clk);
        msg_valid <= 1; msg_data <= data; msg_last <= last; msg_last_bytes <= bytes;
        @(posedge clk); msg_valid <= 0; msg_last <= 0;
    end
    endtask
    // Display Logic
    integer w_cnt = 0, b_cnt = 0;
    
    // Monitor Concatenated Block
    always @(posedge clk) if (o_block_valid) begin
        $display("\n[TIME %0t] --- CONCATENATED 512-BIT BLOCK ---", $time);
        $display("%h", o_block_512);
        $display("----------------------------------------------");
    end

    // Monitor Word Stream
    always @(posedge clk) if (o_word_valid) begin
        if (w_cnt == 0) $display("\n--- Block %0d Word Stream ---", b_cnt);
        $display("W[%02d] = %h", w_cnt, o_word);
        w_cnt <= (w_cnt == 15) ? 0 : w_cnt + 1;
        if (o_last_word) b_cnt <= b_cnt + 1;
    end

    initial begin
        rst_n = 0; msg_valid = 0; #20 rst_n = 1;
        
        $display("\nTEST 1: 'abc'");
        send_word(32'h61626300, 1, 3);
        wait(b_cnt == 1);
        #100;

        $display("\nTEST 3: FIPS Multi-block (56 Bytes)");
        b_cnt = 0; w_cnt = 0;
        send_word(32'h61626364, 0, 0); send_word(32'h62636465, 0, 0);
        send_word(32'h63646566, 0, 0); send_word(32'h64656667, 0, 0);
        send_word(32'h65666768, 0, 0); send_word(32'h66676869, 0, 0);
        send_word(32'h6768696a, 0, 0); send_word(32'h68696a6b, 0, 0);
        send_word(32'h696a6b6c, 0, 0); send_word(32'h6a6b6c6d, 0, 0);
        send_word(32'h6b6c6d6e, 0, 0); send_word(32'h6c6d6e6f, 0, 0);
        send_word(32'h6d6e6f70, 0, 0); send_word(32'h6e6f7071, 1, 0);
        
        wait(b_cnt == 2);
        #100; $finish;
    end
endmodule
*/

`timescale 1ns / 1ps

module sha256_padder_tb;
    reg clk, rst_n, msg_valid, msg_last;
    reg [1:0] msg_last_bytes;
    reg [31:0] msg_data;
    
    // Outputs from DUT
    wire [511:0] o_block_512;
    wire o_block_valid;

    // Instantiate (No streaming outputs connected)
    sha256_padder dut (
        .clk(clk), .rst_n(rst_n), 
        .msg_valid(msg_valid), .msg_last(msg_last),
        .msg_last_bytes(msg_last_bytes), .msg_data(msg_data), 
        .o_block_512(o_block_512), .o_block_valid(o_block_valid)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    integer i;

    // --- MAIN TEST BLOCK ---
    initial begin
        // 1. Initialize
        rst_n = 0; msg_valid = 0; msg_last = 0; msg_last_bytes = 0; msg_data = 0;
        #20 rst_n = 1;

        // ----------------------------------------
        // TEST 1: "abc" (Single Word Input)
        // ----------------------------------------
        $display("\nTEST 1: 'abc'");
        @(posedge clk);
        msg_valid <= 1; 
        msg_data <= 32'h61626300; 
        msg_last <= 1; 
        msg_last_bytes <= 3;
        
        @(posedge clk);
        msg_valid <= 0; msg_last <= 0;

        // Wait for output (Takes about 17 cycles internal processing)
        wait(o_block_valid);
        #10; // Wait a bit to clear
        
        // Wait for FSM to return to IDLE (logic takes ~16 cycles in S_STREAM)
        repeat(20) @(posedge clk);


        // ----------------------------------------
        // TEST 2: 56 Bytes (Multi-Block)
        // ----------------------------------------
        $display("\nTEST 2: 56 Bytes (Expect 2 Blocks)");
        
        // Send 13 Full words (AAAA...)
        for (i=0; i<13; i=i+1) begin
            @(posedge clk);
            msg_valid <= 1; 
            msg_data <= 32'hAAAAAAAA; 
            msg_last <= 0; 
            msg_last_bytes <= 0;
        end

        // Send 14th Word (BBBB...) - Last Word
        @(posedge clk);
        msg_valid <= 1; 
        msg_data <= 32'hBBBBBBBB; 
        msg_last <= 1; 
        msg_last_bytes <= 0;

        @(posedge clk);
        msg_valid <= 0; msg_last <= 0;

        #200;

        rst_n=0;
        #10;
        rst_n=1;
        #10;
        for (i=0; i<12; i=i+1) begin
            @(posedge clk);
            msg_valid <= 1; 
            msg_data <= 32'habcdef00; 
            msg_last <= 0; 
            msg_last_bytes <= 0;
        end

         @(posedge clk);
        msg_valid <= 1; 
        msg_data <= 32'hfedcba30; 
        msg_last <= 1; 
        msg_last_bytes <= 0;


        // Wait for Block 1
        wait(o_block_valid);
        $display("  -> Block 1 Received");
        @(posedge clk);
        while(o_block_valid) @(posedge clk); // Wait for signal to drop

        // Wait for Block 2 (Spillover block)
        wait(o_block_valid);
        $display("  -> Block 2 Received");
      
        #200;
        $finish;
    end

    // Monitor Block Output
    always @(posedge clk) begin
        if (o_block_valid) begin
            $display("--------------------------------------------------");
            $display("OUTPUT 512-bit Block: %h", o_block_512);
            $display("--------------------------------------------------");
        end
    end

    initial
    begin
        $shm_open("pp_test.shm");
        $shm_probe("ACTMF");
    end

endmodule

