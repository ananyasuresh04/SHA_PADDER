`timescale 1ns/1ps

/*module sha256_compress_fsm (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  count,
    input  wire        last_block,

    output reg         H_buff_en,
    output reg         comp_new_h,
    output reg         H_load_in,
    output reg         comp_done,
    output reg         final_block,
    output reg         H_update_en
);

    // -------------------------------------------------
    // State encoding (4 states for 4 conditions)
    // -------------------------------------------------
    parameter S_CNT0        = 2'b00;  // count == 0
    parameter S_CNT_1_14    = 2'b01;  // count 1 to 14
    parameter S_CNT15_MID  = 2'b10;  // count == 15 && last_block == 0
    parameter S_CNT15_LAST = 2'b11;  // count == 15 && last_block == 1

    reg [1:0] curr_state, next_state;

    // -------------------------------------------------
    // State register
    // -------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            curr_state <= S_CNT0;
        else
            curr_state <= next_state;
    end

    // -------------------------------------------------
    // Next state logic
    // -------------------------------------------------
    always @(*) begin
        // next_state = curr_state;

        if (count == 4'd0) begin
            next_state = S_CNT0;
        end
        else if (count == 4'd15) begin
            if (last_block)
                next_state = S_CNT15_LAST;
            else
                next_state = S_CNT15_MID;
        end
        else begin
            next_state = S_CNT_1_14;
        end
    end

    // -------------------------------------------------
    // Output logic (Moore style)
    // -------------------------------------------------
    always @(*) begin
        // default outputs
        case (next_state)
            S_CNT0: begin
    	        H_buff_en = 1'b0;
		comp_new_h = 1'b0;
        	H_load_in = 1'b0;
        	comp_done = 1'b0;
        	final_block = 1'b0;
        	H_update_en = 1'b1;
	end

            S_CNT_1_14: begin
                H_buff_en = 1'b0;
		comp_new_h = 1'b1;
        	H_load_in = 1'b1;
        	comp_done = 1'b0;
        	final_block = 1'b0;
        	H_update_en = 1'b1;
            end

            S_CNT15_MID: begin
                H_buff_en = 1'b1;
		comp_new_h = 1'b1;
        	H_load_in = 1'b1;
        	comp_done = 1'b1;
        	final_block = 1'b0;
        	H_update_en = 1'b1;
            end

            S_CNT15_LAST: begin
                H_buff_en = 1'b0;
		comp_new_h = 1'b1;
        	H_load_in = 1'b1;
        	comp_done = 1'b1;
        	final_block = 1'b1;
        	H_update_en = 1'b1;
            end

            default: begin
                H_buff_en = 1'b0;
		comp_new_h = 1'b0;
        	H_load_in = 1'b0;
        	comp_done = 1'b0;
        	final_block = 1'b0;
        	H_update_en = 1'b0;
            end
        endcase
    end

endmodule
*/

module sha256_compress_fsm  (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [4:0]  count,
    input  wire        last_block,

    output reg         H_buff_en,
    output reg         comp_new_h,
    output reg         H_load_in,
    output reg         comp_done,
    output reg         final_block,
    output reg         H_update_en
);

    // -------------------------------------------------
    // State encoding (4 states for 4 conditions)
    // -------------------------------------------------
    parameter S_CNT0_MID     = 3'b000;  // count == 0 && last_block == 0
    parameter S_CNT0_LAST    = 3'b001;  // count == 0 && last_block == 1
    parameter S_CNT1_14_MID  = 3'b010;  // count 1 to 14 && last_block == 0
    parameter S_CNT1_14_LAST = 3'b011;  // count 1 to 14 && last_block == 1
    parameter S_CNT15_MID    = 3'b100;  // count == 15 && last_block == 0
    parameter S_CNT15_LAST   = 3'b101;  // count == 15 && last_block == 1

    reg [2:0] curr_state, next_state;
    //reg last_block;
    // -------------------------------------------------
    // State register
    // -------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        curr_state <= S_CNT0_MID; end
          else begin
            curr_state <= next_state; end

      end

    // -------------------------------------------------
    // Next state logic
    // -------------------------------------------------
    always @(count or last_block) begin
        // next_state = curr_state;()
       if (count == 4'd0) begin
            /*if (last_block)
                next_state = S_CNT0_LAST;
            else*/
                next_state = S_CNT0_MID;
        end
        else if (count == 5'd16 /*&& curr_state != S_CNT0_MID*/ ) begin
          if (last_block) begin
                next_state = S_CNT15_LAST;
                //last_block = 1'b0; // added to reset the last_block
            end
            else
                next_state = S_CNT15_MID;
        end
        else if(count == 5'd15) begin
            if(last_block == 1'b1)
                next_state = S_CNT1_14_LAST;
        else
                next_state = S_CNT1_14_MID;
        end
        else 
            next_state = S_CNT0_LAST;
    end

    // -------------------------------------------------
    // Output logic (Moore style)
    // -------------------------------------------------
    always @(*) begin
        // default outputs
        case (next_state )
            S_CNT0_MID: begin
    	        H_buff_en = 1'b0;
		comp_new_h = 1'b0;
        	H_load_in = 1'b0;
        	comp_done = 1'b0;
        	final_block = 1'b0;
        	H_update_en = 1'b0;
	    end

            S_CNT1_14_MID: begin
                H_buff_en = 1'b0;
		comp_new_h = 1'b0;
        	H_load_in = 1'b1;
        	comp_done = 1'b1;
        	final_block = 1'b0;
        	H_update_en = 1'b0;
            end

            S_CNT15_MID: begin
                H_buff_en = 1'b1;
		comp_new_h = 1'b1;
        	H_load_in = 1'b1;
        	comp_done = 1'b0;
        	final_block = 1'b0;
        	H_update_en = 1'b1;
            end

            S_CNT0_LAST: begin
                H_buff_en = 1'b0;
		comp_new_h = 1'b0;
        	H_load_in = 1'b1;
        	comp_done = 1'b0;
        	final_block = 1'b0;
        	H_update_en = 1'b0;
            end

            S_CNT1_14_LAST: begin
                H_buff_en = 1'b0;
		comp_new_h = 1'b0;
        	H_load_in = 1'b1;
        	comp_done = 1'b1;
        	final_block = 1'b0;//for debug changed
        	H_update_en = 1'b1;
            end

            S_CNT15_LAST: begin
                H_buff_en = 1'b0;
		comp_new_h = 1'b0;
        	H_load_in = 1'b1;
        	comp_done = 1'b1;
        	final_block = 1'b1;
        	H_update_en = 1'b1;
            end

            default: begin
                H_buff_en = 1'b0;
		comp_new_h = 1'b0;
        	H_load_in = 1'b0;
        	comp_done = 1'b0;
        	final_block = 1'b0;
        	H_update_en = 1'b0;
            end
        endcase
    end

endmodule


