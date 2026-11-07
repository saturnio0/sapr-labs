module rspsignals
(
Q, Y
);
input [2:0] Q;
output [2:0] Y;
reg [2:0] Y;
always @(Q)
    case (Q)
        3'b 000 : Y = 3'b 010;
        3'b 001 : Y = 3'b 010;
        3'b 010 : Y = 3'b 001;
        3'b 011 : Y = 3'b 001;
        3'b 100 : Y = 3'b 010;
        3'b 101 : Y = 3'b 100;
        3'b 110 : Y = 3'b 010;
        3'b 111 : Y = 3'b 001;
    endcase
endmodule