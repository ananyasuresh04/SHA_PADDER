`timescale 1ns/1ps

module padder_fsm (
    input  wire        clk,
    input  wire        rst,

    input  wire        msg_start,
    input  wire        msg_valid,
    input  wire        msg_end,

    input  wire [4:0]  word_count,        // 0–15
    input  wire        block_full,        // word_count == 15
    input  wire        overflow_required, // delimiter fits or not

    output reg  [1:0]  mux_sel,
    output reg         shift_en,
    output reg         pipo_load,
    output reg  [3:0]  state
);

    //====================================================
    // STATE ENCODING
    //====================================================
    localparam S_IDLE            = 4'd0;
    localparam S_READ_DATA       = 4'd1;
    localparam S_ADD_DELIMITER   = 4'd2;
    localparam S_PAD_ZEROS       = 4'd3;
    localparam S_ADD_LENGTH_HIGH = 4'd4;
    localparam S_ADD_LENGTH_LOW  = 4'd5;
    localparam S_OUT_BLOCK       = 4'd6;
    localparam S_WAIT_OVERFLOW   = 4'd7;
    localparam S_PAD_ZEROS_NEXT  = 4'd8;
    localparam S_OUT_BLOCK_NEXT  = 4'd9;

    reg [3:0] next_state;

    //====================================================
    // STATE REGISTER
    //====================================================
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    //====================================================
    // NEXT STATE LOGIC
    //====================================================
    always @(*) begin
        next_state = state;

        case (state)

            //------------------------------------------------
            S_IDLE: begin
                if (msg_start)
                    next_state = S_READ_DATA;
            end

            //------------------------------------------------
            S_READ_DATA: begin
                if (msg_valid && !msg_end)
                    next_state = S_READ_DATA;
                else if (msg_valid && msg_end)
                    next_state = S_ADD_DELIMITER;
                else if (block_full)
                    next_state = S_OUT_BLOCK;
            end

            //------------------------------------------------
            S_ADD_DELIMITER: begin
                if (block_full)
                    next_state = S_WAIT_OVERFLOW;
                else
                    next_state = S_PAD_ZEROS;
            end

            //------------------------------------------------
            S_PAD_ZEROS: begin
                if (block_full)
                    next_state = S_WAIT_OVERFLOW;
                else if (word_count == 5'd14)
                    next_state = S_ADD_LENGTH_HIGH;
            end

            //------------------------------------------------
            S_ADD_LENGTH_HIGH: begin
                next_state = S_ADD_LENGTH_LOW;
            end

            //------------------------------------------------
            S_ADD_LENGTH_LOW: begin
                next_state = S_OUT_BLOCK;
            end

            //------------------------------------------------
            S_OUT_BLOCK: begin
                next_state = S_IDLE;
            end

            //------------------------------------------------
            S_WAIT_OVERFLOW: begin
                next_state = S_PAD_ZEROS_NEXT;
            end

            //------------------------------------------------
            S_PAD_ZEROS_NEXT: begin
                if (word_count == 5'd14)
                    next_state = S_ADD_LENGTH_HIGH;
            end

            //------------------------------------------------
            S_OUT_BLOCK_NEXT: begin
                next_state = S_IDLE;
            end

        endcase
    end

    //====================================================
    // OUTPUT LOGIC
    //====================================================
    always @(*) begin

        shift_en  = 0;
        pipo_load = 0;
        mux_sel   = 2'b00;

        case(state)

            S_IDLE: begin end

            S_READ_DATA: begin
                shift_en = msg_valid;
                mux_sel  = 2'b00; // normal data
            end

            S_ADD_DELIMITER: begin
                shift_en = 1;
                mux_sel  = 2'b01; // delimiter
            end

            S_PAD_ZEROS: begin
                shift_en = 1;
                mux_sel  = 2'b10; // zeros
            end

            S_ADD_LENGTH_HIGH: begin
                shift_en = 1;
                mux_sel  = 2'b11; // length high
            end

            S_ADD_LENGTH_LOW: begin
                shift_en = 1;
                mux_sel  = 2'b11; // length low
            end

            S_OUT_BLOCK: begin
                pipo_load = 1;
            end

            S_WAIT_OVERFLOW: begin
                pipo_load = 1;
            end

            S_PAD_ZEROS_NEXT: begin
                shift_en = 1;
                mux_sel  = 2'b10;
            end

            S_OUT_BLOCK_NEXT: begin
                pipo_load = 1;
            end

        endcase
    end

endmodule
