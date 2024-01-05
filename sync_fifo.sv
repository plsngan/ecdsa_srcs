`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2023 03:59:36 AM
// Design Name: 
// Module Name: sync_fifo
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

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/07/2023 07:13:23 AM
// Design Name: 
// Module Name: sync_fifo
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


module sync_fifo #(
    parameter DEPTH = 512,
    parameter WIDTH = 128
) (
    input   wire                        clk,
    input   wire                        rst,
    input   wire[WIDTH-1:0]             wr_tdata,
    input   wire                        wr_tvalid,
    output  wire                        wr_tready,
    output  wire[$clog2(DEPTH):0]       w_rdptr_o,
    
    output  wire[WIDTH-1:0]             rd_tdata,
    output  wire                        rd_tvalid,
    input   wire                        rd_tready,
    output  wire[$clog2(DEPTH):0]       r_wrptr_o
);

    reg[WIDTH-1:0] mem[0:DEPTH-1];
    
    localparam DEPTH_W = $clog2(DEPTH);
    
    reg[DEPTH_W:0] r_rdptr = {(DEPTH_W+1){1'b0}};
    reg[DEPTH_W:0] w_wrptr = {(DEPTH_W+1){1'b0}};
    
    wire[DEPTH_W:0] r_wrptr = w_wrptr;
    wire[DEPTH_W:0] w_rdptr = r_rdptr;
    
    
    
    reg w_ready_q = 1'b0;
    
    wire w_write_commit = wr_tvalid & w_ready_q;
    wire[DEPTH_W:0] w_wrptr_nxt = w_wrptr + w_write_commit;
    
    always @(posedge clk)
        if (rst)
            w_ready_q <= 1'b0;
        else
            w_ready_q <= {~w_rdptr[DEPTH_W], w_rdptr[DEPTH_W-1:0]} != w_wrptr_nxt;
            
    
    always @(posedge clk)
        if (rst)
            w_wrptr <= {DEPTH_W{1'b0}};
        else
            w_wrptr <= w_wrptr_nxt;
    
    always @(posedge clk)
        if (w_write_commit)
            mem[w_wrptr[DEPTH_W-1:0]] <= wr_tdata;
    
    
    assign wr_tready = w_ready_q;
    assign w_rdptr_o = w_rdptr;
    
    
    
    
    reg r_latch_rvalid = 1'b0;
    reg r_reg_rvalid   = 1'b0;
    
    wire r_reg_enable   = ~r_reg_rvalid | rd_tready;
    wire r_latch_enable = ~r_latch_rvalid | r_reg_enable;
    reg r_rvalid_q = 1'b0;
   
    wire r_read_commit = r_rvalid_q & r_latch_enable;
    wire[DEPTH_W:0] r_rdptr_nxt = r_rdptr + r_read_commit;
    always @(posedge clk)
        if (rst)
            r_rdptr <= {DEPTH_W{1'b0}};
        else
            r_rdptr <= r_rdptr_nxt;
            
     always @(posedge clk)
        if (rst)
            r_rvalid_q <= 1'b0;
        else
            r_rvalid_q <= r_rdptr_nxt != r_wrptr;
    
    
    
    always @(posedge clk)
        if (rst)
            r_latch_rvalid <= 1'b0;
        else if (r_latch_enable)
            r_latch_rvalid <= r_rvalid_q;
    
    reg[WIDTH-1:0] r_latch_data;
    always @(posedge clk)
        if (r_read_commit)
            r_latch_data <= mem[r_rdptr[DEPTH_W-1:0]];
    
    
    always @(posedge clk)
        if (rst)
            r_reg_rvalid <= 1'b0;
        else if (r_reg_enable)
            r_reg_rvalid <= r_latch_rvalid;
    
    reg[WIDTH-1:0] r_reg_data;
    always @(posedge clk)
        if (r_latch_rvalid & r_reg_enable)
            r_reg_data <= r_latch_data;
    
    
    assign rd_tdata  = r_reg_data;
    assign rd_tvalid = r_reg_rvalid;
    assign r_wrptr_o = r_wrptr;
endmodule



module sync_fifo_single #(
    parameter DEPTH = 512,
    parameter WIDTH = 128
) (
    input   wire                        clk,
    input   wire                        rst,
    input   wire[WIDTH-1:0]             wr_tdata,
    input   wire                        wr_tvalid,
    output  wire                        wr_tready,
    output  wire[$clog2(DEPTH):0]       w_rdptr_o,
    
    output  wire[WIDTH-1:0]             rd_tdata,
    output  wire                        rd_tvalid,
    input   wire                        rd_tready,
    output  wire[$clog2(DEPTH):0]       r_wrptr_o
);


    reg[WIDTH-1:0] mem[0:DEPTH-1];
    
    localparam DEPTH_W = $clog2(DEPTH);
    
    reg[DEPTH_W:0] r_rdptr = {(DEPTH_W+1){1'b0}};
    reg[DEPTH_W:0] w_wrptr = {(DEPTH_W+1){1'b0}};
    
    wire[DEPTH_W:0] r_wrptr = w_wrptr;
    wire[DEPTH_W:0] w_rdptr = r_rdptr;
    
    
    
    reg w_ready_q = 1'b0;
    
    wire w_write_commit = wr_tvalid & w_ready_q;
    wire[DEPTH_W:0] w_wrptr_nxt = w_wrptr + w_write_commit;
    
    always @(posedge clk)
        if (rst)
            w_ready_q <= 1'b0;
        else
            w_ready_q <= {~w_rdptr[DEPTH_W], w_rdptr[DEPTH_W-1:0]} != w_wrptr_nxt;
            
    
    always @(posedge clk)
        if (rst)
            w_wrptr <= {DEPTH_W{1'b0}};
        else
            w_wrptr <= w_wrptr_nxt;
    
    always @(posedge clk)
        if (w_write_commit)
            mem[w_wrptr[DEPTH_W-1:0]] <= wr_tdata;
    
    
    assign wr_tready = w_ready_q;
    assign w_rdptr_o = w_rdptr;
    
    
    
    
    reg r_latch_rvalid = 1'b0;
    
    wire r_latch_enable = ~r_latch_rvalid | rd_tready;
    reg r_rvalid_q = 1'b0;
   
    wire r_read_commit = r_rvalid_q & r_latch_enable;
    wire[DEPTH_W:0] r_rdptr_nxt = r_rdptr + r_read_commit;
    always @(posedge clk)
        if (rst)
            r_rdptr <= {DEPTH_W{1'b0}};
        else
            r_rdptr <= r_rdptr_nxt;
            
     always @(posedge clk)
        if (rst)
            r_rvalid_q <= 1'b0;
        else
            r_rvalid_q <= r_rdptr_nxt != r_wrptr;
    
    always @(posedge clk)
        if (rst)
            r_latch_rvalid <= 1'b0;
        else if (r_latch_enable)
            r_latch_rvalid <= r_rvalid_q;
    
    reg[WIDTH-1:0] r_latch_data;
    always @(posedge clk)
        if (r_read_commit)
            r_latch_data <= mem[r_rdptr[DEPTH_W-1:0]];
    
    assign rd_tdata  = r_latch_data;
    assign rd_tvalid = r_latch_rvalid;
    assign r_wrptr_o = r_wrptr;
endmodule

