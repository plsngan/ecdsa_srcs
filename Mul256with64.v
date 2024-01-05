`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/21/2023 11:35:00 PM
// Design Name: 
// Module Name: Mul256with64
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "state_define.vh"

module Mul256with64(clk, start, busy, A, B, C);

input clk, start;
input [255:0] A,B;
output busy;
output [511:0] C;

reg [63:0] a,b;
reg [319:0] Reg1,Reg2;
reg [511:0] C;
reg [4:0] state;
reg busy;

wire [127:0] c;

assign c = a * b;

always @(posedge clk or negedge start) begin
if(!start) begin    //Ready
    busy <= 0;
    C <= 512'b0;
    state <= `Init;
end else begin
    if(state == `Init) begin
    busy <= 1;
    //C <= 512'b0;
    Reg1 <= 320'b0;
    Reg2 <= 320'b0;
    a <= A[63:0];
    b <= B[63:0];
    state <= `Mul1;
    end else if(state == `Mul1) begin
    C[127:0] <= c;
    a <= A[63:0];
    b <= B[127:64];
    state <= `Mul2;
    end else if(state == `Mul2) begin
    C[191:64] <= C[191:64] + c;
    a <= A[63:0];
    b <= B[191:128];
    state <= `Mul3;
    end else if(state == `Mul3) begin
    C[255:128] <= C[255:128] + c;
    a <= A[63:0];
    b <= B[255:192];
    state <= `Mul4;
    end else if(state == `Mul4) begin
    C[319:192] <= C[319:192] + c;
    a <= A[127:64];
    b <= B[63:0];
    state <= `Mul5;
    end else if(state == `Mul5) begin
    Reg1[127:0] <= c;
    a <= A[127:64];
    b <= B[127:64];
    state <= `Mul6;
    end else if(state == `Mul6) begin
    Reg1[191:64] <= Reg1[191:64] + c;
    a <= A[127:64];
    b <= B[191:128];
    state <= `Mul7;
    end else if(state == `Mul7) begin
    Reg1[255:128] <= Reg1[255:128] + c;
    a <= A[127:64];
    b <= B[255:192];
    state <= `Mul8;
    end else if(state == `Mul8) begin
    Reg1[319:192] <= Reg1[319:192] + c;
    a <= A[191:128];
    b <= B[63:0];
    state <= `Mul9;
    end else if(state == `Mul9) begin
    C[383:64] <= C[383:64] + Reg1;
    Reg2[127:0] <= c;
    a <= A[191:128];
    b <= B[127:64];
    state <= `Mul10;
    end else if(state == `Mul10) begin
    Reg1 <= 320'b0;
    Reg2[191:64] <= Reg2[191:64] + c;
    a <= A[191:128];
    b <= B[191:128];
    state <= `Mul11;
    end else if(state == `Mul11) begin
    Reg2[255:128] <= Reg2[255:128] + c;
    a <= A[191:128];
    b <= B[255:192];
    state <= `Mul12;
    end else if(state == `Mul12) begin
    Reg2[319:192] <= Reg2[319:192] + c;
    a <= A[255:192];
    b <= B[63:0];
    state <= `Mul13;
    end else if(state == `Mul13) begin
    C[447:128] <= C[447:128] + Reg2;
    Reg1[127:0] <= c;
    a <= A[255:192];
    b <= B[127:64];
    state <= `Mul14;
    end else if(state == `Mul14) begin
    Reg1[191:64] <= Reg1[191:64] + c;
    a <= A[255:192];
    b <= B[191:128];
    state <= `Mul15;
    end else if(state == `Mul15) begin
    Reg1[255:128] <= Reg1[255:128] + c;
    a <= A[255:192];
    b <= B[255:192];
    state <= `Mul16;
    end else if(state == `Mul16) begin  
    Reg1[319:192] <= Reg1[319:192] + c;
    state <= `Add;
    end else if(state == `Add) begin
    C[511:192] <= C[511:192] + Reg1;
    state <= `Final;
    end else if(state == `Final) begin    
    busy <= 0;
    end
end
end
endmodule
