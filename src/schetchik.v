module schetchik
(
C, R, D, Q
);
input C;
input R;
input [2:0] D;
output [2:0] Q;
reg [2:0] Q;
always @(D)
    case (D)
        3'b 000 : Q = 3'b 111;
        3'b 001 : Q = 3'b 000;
        3'b 010 : Q = 3'b 001;
        3'b 011 : Q = 3'b 010;
        3'b 100 : Q = 3'b 011;
        3'b 101 : Q = 3'b 100;
        3'b 110 : Q = 3'b 101;
        3'b 111 : Q = 3'b 110;
    endcase
endmodule