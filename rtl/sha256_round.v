
`timescale 1ns/1ps

module sha256_round (
    input  [31:0] a,b,c,d,e,f,g,h,
    input  [31:0] w,
    input  [31:0] k,
    output [31:0] ao,bo,co,do,eo,fo,go,ho
);
    function [31:0] ROTR(input [31:0] x, input integer n);
        ROTR = (x >> n) | (x << (32-n));
//        ROTR = {x[n:0],x >> n};
    endfunction
    function [31:0] Ch(input [31:0] x,y,z);
        Ch = (x & y) ^ (~x & z);
    endfunction
    function [31:0] Maj(input [31:0] x,y,z);
        Maj = (x & y) ^ (x & z) ^ (y & z);
    endfunction
    function [31:0] S0(input [31:0] x);
        S0 = ROTR(x,2) ^ ROTR(x,13) ^ ROTR(x,22);
    endfunction
    function [31:0] S1(input [31:0] x);
        S1 = ROTR(x,6) ^ ROTR(x,11) ^ ROTR(x,25);
    endfunction

    wire [31:0] T1;
    wire [31:0] T2; 
    
    assign T1 = h + S1(e) + Ch(e,f,g) + k + w;

    assign T2 = S0(a) + Maj(a,b,c);

    assign ao = T1 + T2;
    assign bo = a;
    assign co = b;
    assign do = c;
    assign eo = d + T1;
    assign fo = e;
    assign go = f;
    assign ho = g;
endmodule

