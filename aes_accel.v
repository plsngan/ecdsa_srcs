`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/19/2023 02:37:25 PM
// Design Name: 
// Module Name: aes_accel
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
module aes_accel(
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF ina:outa, ASSOCIATED_RESET rst_n" *)
    input wire clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst_n RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input wire rst_n,
    
    input wire[255:0] ina_tdata,
    input wire ina_tvalid,
    output wire ina_tready,
    
    output wire[255:0] outa_tdata,
    output wire outa_tvalid,
    input outa_tready
);
    wire[511:0] data;
    //wire[255:0] data;
    //wire[255:0] key;
    wire d_in_valid;
 //Ngan comment out
   // assign data[0] = key_in ^ ina_tdata;
   // assign key[0] = key_in;
    assign d_in_valid = ina_tvalid;
    
    //wire[255:0] d_out[0:9];
    //wire[127:0] k_out[0:9];
    //wire[255:0] d_out;
    //wire[127:0] k_out;
    
    wire d_out_valid;
    wire gnt;


    assign gnt = outa_tready | ~d_out_valid;
   // assign ina_tready = gnt; 
    assign outa_tvalid = d_out_valid;
    
    wire[255:0] key_in = 256'h0;
   
    ECDSA ecdsa (
        .clk(clk), .start(rst_n),
        .message(data), .key(key_in),
        .sign(outa_tdata), .busy(gnt)
    );
    data_packet_to_axi_stream data_packet (
        .clk(clk), .rst_n(rst_n),
        .data_in(ina_tdata), .valid_in(d_in_valid),
        .data_out(data),
        .valid_out(outa_tvalid)
    );
 /*   generate
        for (i = 0; i < 10; i = i + 1) begin
            aes_block #(
                .KEY_CONST(i == 9 ? 8'h36 :
                           i == 8 ? 8'h1B : 
                           (8'h1 << i)),
                .ENC_LAST(i == 9)
            ) aesblock0 (
                .clk(clk),
                .rst_n(rst_n),
                .enable(gnt[i]),
                .data_valid_in(d_in_valid[i]),
                .data_in(data[i]),
                .key_in(key[i]),
                .data_out(d_out[i]),
                .key_out(k_out[i]),
                .data_valid_out(d_out_valid[i])
            );
        
           if (i != 9) begin
               assign data[i + 1] = d_out[i];
                assign key[i + 1] = k_out[i];
                assign d_in_valid[i + 1] = d_out_valid[i];

           end
       end
    endgenerate
    //assign outa_tdata = d_out;
    //assign outa_tvalid = d_out_valid;
    */
   
endmodule