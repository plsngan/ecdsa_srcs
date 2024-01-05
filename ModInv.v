`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/21/2023 11:36:15 PM
// Design Name: 
// Module Name: ModInv
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

module ModInv(clk, A, B, start, busy);

input [255:0] A;
input start, clk;
output [255:0] B;
output busy;

reg [255:0] u, v, x, y, B;
reg [1:0] state;
reg busy;

wire [256:0] Reg1, Reg2, Reg3,Reg4; 

assign        Reg1 = u - v;
assign        Reg2 = x - y;
assign        Reg3 = x + `prime;
assign        Reg4 = y + `prime;

always @(posedge clk or negedge start) begin
if(!start) begin    //Ready
    busy <= 0;
    state <= `Init;
end else begin
    if(state == `Init) begin    //Initialization
        busy <= 1;
        u <= A;
        v <= `prime;
        x <= 1;
        y <= 0;
        state <= `ModInv;
    end else if(state == `ModInv) begin
        if((u != 1) && (v != 1)) begin
            if(u[0]==0) begin
              u <= {1'b0,u[255:1]};
              x <= (x[0])? Reg3[256:1] : {1'b0,x[255:1]} ;
            end
            if(v[0]==0) begin
              v <= {1'b0,v[255:1]};
              y <= (y[0])? Reg4[256:1] : {1'b0,y[255:1]} ;
            end
            if((u[0])&&(v[0])) begin
                if (Reg1[256]) begin
                    v <= (v - u);
                    y <= (Reg2[256])? (y - x):(y - x + `prime);
                end else begin
                    u <= (u - v);
                    x <= (Reg2[256])? (x - y + `prime):(x - y);
                end
            end
        end else begin
            B <= (u == 1)? x:y ;
            state <= `invFinal;
        end
    end else begin
        busy <= 0;  //final state
    end
    end
end
endmodule