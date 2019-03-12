module sha256_padder_datapath (
    input wire clk,
    input wire reset,
    input wire [31:0] msg_data,
    input wire [1:0]  valid_bytes, 
    input wire [1:0] mux_sel,
    input wire shift_en,
    input wire counter_reset,
    input wire len_latch_en,
    
    output wire [3:0] word_count,
    output wire is_last_full,
    output wire [511:0] M_block
);

    reg [3:0] w_ctr;
    always @(posedge clk or posedge reset) begin
        if (reset || counter_reset) w_ctr <= 0;
        else if (shift_en) w_ctr <= w_ctr + 1;
    end
    assign word_count = w_ctr;

    // Length Calculation
    reg [63:0] total_bit_len;
    reg [63:0] latched_len;
    reg [5:0] current_bits;
    
    always @(*) begin
        case(valid_bytes)
            2'b00: current_bits = 32; 
            2'b01: current_bits = 8;
            2'b10: current_bits = 16;
            2'b11: current_bits = 24;
        endcase
    end
    assign is_last_full = (valid_bytes == 2'b00);

    // RESET LOGIC: Clears length on hardware reset
    always @(posedge clk or posedge reset) begin
        if (reset) total_bit_len <= 0; 
        else if (shift_en && mux_sel == 2'b00) total_bit_len <= total_bit_len + current_bits;
    end

    always @(posedge clk) begin
        if (len_latch_en) latched_len <= total_bit_len + current_bits;
    end

    // Padding Logic
    reg [31:0] padded_data_comb;
    always @(*) begin
        if (is_last_full) padded_data_comb = 32'h80000000;
        else begin
            case(valid_bytes)
                2'b01: padded_data_comb = {msg_data[31:24], 8'h80, 16'h00};
                2'b10: padded_data_comb = {msg_data[31:16], 8'h80, 8'h00};
                2'b11: padded_data_comb = {msg_data[31:8],  8'h80};
                default: padded_data_comb = 32'h80000000;
            endcase
        end
    end

    // MUX
    reg [31:0] shift_in_data;
    always @(*) begin
        case(mux_sel)
            2'b00: shift_in_data = msg_data;              
            2'b01: shift_in_data = padded_data_comb;      
            2'b10: shift_in_data = 32'd0;                 
            2'b11: begin
                if (w_ctr == 14) shift_in_data = latched_len[63:32];
                else             shift_in_data = latched_len[31:0];
            end
        endcase
    end

    // SIPO Register
    reg [511:0] block_reg;
    always @(posedge clk or posedge reset) begin
        if (reset || counter_reset) block_reg <= 0; 
        else if (shift_en) block_reg[ (15 - w_ctr)*32 +: 32 ] <= shift_in_data;
    end

    assign M_block = block_reg;
endmodule
