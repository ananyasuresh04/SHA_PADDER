`timescale 1ns/1ps
 
module byte_counter(
    input  clk,                     //Clock signal.
    input rst,                      //Resets byte counter to zero.
    input msg_start,                //Indicates start of a new message.
    input msg_valid,               //Asserted when incoming message word is valid and accepted.
    input wire [2:0] valid_bytes,  //Number of valid message bytes in the current word (1-4)
    input msg_end,                 //Indicates end of message.
     input wire word_en,
    output reg [63:0] byte_count,  //Total number of message bytes.
    output wire [63:0] bit_length,   //Total message length in bits.
    output reg length_ready            //Asserted when full message length is available.

);


// BYTE COUNTER
 always @(posedge clk) begin
        if (rst || msg_start)
            byte_count <= 64'd0;
        else if (msg_valid && word_en)
            byte_count <= byte_count + valid_bytes;
    end
// BIT LENGTH (BYTES ? BITS)
assign bit_length = byte_count << 3;

// LENGTH READY FLAG
 always @(posedge clk) begin
        if (rst || msg_start)
            length_ready <= 1'b0;
        else if (msg_end && msg_valid && word_en)
            length_ready <= 1'b1;
    end
endmodule
