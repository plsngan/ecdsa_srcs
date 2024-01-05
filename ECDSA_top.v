`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/21/2023 11:38:05 PM
// Design Name: 
// Module Name: ECDSA_top
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

module ECDSA(clk, message, key, sign, start, busy);

input clk, start;
input [511:0] message;
input [255:0] key;
output [511:0] sign;
output busy;

wire [255:0] h;
reg [255:0] k,hash,private,X,Y,Z,x,y,X1,Y1,Z1,X2,Y2,Z2,A,B,C,D,E,F,nReg,a1,a2,s1,s2,mulA,mulB,inv_in;
reg [511:0] U,sign;
reg [2:0] main_state;
reg [4:0] XYZconv_state,xyconv_state,sign_state;
reg [6:0] state;
reg [7:0] swap_count;
reg [8:0] count;
reg busy, mul_start, red_start, inv_start, hash_start;

wire [255:0] add, sub, red_out, Zinv;
wire [511:0] mul_out;
wire [256:0] addx, subx;
wire mul_busy, red_busy, inv_busy, hash_busy;


overall sha256_pipeline (.clk(clk), .reset(!hash_start), .message(message), .ready(hash_busy), .hashvalue(h));
Mul256with64 mul(.clk(clk),.start(mul_start),.busy(mul_busy),.A(mulA),.B(mulB),.C(mul_out));
ModRed red(.clk(clk),.start(red_start),.busy(red_busy),.A(U),.B(red_out));
ModInv inv(.clk(clk),.A(inv_in),.B(Zinv),.start(inv_start),.busy(inv_busy));

assign      addx = a1 + a2;
assign      add  = (addx[256])? (a1 + a2 - `prime):(a1 + a2);
assign      subx = s1 - s2;
assign      sub  = (subx[256])? (s1 - s2 + `prime):(s1 - s2);

always @(posedge clk or negedge start) begin
if(!start) begin    //Ready
    busy <= 0;
    main_state <= `Init;
end else begin

    if(main_state == `Init) begin    //Initialization
        busy <= 1;
        count <= 9'd256;
        XYZconv_state <= `conv1a;
        state <= `Double1a;
        xyconv_state <= `conv0a;
        sign_state <= `Sign0a;
        mul_start <= 0; //Reset multiplier *important
        red_start <= 0; //Reset modred *important
        inv_start <= 0; //Reset inv *important  
        hash_start <= 0;    
        private <= key;
        main_state <= `Hash;
    end else if (main_state == `Hash) begin
        busy <= 1;
        hash_start <= 1;
        XYZconv_state <= `conv1a;
        state <= `Double1a;
        xyconv_state <= `conv0a;
        sign_state <= `Sign0a;
        if (hash_busy == 1) begin
            nReg <= h + key;
            k <= h + key;
            hash <= h;
        end 
        main_state <= (hash_busy == 1)?`XYZ: `Hash;  
    end else if(main_state == `XYZ) begin
        if(XYZconv_state == `conv1a) begin
            Z <= k;
        // mul(k, k)
            mul_start <= 1;
            mulA <= k;
            mulB <= k;
            XYZconv_state <= `conv1b;
        end else if(XYZconv_state == `conv1b) begin
            XYZconv_state <= `conv1c; // wait 1 clk
        end else if(XYZconv_state == `conv1c) begin
            XYZconv_state <= (mul_busy == 1)? `conv1c:`conv1d;
        end else if(XYZconv_state == `conv1d) begin
            mul_start <= 0;
            U <= mul_out;
            XYZconv_state <= `conv2a;
        end else if(XYZconv_state == `conv2a) begin
        // mulred(Gy, k, A)
            mul_start <= 1;
            red_start <= 1;
            mulA <= `Gy;
            mulB <= k;
            XYZconv_state <= `conv2b;
        end else if(XYZconv_state == `conv2b) begin
            XYZconv_state <= `conv2c; // wait 1 clk
        end else if(XYZconv_state == `conv2c) begin
            XYZconv_state <= ((red_busy == 0)&&(mul_busy == 0))? `conv2d:`conv2c;
        end else if(XYZconv_state == `conv2d) begin
            U <= mul_out;
            A <= red_out;
            mul_start <= 0;
            red_start <= 0;
            XYZconv_state <= `conv3a;
        end else if(XYZconv_state == `conv3a) begin
        // mulred(Gx, A, B)
            mul_start <= 1;
            red_start <= 1;
            mulA <= `Gx;
            mulB <= A;
            XYZconv_state <= `conv3b;
        end else if(XYZconv_state == `conv3b) begin
            XYZconv_state <= `conv3c; // wait 1 clk
        end else if(XYZconv_state == `conv3c) begin
            XYZconv_state <= ((red_busy == 0)&&(mul_busy == 0))? `conv3d:`conv3c;
        end else if(XYZconv_state == `conv3d) begin
            U <= mul_out;
            B <= red_out;
            mul_start <= 0;
            red_start <= 0;
            XYZconv_state <= `conv4a;
        end else if(XYZconv_state == `conv4a) begin
        // mulred(B, A, X)
            mul_start <= 1;
            red_start <= 1;
            mulA <= B;
            mulB <= A;
            XYZconv_state <= `conv4b;
        end else if(XYZconv_state == `conv4b) begin
            XYZconv_state <= `conv4c; // wait 1 clk
        end else if(XYZconv_state == `conv4c) begin
            XYZconv_state <= ((red_busy == 0)&&(mul_busy == 0))? `conv4d:`conv4c;
        end else if(XYZconv_state == `conv4d) begin
            U <= mul_out;
            X <= red_out;
            mul_start <= 0;
            red_start <= 0;
            XYZconv_state <= `conv5a;
        end else if(XYZconv_state == `conv5a) begin
        // red(Y)
            red_start <= 1;
            XYZconv_state <= `conv5b;
        end else if(XYZconv_state == `conv5b) begin
            XYZconv_state <= `conv5c; // wait 1 clk
        end else if(XYZconv_state == `conv5c) begin
            XYZconv_state <= (red_busy == 1)? `conv5c:`conv5d;
        end else if(XYZconv_state == `conv5d) begin
            Y <= red_out;
            red_start <= 0;            
            XYZconv_state <= `conv_final;
        end else if(XYZconv_state == `conv_final) begin
            {X1,Y1,Z1} <= (nReg[0])? {X,Y,Z}:{256'b1, 256'b1, 256'b1};
            {X2,Y2,Z2} <= (nReg[0])? {256'b1, 256'b1, 256'b1}:{X,Y,Z};
            swap_count <= (nReg[0])? 8'b0:8'b1;
            main_state <= `ML;
        end

    end else if(main_state == `ML) begin
        if(count != 0) begin
            if(state == `Double1a) begin
            //wait_mul(Y1, Y1);
                mul_start <= 1;
                mulA <= Y1;
                mulB <= Y1;
                state <= `Double1b;
            end else if(state == `Double1b) begin
                state <= `Double1c; // wait 1 clk
            end else if(state == `Double1c) begin
                state <= (mul_busy == 1)? `Double1c:`Double1d;
            end else if(state == `Double1d) begin
                mul_start <= 0;
                U <= mul_out;
                state <= `Double1e;
            end else if(state == `Double1e) begin
            //wait_add(X1, X1, C);
                a1 <= X1;
                a2 <= X1;
                state <= `Double1f;
            end else if(state == `Double1f) begin
                C <= add;
                state <= `Double1g;
            end else if(state == `Double1g) begin
            //wait_add(C, X1, D);
                a1 <= C;
                a2 <= X1;
                state <= `Double1h;
            end else if(state == `Double1h) begin
                D <= add;
                state <= `Double2a;
            end else if(state == `Double2a) begin
            //wait_mulred(X1, D, B);
                mul_start <= 1;
                red_start <= 1;
                mulA <= X1;
                mulB <= D;
                state <= `Double2b;
            end else if(state == `Double2b) begin
                state <= `Double2c; // wait 1 clk
            end else if(state == `Double2c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Double2d:`Double2c;
            end else if(state == `Double2d) begin
                U <= mul_out;
                B <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Double2e;
            end else if(state == `Double2e) begin
            //wait_add(B, B, B);
                a1 <= B;
                a2 <= B;
                state <= `Double2f;
            end else if(state == `Double2f) begin
                B <= add;
                state <= `Double2g;
            end else if(state == `Double2g) begin
            //wait_add(B, B, C);
                a1 <= B;
                a2 <= B;
                state <= `Double2h;
            end else if(state == `Double2h) begin
                C <= add;
                state <= `Double3a;                
            end else if(state == `Double3a) begin
            //wait_mulred(C, X1, A);
                mul_start <= 1;
                red_start <= 1;
                mulA <= C;
                mulB <= X1;
                state <= `Double3b;
            end else if(state == `Double3b) begin
                state <= `Double3c; // wait 1 clk
            end else if(state == `Double3c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Double3d:`Double3c;
            end else if(state == `Double3d) begin
                U <= mul_out;
                A <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Double4a;
            end else if(state == `Double4a) begin
            //wait_mulred(C, B, D);
                mul_start <= 1;
                red_start <= 1;
                mulA <= C;
                mulB <= B;
                state <= `Double4b;
            end else if(state == `Double4b) begin
                state <= `Double4c; // wait 1 clk
            end else if(state == `Double4c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Double4d:`Double4c;
            end else if(state == `Double4d) begin
                U <= mul_out;
                D <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Double5a;
            end else if(state == `Double5a) begin
            //wait_mulred(A, A, C);
            //wait_add(D, D, E);
                mul_start <= 1;
                red_start <= 1;
                mulA <= A;
                mulB <= A;
                a1 <= D;
                a2 <= D;
                state <= `Double5b;
            end else if(state == `Double5b) begin
                E <= add;
                state <= `Double5c; // wait 1 clk
            end else if(state == `Double5c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Double5d:`Double5c;
            end else if(state == `Double5d) begin
                U <= mul_out;
                C <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Double5e;                
            end else if(state == `Double5e) begin
            //wait_add(Z1, Z1, Z1);
                a1 <= Z1;
                a2 <= Z1;
                state <= `Double5f;
            end else if(state == `Double5f) begin
                Z1 <= add;
                state <= `Double6a;  
            end else if(state == `Double6a) begin
            //wait_mulred(Y1, Z1, B);
                mul_start <= 1;
                red_start <= 1;
                mulA <= Y1;
                mulB <= Z1;
                state <= `Double6b;
            end else if(state == `Double6b) begin
                state <= `Double6c; // wait 1 clk
            end else if(state == `Double6c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Double6d:`Double6c;
            end else if(state == `Double6d) begin
                U <= mul_out;
                B <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Double6e;
            end else if(state == `Double6e) begin
            //wait_sub(B, E, X1);
                s1 <= B;
                s2 <= E;    
                state <= `Double6f;
            end else if(state == `Double6f) begin
                X1 <= sub;
                state <= `Double6g;      
            end else if(state == `Double6g) begin
            //wait_sub(D, X1, D);
                s1 <= D;
                s2 <= X1;    
                state <= `Double6h;
            end else if(state == `Double6h) begin
                D <= sub;
                state <= `Double7a; 
            end else if(state == `Double7a) begin
            //wait_mulred(D, A, Z1);
                mul_start <= 1;
                red_start <= 1;
                mulA <= D;
                mulB <= A;
                state <= `Double7b;
            end else if(state == `Double7b) begin
                state <= `Double7c; // wait 1 clk
            end else if(state == `Double7c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Double7d:`Double7c;
            end else if(state == `Double7d) begin
                U <= mul_out;
                Z1 <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Double8a;                
            end else if(state == `Double8a) begin
            //wait_red(Y1);
                red_start <= 1;
                state <= `Double8b;
            end else if(state == `Double8b) begin
                state <= `Double8c; // wait 1 clk
            end else if(state == `Double8c) begin
                state <= (red_busy == 1)? `Double8c:`Double8d;
            end else if(state == `Double8d) begin
                Y1 <= red_out;
                red_start <= 0;
                state <= `Double8e;
            end else if(state == `Double8e) begin
            //wait_sub(Y1, C, Y1);
                s1 <= Y1;
                s2 <= C;    
                state <= `Double8f;
            end else if(state == `Double8f) begin
                Y1 <= sub;
                state <= `Add1a;
            end else if(state == `Add1a) begin
            //wait_mul(Z1, Z1);
                mul_start <= 1;
                mulA <= Z1;
                mulB <= Z1;
                state <= `Add1b;
            end else if(state == `Add1b) begin
                state <= `Add1c; // wait 1 clk
            end else if(state == `Add1c) begin
                state <= (mul_busy == 1)? `Add1c:`Add1d;
            end else if(state == `Add1d) begin
                mul_start <= 0;
                U <= mul_out;
                state <= `Add2a;
            end else if(state == `Add2a) begin
            //wait_mulred(Z2, Z2, A);
                mul_start <= 1;
                red_start <= 1;
                mulA <= Z2;
                mulB <= Z2;
                state <= `Add2b;
            end else if(state == `Add2b) begin
                state <= `Add2c; // wait 1 clk
            end else if(state == `Add2c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Add2d:`Add2c;
            end else if(state == `Add2d) begin
                U <= mul_out;
                A <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Add3a; 
            end else if(state == `Add3a) begin
            //wait_mulred(A, Z1, E);
                mul_start <= 1;
                red_start <= 1;
                mulA <= A;
                mulB <= Z1;
                state <= `Add3b;
            end else if(state == `Add3b) begin
                state <= `Add3c; // wait 1 clk
            end else if(state == `Add3c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Add3d:`Add3c;
            end else if(state == `Add3d) begin
                U <= mul_out;
                E <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Add4a; 
            end else if(state == `Add4a) begin
            //wait_mulred(E, Z2, B);
                mul_start <= 1;
                red_start <= 1;
                mulA <= E;
                mulB <= Z2;
                state <= `Add4b;
            end else if(state == `Add4b) begin
                state <= `Add4c; // wait 1 clk
            end else if(state == `Add4c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Add4d:`Add4c;
            end else if(state == `Add4d) begin
                U <= mul_out;
                B <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Add5a; 
            end else if(state == `Add5a) begin
            //wait_mulred(A, X2, F);
                mul_start <= 1;
                red_start <= 1;
                mulA <= A;
                mulB <= X2;
                state <= `Add5b;
            end else if(state == `Add5b) begin
                state <= `Add5c; // wait 1 clk
            end else if(state == `Add5c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Add5d:`Add5c;
            end else if(state == `Add5d) begin
                U <= mul_out;
                F <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Add6a; 
            end else if(state == `Add6a) begin
            //wait_mulred(B, Y2, A);
                mul_start <= 1;
                red_start <= 1;
                mulA <= B;
                mulB <= Y2;
                state <= `Add6b;
            end else if(state == `Add6b) begin
                state <= `Add6c; // wait 1 clk
            end else if(state == `Add6c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Add6d:`Add6c;
            end else if(state == `Add6d) begin
                U <= mul_out;
                A <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Add7a; 
            end else if(state == `Add7a) begin
            //wait_mulred(E, X1, B);
                mul_start <= 1;
                red_start <= 1;
                mulA <= E;
                mulB <= X1;
                state <= `Add7b;
            end else if(state == `Add7b) begin
                state <= `Add7c; // wait 1 clk
            end else if(state == `Add7c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Add7d:`Add7c;
            end else if(state == `Add7d) begin
                U <= mul_out;
                B <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Add8a; 
            end else if(state == `Add8a) begin
            //wait_mulred(F, Y1, E);
                mul_start <= 1;
                red_start <= 1;
                mulA <= F;
                mulB <= Y1;
                state <= `Add8b;
            end else if(state == `Add8b) begin
                state <= `Add8c; // wait 1 clk
            end else if(state == `Add8c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Add8d:`Add8c;
            end else if(state == `Add8d) begin
                U <= mul_out;
                E <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Add9a; 
            end else if(state == `Add9a) begin
            //wait_mulred(Z1, Z2, F);
            //wait_sub(A, E, A);
                mul_start <= 1;
                red_start <= 1;
                mulA <= Z1;
                mulB <= Z2;
                s1 <= A;
                s2 <= E;
                state <= `Add9b;
            end else if(state == `Add9b) begin
                A <= sub;                
                state <= `Add9c; // wait 1 clk
            end else if(state == `Add9c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Add9d:`Add9c;
            end else if(state == `Add9d) begin
                U <= mul_out;
                F <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Add10a;
            end else if(state == `Add10a) begin
            //wait_mulred(A, A, D);
            //wait_sub(B, F, B);
                mul_start <= 1;
                red_start <= 1;
                mulA <= A;
                mulB <= A;
                s1 <= B;
                s2 <= F;                
                state <= `Add10b;
            end else if(state == `Add10b) begin
                B <= sub;                
                state <= `Add10c; // wait 1 clk
            end else if(state == `Add10c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Add10d:`Add10c;
            end else if(state == `Add10d) begin
                U <= mul_out;
                D <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Add11a; 
            end else if(state == `Add11a) begin
            //wait_mulred(A, D, C);
                mul_start <= 1;
                red_start <= 1;
                mulA <= A;
                mulB <= D;
                state <= `Add11b;
            end else if(state == `Add11b) begin
                state <= `Add11c; // wait 1 clk
            end else if(state == `Add11c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Add11d:`Add11c;
            end else if(state == `Add11d) begin
                U <= mul_out;
                C <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Add12a; 
            end else if(state == `Add12a) begin
            //wait_mulred(C, A, Z2);
                mul_start <= 1;
                red_start <= 1;
                mulA <= C;
                mulB <= A;
                state <= `Add12b;
            end else if(state == `Add12b) begin
                state <= `Add12c; // wait 1 clk
            end else if(state == `Add12c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Add12d:`Add12c;
            end else if(state == `Add12d) begin
                U <= mul_out;
                Z2 <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Add13a;
            end else if(state == `Add13a) begin
            //wait_mulred(C, E, D);
                mul_start <= 1;
                red_start <= 1;
                mulA <= C;
                mulB <= E;
                state <= `Add13b;
            end else if(state == `Add13b) begin
                state <= `Add13c; // wait 1 clk
            end else if(state == `Add13c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Add13d:`Add13c;
            end else if(state == `Add13d) begin
                U <= mul_out;
                D <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Add14a; 
            end else if(state == `Add14a) begin
            //wait_mulred(B, B, C);
                mul_start <= 1;
                red_start <= 1;
                mulA <= B;
                mulB <= B;
                state <= `Add14b;
            end else if(state == `Add14b) begin
                state <= `Add14c; // wait 1 clk
            end else if(state == `Add14c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Add14d:`Add14c;
            end else if(state == `Add14d) begin
                U <= mul_out;
                C <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Add15a; 
            end else if(state == `Add15a) begin
            //wait_mulred(D, F, X2);
            //wait_add(C, C, A);
                mul_start <= 1;
                red_start <= 1;
                mulA <= D;
                mulB <= F;
                a1 <= C;
                a2 <= C;
                state <= `Add15b;
            end else if(state == `Add15b) begin
                A <= add;
                state <= `Add15c; // wait 1 clk
            end else if(state == `Add15c) begin
                state <= ((red_busy == 0)&&(mul_busy == 0))? `Add15d:`Add15c;
            end else if(state == `Add15d) begin
                U <= mul_out;
                X2 <= red_out;
                mul_start <= 0;
                red_start <= 0;
                state <= `Add15e; 
            end else if(state == `Add15e) begin
            //wait_add(A, D, A);
                a1 <= A;
                a2 <= D;
                state <= `Add15f;
            end else if(state == `Add15f) begin
                A <= add;
                state <= `Add16a;
            end else if(state == `Add16a) begin
            //wait_red(D);
            //wait_sub(X2, A, X2);
                s1 <= X2;
                s2 <= A;
                red_start <= 1;
                state <= `Add16b;
            end else if(state == `Add16b) begin
                X2 <= sub;
                state <= `Add16c; // wait 1 clk
            end else if(state == `Add16c) begin
                state <= (red_busy == 1)? `Add16c:`Add16d;
            end else if(state == `Add16d) begin
                D <= red_out;
                red_start <= 0;
                state <= `Add16e;
            end else if(state == `Add16e) begin
            //wait_sub(C, X2, C);
                s1 <= C;
                s2 <= X2;    
                state <= `Add16f;
            end else if(state == `Add16f) begin
                C <= sub;
                state <= `Add17a;
            end else if(state == `Add17a) begin
            //wait_mul(B, C);
                mul_start <= 1;
                mulA <= B;
                mulB <= C;
                state <= `Add17b;
            end else if(state == `Add17b) begin
                state <= `Add17c; // wait 1 clk
            end else if(state == `Add17c) begin
                state <= (mul_busy == 1)? `Add17c:`Add17d;
            end else if(state == `Add17d) begin
                mul_start <= 0;
                U <= mul_out;
                state <= `Add18a;
            end else if(state == `Add18a) begin
            //wait_red(C);
                red_start <= 1;
                state <= `Add18b;
            end else if(state == `Add18b) begin
                state <= `Add18c; // wait 1 clk
            end else if(state == `Add18c) begin
                state <= (red_busy == 1)? `Add18c:`Add18d;
            end else if(state == `Add18d) begin
                C <= red_out;
                red_start <= 0;
                state <= `Add18e;
            end else if(state == `Add18e) begin
            //wait_sub(C, D, Y2);
                s1 <= C;
                s2 <= D;    
                state <= `Add18f;
            end else if(state == `Add18f) begin
                Y2 <= sub;
                state <= `MLswap; 
            end else if(state == `MLswap) begin
                {X1,Y1,Z1} <= (nReg[1]^nReg[0])? {X2,Y2,Z2}:{X1,Y1,Z1};
                {X2,Y2,Z2} <= (nReg[1]^nReg[0])? {X1,Y1,Z1}:{X2,Y2,Z2};
                swap_count <= (nReg[1]^nReg[0])? (swap_count + 1):swap_count;
                count <= count - 1;
                state <= `MLshift;
            end else if(state == `MLshift) begin
                nReg <= {1'b0, nReg[255:1]};
                state <= `Double1a;
            end
        end else begin
            {X,Y,Z} <= (swap_count[0])? {X1,Y1,Z1}:{X2,Y2,Z2};
            main_state <= `xy;
        end

    end else if(main_state == `xy) begin
        if(xyconv_state == `conv0a) begin
        // inv(z) start
            inv_start <= 1;
            inv_in <= Z;
            xyconv_state <= `conv0b;
        end else if(xyconv_state == `conv0b) begin
            xyconv_state <= `conv0c; // wait 1 clk
        end else if(xyconv_state == `conv0c) begin
            xyconv_state <= (inv_busy == 1)? `conv0c:`conv0d;
        end else if(xyconv_state == `conv0d) begin
            Z <= Zinv;
            inv_start <= 0;
            xyconv_state <= `conv1a;
        end else if(xyconv_state == `conv1a) begin
        // mul(Z, Z)
            mul_start <= 1;
            mulA <= Z;
            mulB <= Z;
            xyconv_state <= `conv1b;
        end else if(xyconv_state == `conv1b) begin
            xyconv_state <= `conv1c; // wait 1 clk
        end else if(xyconv_state == `conv1c) begin
            xyconv_state <= (mul_busy == 1)? `conv1c:`conv1d;
        end else if(xyconv_state == `conv1d) begin
            mul_start <= 0;
            U <= mul_out;
            xyconv_state <= `conv2a;
        end else if(xyconv_state == `conv2a) begin
        // mulred(Y, Z, A)
            mul_start <= 1;
            red_start <= 1;
            mulA <= Y;
            mulB <= Z;
            xyconv_state <= `conv2b;
        end else if(xyconv_state == `conv2b) begin
            xyconv_state <= `conv2c; // wait 1 clk
        end else if(xyconv_state == `conv2c) begin
            xyconv_state <= ((red_busy == 0)&&(mul_busy == 0))? `conv2d:`conv2c;
        end else if(xyconv_state == `conv2d) begin
            U <= mul_out;
            A <= red_out;
            mul_start <= 0;
            red_start <= 0;
            xyconv_state <= `conv3a;
        end else if(xyconv_state == `conv3a) begin
        // mulred(X, A, B)
            mul_start <= 1;
            red_start <= 1;
            mulA <= X;
            mulB <= A;
            xyconv_state <= `conv3b;
        end else if(xyconv_state == `conv3b) begin
            xyconv_state <= `conv3c; // wait 1 clk
        end else if(xyconv_state == `conv3c) begin
            xyconv_state <= ((red_busy == 0)&&(mul_busy == 0))? `conv3d:`conv3c;
        end else if(xyconv_state == `conv3d) begin
            U <= mul_out;
            B <= red_out;
            mul_start <= 0;
            red_start <= 0;
            xyconv_state <= `conv4a;
        end else if(xyconv_state == `conv4a) begin
        // mulred(B, A, x)
            mul_start <= 1;
            red_start <= 1;
            mulA <= B;
            mulB <= A;
            xyconv_state <= `conv4b;
        end else if(xyconv_state == `conv4b) begin
            xyconv_state <= `conv4c; // wait 1 clk
        end else if(xyconv_state == `conv4c) begin
            xyconv_state <= ((red_busy == 0)&&(mul_busy == 0))? `conv4d:`conv4c;
        end else if(xyconv_state == `conv4d) begin
            U <= mul_out;
            x <= red_out;
            mul_start <= 0;
            red_start <= 0;
            xyconv_state <= `conv5a;
        end else if(xyconv_state == `conv5a) begin
        // red(y)
            red_start <= 1;
            xyconv_state <= `conv5b;
        end else if(xyconv_state == `conv5b) begin
            xyconv_state <= `conv5c; // wait 1 clk
        end else if(xyconv_state == `conv5c) begin
            xyconv_state <= (red_busy == 1)? `conv5c:`conv5d;
        end else if(xyconv_state == `conv5d) begin
            y <= red_out;
            red_start <= 0;            
            xyconv_state <= `conv_final;
        end else if(xyconv_state == `conv_final) begin
            main_state <= `Sign;
        end

    end else if(main_state == `Sign) begin
        if(sign_state == `Sign0a) begin
        // inv(k) start
            inv_start <= 1;
            inv_in <= k;
            sign_state <= `Sign0b;
        end else if(sign_state == `Sign0b) begin
            sign_state <= `Sign0c; // wait 1 clk
        end else if(sign_state == `Sign0c) begin
            sign_state <= (inv_busy == 1)? `Sign0c:`Sign0d;
        end else if(sign_state == `Sign0d) begin
            k <= Zinv;
            inv_start <= 0;
            sign_state <= `Sign1a;
        end else if(sign_state == `Sign1a) begin
        // mul(x, private)
            mul_start <= 1;
            mulA <= x;
            mulB <= private;
            sign_state <= `Sign1b;
        end else if(sign_state == `Sign1b) begin
            sign_state <= `Sign1c; // wait 1 clk
        end else if(sign_state == `Sign1c) begin
            sign_state <= (mul_busy == 1)? `Sign1c:`Sign1d;
        end else if(sign_state == `Sign1d) begin
            mul_start <= 0;
            U <= mul_out;
            sign_state <= `Sign2a;
        end else if(sign_state == `Sign2a) begin
        // red(A)
            red_start <= 1;
            sign_state <= `Sign2b;
        end else if(sign_state == `Sign2b) begin
            sign_state <= `Sign2c; // wait 1 clk
        end else if(sign_state == `Sign2c) begin
            sign_state <= (red_busy == 1)? `Sign2c:`Sign2d;
        end else if(sign_state == `Sign2d) begin
            A <= red_out;
            red_start <= 0; 
            sign_state <= `Sign2e;
        end else if(sign_state == `Sign2e) begin
        //wait_add(A,hash,A);
            a1 <= A;
            a2 <= hash;
            sign_state <= `Sign2f;
        end else if(sign_state == `Sign2f) begin
            A <= add;
            sign_state <= `Sign3a;        
        end else if(sign_state == `Sign3a) begin
       // mul(A, k)
            mul_start <= 1;
            mulA <= A;
            mulB <= k;
            sign_state <= `Sign3b;
        end else if(sign_state == `Sign3b) begin
            sign_state <= `Sign3c; // wait 1 clk
        end else if(sign_state == `Sign3c) begin
            sign_state <= (mul_busy == 1)? `Sign3c:`Sign3d;
        end else if(sign_state == `Sign3d) begin
            mul_start <= 0;
            U <= mul_out;
            sign_state <= `Sign4a;
        end else if(sign_state == `Sign4a) begin
        // red(A)
            red_start <= 1;
            sign_state <= `Sign4b;
        end else if(sign_state == `Sign4b) begin
            sign_state <= `Sign4c; // wait 1 clk
        end else if(sign_state == `Sign4c) begin
            sign_state <= (red_busy == 1)? `Sign4c:`Sign4d;
        end else if(sign_state == `Sign4d) begin
            A <= red_out;
            red_start <= 0; 
            sign_state <= `Sign_end;
        end else if(sign_state == `Sign_end) begin
            sign <= {x,A};
            busy <= 0;
        end
    end
    end
end
endmodule
