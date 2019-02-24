`timescale 1ns/1ps

module sha256_padder_fsm (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        msg_valid,
    input  wire        msg_last,
    input  wire [1:0]  msg_last_bytes,
    input  wire [31:0] msg_data,

    output reg  [511:0] block_out,
    output reg          block_valid
);

    //--------------------------------------------------------------
    // FSM STATES (NO localparam)
    //--------------------------------------------------------------
    parameter S_IDLE = 3'd0;
    parameter S_PAD0 = 3'd1;
    parameter S_LEN  = 3'd2;
    parameter S_OUT1 = 3'd3;
    parameter S_OUT2 = 3'd4;
    parameter S_FULL = 3'd5;

    reg [2:0] state;

    //--------------------------------------------------------------
    // 16 WORDS — NO ARRAYS ? LINT CLEAN
    //--------------------------------------------------------------
    reg [31:0] blk0, blk1, blk2, blk3;
    reg [31:0] blk4, blk5, blk6, blk7;
    reg [31:0] blk8, blk9, blk10, blk11;
    reg [31:0] blk12, blk13, blk14, blk15;

    //--------------------------------------------------------------
    reg [4:0]  wc;
    reg [63:0] total_bytes;
    reg [63:0] bit_len;
    reg        overflow;

    reg [31:0] patched;   // moved OUTSIDE always block ? Verilog-95 OK


    //--------------------------------------------------------------
    // MAIN FSM
    //--------------------------------------------------------------
    always @(posedge clk ) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            wc           <= 5'd0;
            total_bytes  <= 64'd0;
            bit_len      <= 64'd0;
            overflow     <= 1'b0;
            block_valid  <= 1'b0;

            blk0 <= 0; blk1 <= 0; blk2 <= 0; blk3 <= 0;
            blk4 <= 0; blk5 <= 0; blk6 <= 0; blk7 <= 0;
            blk8 <= 0; blk9 <= 0; blk10 <= 0; blk11 <= 0;
            blk12 <= 0; blk13 <= 0; blk14 <= 0; blk15 <= 0;
        end
        else begin
            block_valid <= 1'b0;

            case(state)

            //==========================================================
            // IDLE — INPUT COLLECTION
            //==========================================================
            S_IDLE: begin
                if (msg_valid) begin

                    // FULL BLOCK BEFORE LAST FLAG
                    if (!msg_last && wc == 5'd16) begin
                        state <= S_FULL;
                    end

                    // NORMAL WORD
                    else if (!msg_last) begin
                        case(wc)
                            5'd0: blk0  <= msg_data;
                            5'd1: blk1  <= msg_data;
                            5'd2: blk2  <= msg_data;
                            5'd3: blk3  <= msg_data;
                            5'd4: blk4  <= msg_data;
                            5'd5: blk5  <= msg_data;
                            5'd6: blk6  <= msg_data;
                            5'd7: blk7  <= msg_data;
                            5'd8: blk8  <= msg_data;
                            5'd9: blk9  <= msg_data;
                            5'd10: blk10 <= msg_data;
                            5'd11: blk11 <= msg_data;
                            5'd12: blk12 <= msg_data;
                            5'd13: blk13 <= msg_data;
                            5'd14: blk14 <= msg_data;
                            5'd15: blk15 <= msg_data;
                        endcase

                        wc <= wc + 5'd1;
                        total_bytes <= total_bytes + 64'd4;

                        if (wc == 5'd15)
                            state <= S_FULL;
                    end

                    //==================================================
                    // LAST WORD — INSERT 0x80
                    //==================================================
                    else begin
                        // compute patch
                        if (msg_last_bytes == 2'd0)
                            patched = 32'h80000000;
                        else if (msg_last_bytes == 2'd1)
                            patched = {msg_data[31:24],8'h80,16'h0000};
                        else if (msg_last_bytes == 2'd2)
                            patched = {msg_data[31:16],8'h80,8'h00};
                        else
                            patched = {msg_data[31:8],8'h80};

                        // store into correct word
                        case(wc)
                            5'd0: blk0  <= patched;
                            5'd1: blk1  <= patched;
                            5'd2: blk2  <= patched;
                            5'd3: blk3  <= patched;
                            5'd4: blk4  <= patched;
                            5'd5: blk5  <= patched;
                            5'd6: blk6  <= patched;
                            5'd7: blk7  <= patched;
                            5'd8: blk8  <= patched;
                            5'd9: blk9  <= patched;
                            5'd10: blk10 <= patched;
                            5'd11: blk11 <= patched;
                            5'd12: blk12 <= patched;
                            5'd13: blk13 <= patched;
                            5'd14: blk14 <= patched;
                            5'd15: blk15 <= patched;
                        endcase

                        total_bytes <= total_bytes + msg_last_bytes;

                        overflow <= (wc >= 5'd14);
                        wc <= wc + 5'd1;

                        state <= S_PAD0;
                    end
                end
            end

            //==========================================================
            // ZERO PAD BLOCK
            //==========================================================
            S_PAD0: begin
                if (wc < 5'd16) begin
                    case(wc)
                        5'd0: blk0 <= 0;
                        5'd1: blk1 <= 0;
                        5'd2: blk2 <= 0;
                        5'd3: blk3 <= 0;
                        5'd4: blk4 <= 0;
                        5'd5: blk5 <= 0;
                        5'd6: blk6 <= 0;
                        5'd7: blk7 <= 0;
                        5'd8: blk8 <= 0;
                        5'd9: blk9 <= 0;
                        5'd10: blk10 <= 0;
                        5'd11: blk11 <= 0;
                        5'd12: blk12 <= 0;
                        5'd13: blk13 <= 0;
                        5'd14: blk14 <= 0;
                        5'd15: blk15 <= 0;
                    endcase

                    wc <= wc + 5'd1;
                end
                else begin
                    bit_len <= total_bytes << 3;
                    state <= S_LEN;
                end
            end

            //==========================================================
            // INSERT MESSAGE LENGTH
            //==========================================================
            S_LEN: begin
                if (!overflow) begin
                    blk14 <= bit_len[63:32];
                    blk15 <= bit_len[31:0];
                end
                state <= S_OUT1;
            end

            //==========================================================
            // OUTPUT BLOCK 1
            //==========================================================
            S_OUT1: begin
                block_out <= {
                    blk0, blk1, blk2, blk3,
                    blk4, blk5, blk6, blk7,
                    blk8, blk9, blk10, blk11,
                    blk12, blk13, blk14, blk15
                };
                block_valid <= 1'b1;

                if (overflow) begin
                    blk0 <= 0; blk1 <= 0; blk2 <= 0; blk3 <= 0;
                    blk4 <= 0; blk5 <= 0; blk6 <= 0; blk7 <= 0;
                    blk8 <= 0; blk9 <= 0; blk10 <= 0; blk11 <= 0;
                    blk12 <= 0; blk13 <= 0;
                    blk14 <= bit_len[63:32];
                    blk15 <= bit_len[31:0];
            	    // block_valid <= 1'b1;

                    wc <= 0;
                    state <= S_OUT2;
                end
                else begin
                    wc <= 0;
                    total_bytes <= 0;
                    overflow <= 0;

                    blk0 <= 0; blk1 <= 0; blk2 <= 0; blk3 <= 0;
                    blk4 <= 0; blk5 <= 0; blk6 <= 0; blk7 <= 0;
                    blk8 <= 0; blk9 <= 0; blk10 <= 0; blk11 <= 0;
                    blk12 <= 0; blk13 <= 0; blk14 <= 0; blk15 <= 0;
                    state <= S_IDLE;
                end
            end

            //==========================================================
            // OUTPUT BLOCK 2 (IF OVERFLOW)
            //==========================================================
            S_OUT2: begin
                block_out <= {
                    blk0, blk1, blk2, blk3,
                    blk4, blk5, blk6, blk7,
                    blk8, blk9, blk10, blk11,
                    blk12, blk13, blk14, blk15
                };
                block_valid <= 1'b1;

                wc <= 0;
                total_bytes <= 0;
                overflow <= 0;

                blk0 <= 0; blk1 <= 0; blk2 <= 0; blk3 <= 0;
                blk4 <= 0; blk5 <= 0; blk6 <= 0; blk7 <= 0;
                blk8 <= 0; blk9 <= 0; blk10 <= 0; blk11 <= 0;
                blk12 <= 0; blk13 <= 0; blk14 <= 0; blk15 <= 0;
                state <= S_IDLE;
            end


            //==========================================================
            // FULL 512-BIT DATA BLOCK
            //==========================================================
            S_FULL: begin
                block_out <= {
                    blk0, blk1, blk2, blk3,
                    blk4, blk5, blk6, blk7,
                    blk8, blk9, blk10, blk11,
                    blk12, blk13, blk14, blk15
                };
                block_valid <= 1'b1;

                wc <= 0;

                blk0 <= 0; blk1 <= 0; blk2 <= 0; blk3 <= 0;
                blk4 <= 0; blk5 <= 0; blk6 <= 0; blk7 <= 0;
                blk8 <= 0; blk9 <= 0; blk10 <= 0; blk11 <= 0;
                blk12 <= 0; blk13 <= 0; blk14 <= 0; blk15 <= 0;

                state <= S_IDLE;
            end

            endcase
        end
    end

endmodule

