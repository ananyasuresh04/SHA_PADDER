`timescale 1ns / 1ps

module sha256_padder_tb;
    reg clk, rst_n, msg_valid, msg_last;
    reg [1:0] msg_last_bytes;
    reg [31:0] msg_data;
    
    // Outputs from DUT
    wire [511:0] o_block_512;
    wire o_block_valid;


    initial
begin
$shm_open("pa.shm");
$shm_probe("ACTMF");
end

    // Instantiate DUT
    sha256_padder dut (
        .clk(clk), .rst_n(rst_n), 
        .msg_valid(msg_valid), .msg_last(msg_last),
        .msg_last_bytes(msg_last_bytes), .msg_data(msg_data), 
        .o_block_512(o_block_512), .o_block_valid(o_block_valid)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    integer i;
    integer word_counter;
    integer block_counter;

    // --- MAIN TEST BLOCK ---
    initial begin
        // 1. Initialize
        rst_n = 0; msg_valid = 0; msg_last = 0; msg_last_bytes = 0; msg_data = 0;
        #20 rst_n = 1;

        // ----------------------------------------
        // TEST 1: "abc" (1 Block)
        // ----------------------------------------
        $display("\nTEST 1: 'abc' (1 Block)");
        @(posedge clk);
        msg_valid <= 1; msg_data <= 32'h61626300; msg_last <= 1; msg_last_bytes <= 3;
        @(posedge clk);
        msg_valid <= 0; msg_last <= 0;
        
        #100;
//        wait(o_block_valid);
        repeat(20) @(posedge clk);


        // ----------------------------------------
        // TEST 2: 56 Bytes (Expect 2 Blocks)
        // ----------------------------------------
        $display("\nTEST 2: 56 Bytes (Expect 2 Blocks)");
        word_counter = 0;
        
        for (i=0; i<14; i=i+1) begin
            @(posedge clk);
            msg_valid <= 1; 
            msg_data <= (i==13) ? 32'hBBBBBBBB : 32'hAAAAAAAA; 
            if (i == 13) begin msg_last <= 1; msg_last_bytes <= 0; end
            else msg_last <= 0;
        end

        @(posedge clk); 
        msg_valid <= 0; msg_last <= 0;

        repeat(2) begin
            #50;
//            wait(o_block_valid);
            @(posedge clk); while(o_block_valid) @(posedge clk);
        end
        repeat(20) //@(posedge clk);
        #50;

        // ----------------------------------------
        // TEST 3: 120 Bytes (Expect 3 Blocks)
        // ----------------------------------------
        $display("\nTEST 3: 120 Bytes (Expect 3 Blocks)");
        word_counter = 0;

        for (i=0; i<30; i=i+1) begin
            @(posedge clk);
            msg_valid <= 1; msg_data <= i;
            if (i == 29) begin msg_last <= 1; msg_last_bytes <= 0; end
            else msg_last <= 0;

            word_counter = word_counter + 1;
            if (word_counter == 16 && i != 29) begin
                @(posedge clk);
                msg_valid <= 0;
                repeat(16) @(posedge clk); 
                word_counter = 0;
            end
        end

        @(posedge clk); msg_valid <= 0; msg_last <= 0;

        repeat(3) begin
            #50;
            //wait(o_block_valid);
            @(posedge clk); while(o_block_valid) @(posedge clk);
        end
        repeat(20) @(posedge clk);


        // ----------------------------------------
        // TEST 4: 400 Bytes (Expect 7 Blocks)
        // ----------------------------------------
        $display("\nTEST 4: 400 Bytes (Expect 7 Blocks)");
        word_counter = 0;
        block_counter = 0;

        for (i=0; i<100; i=i+1) begin
            @(posedge clk);
            msg_valid <= 1;
            msg_data <= i; 
            
            if (i == 99) begin
                msg_last <= 1;
                msg_last_bytes <= 0; 
            end else msg_last <= 0;

            word_counter = word_counter + 1;
            if (word_counter == 16 && i != 99) begin
                @(posedge clk);
                msg_valid <= 0; 
                repeat(16) @(posedge clk); 
                word_counter = 0; 
            end
        end

        @(posedge clk); msg_valid <= 0; msg_last <= 0;

        repeat(7) begin
//            wait(o_block_valid);
            #50;
            block_counter = block_counter + 1;
            @(posedge clk); while(o_block_valid) @(posedge clk);
        end
        repeat(20) @(posedge clk);


        // ----------------------------------------
        // TEST 5: Reset Check ("abc" again)
        // ----------------------------------------
        $display("\nTEST 5: 'abc' again (Sanity Check)");
        @(posedge clk);
        msg_valid <= 1; msg_data <= 32'h61626300; msg_last <= 1; msg_last_bytes <= 3;
        @(posedge clk);
        msg_valid <= 0; msg_last <= 0;
        
        #100;
//        wait(o_block_valid);
        $display("  -> Block Received");

        #100;
        $display("\n--- ALL TESTS COMPLETE ---");
        $finish;
    end

    // Monitor Output
    always @(posedge clk) begin
        if (o_block_valid) begin
            $display("--------------------------------------------------");
            $display("OUTPUT 512-bit Block: %h", o_block_512);
            $display("Length Field (Hex): %h", o_block_512[63:0]);
            $display("--------------------------------------------------");
        end
    end

endmodule
