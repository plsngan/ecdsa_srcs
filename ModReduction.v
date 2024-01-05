`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/21/2023 11:37:08 PM
// Design Name: 
// Module Name: ModReduction
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

module ModRed(clk, start, busy, A, B);

input clk, start;
input [511:0] A;
output busy;
output [255:0] B;

reg busy;
reg [511:0] Reg;
reg [255:0] B, RegH, RegL;
reg [3:0] state;

always @(posedge clk or negedge start) begin
if(!start) begin    //Ready
    busy <= 0;
    state <= `Init;
end else begin
    if(state == `Init) begin    //Initialization
        {RegH, RegL} <= A;
        busy <= 1;
        state <= `Mod1;       
    end else if(state == `Mod1) begin
        Reg <= {256'b0, RegH} + {256'b0, RegL};
        state <= `Mod2;
    end else if(state == `Mod2) begin
        Reg <= {252'b0, RegH, 4'b0} + Reg;
        state <= `Mod3;
    end else if(state == `Mod3) begin
        Reg <= {250'b0, RegH, 6'b0} + Reg;
        state <= `Mod4;
    end else if(state == `Mod4) begin
        Reg <= {249'b0, RegH, 7'b0} + Reg;
        state <= `Mod5;
    end else if(state == `Mod5) begin
        Reg <= {248'b0, RegH, 8'b0} + Reg;
        state <= `Mod6;
    end else if(state == `Mod6) begin
        Reg <= {247'b0, RegH, 9'b0} + Reg;
        state <= `Mod7;
    end else if(state == `Mod7) begin
        Reg <= {224'b0, RegH, 32'b0} + Reg;
        state <= `Mod8;
    end else if(state == `Mod8) begin
        if(Reg[511:256] != 256'b0) begin
            {RegH, RegL} <= Reg;
            state <= `Mod1;
        end else begin
            B <= Reg[255:0];
            state <= `Finish;
        end
    end else begin
        busy <= 0;  //finish state
    end
end
end

endmodule