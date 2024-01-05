`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/14/2023 01:28:44 PM
// Design Name: 
// Module Name: top
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


//`define TEST_THROUGHPUT 1

module top();
    reg clk = 1'b0;
    always #1.5 clk <= ~clk;
    reg rst = 1'b1;
    initial #38 rst <= 1'b0;
    
    
    int ctr = 0;
    int queue_size;
    
    reg[7:0] test_in[int];
    reg[7:0] test_expected[int];
    
    
    initial begin
        $readmemh("test_in.mem", test_in);
        $readmemh("test_expected.mem", test_expected);
        queue_size = test_in.size() / 16;
    end
    reg[127:0] data_in;
    
    always_comb
        for (int i = 0; i < 16; ++i) begin
            data_in[8*i+:8] = test_in[16*ctr + i];
        end
    
    
    reg i_req = 1'b0;
    reg data_ready = 1'b0;
    
    `ifndef TEST_THROUGHPUT
    always_ff @(posedge clk)
        data_ready <= $urandom % 4 != 0;
    
    always_ff @(posedge clk)
        i_req <= $urandom % 4 != 0;
    `else
    always_ff @(posedge clk)
        data_ready <= 1'b1;
    
    always_ff @(posedge clk)
        i_req <= 1'b1;
    `endif
    
        
    wire o_gnt;
    always_ff @(posedge clk)
        if (rst)
            ctr <= '0;
        else if (i_req & o_gnt & (ctr < queue_size))
            ctr <= ctr + 1'b1;
    
        
    wire[127:0] data_out;
    wire data_valid;
    
    acc_core acc0(
        .clk_core(clk),
        .rst_core(rst),
        .clk_if(clk),
        .rst_if(rst),
        .ina_tdata(data_in),
        .ina_tvalid(i_req && ctr < queue_size),
        .ina_tready(o_gnt),
        .ina_rdptr(),
        .outa_tdata(data_out),
        .outa_tvalid(data_valid),
        .outa_tready(data_ready),
        .outa_wrptr()
    );
    
    reg[127:0] data_q[128];    
    int idx = '0;
    reg[127:0] expected_data;
    always_comb
        for (int i = 0; i < 16; ++i)
            expected_data[8*i+:8] = test_expected[16 * idx + i];
    
    always @(posedge clk)
        if (rst) begin
            idx <= '0;
        end
        else begin
//            if (idx == 128)
//                $finish;
            if (data_valid & data_ready) begin
                if (data_out !== expected_data)
                    $finish;
                
                
                idx <= idx + 1;
                
                data_q[idx] <= data_out;
            end
        end
   
    
    
    
    
endmodule
