`timescale 1ns/1ps
module padder_fsm_tb;

    reg clk, rst;
    reg msg_start;
    reg msg_valid;
    reg msg_end;

    // Word counter (driven ONLY by shift_en)
    reg [4:0] word_count;

    wire block_full;
     wire overflow_required;

    wire [1:0] mux_sel;
    wire shift_en;
    wire pipo_load;
    wire [3:0] state;

       padder_fsm DUT (
        .clk(clk),
        .rst(rst),
        .msg_start(msg_start),
        .msg_valid(msg_valid),
        .msg_end(msg_end),
        .word_count(word_count),
        .block_full(block_full),
       .overflow_required(1'b0),   // no overflow in this test
        .mux_sel(mux_sel),
        .shift_en(shift_en),
        .pipo_load(pipo_load),
        .state(state)
    );
    initial
begin
    $shm_open("waves.shm");
    $shm_probe("ACTMF");
end


    always #5 clk = ~clk;

    
  /*  always @(posedge clk or posedge rst) begin
        if (rst)
            word_count <= 0;
        else if (pipo_load)
            word_count <= 0;               // reset when block finished
        else if (shift_en)
            word_count <= word_count + 1;  // increment only on shift
    end

    assign block_full = (word_count == 5'd15);*/

    always @(posedge clk or posedge rst) begin
        if (rst)
            word_count <= 0;
        else if (pipo_load)
            word_count <= 0;
        else if (shift_en) begin
            if (word_count < 5'd15)
                word_count <= word_count + 1;
            else
                word_count <= word_count; // clamp
        end
    end

    assign block_full = (word_count == 5'd15);

    initial begin
        $display("-------------------------------------------------------------");
        $display(" TIME | STATE | shift_en | mux_sel | pipo_load | word_count ");
        $display("-------------------------------------------------------------");

        $monitor("%4dns |   %1d    |    %1d     |    %02b     |     %1d     |     %2d",
                 $time, state, shift_en, mux_sel, pipo_load, word_count);
    end
    initial begin
        clk = 0;
        rst = 1;

        msg_start = 0;
        msg_valid = 0;
        msg_end   = 0;

        #20 rst = 0;

        //-------------------------------
        // Start a new message
        //-------------------------------
        #10 msg_start = 1;
        #10 msg_start = 0;

        //-------------------------------
        // Send 3 normal words
        //-------------------------------
        repeat (3) begin
            msg_valid = 1;
            msg_end   = 0;
            #10;
        end

        //-------------------------------
        // Last word (msg_end = 1)
        //-------------------------------
        msg_valid = 1;
        msg_end   = 1;
        #10;

               // Stop sending data
                msg_valid = 0;
        msg_end   = 0;
        // Allow time for padding + length
               #300;

        $display("-------------------------------------------------------------");
        $display("PADDER FSM TEST COMPLETED SUCCESSFULLY");
        $display("-------------------------------------------------------------");

        $finish;
    end

endmodule
      
 
