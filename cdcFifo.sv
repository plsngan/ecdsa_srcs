`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2023 09:07:34 PM
// Design Name: 
// Module Name: cdcFifo
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



module cdcBus #(
    parameter WIDTH = 0
) (
    input wire              clkSrc,
    input wire[WIDTH-1:0]   srcBin_i,
    
    input wire              clkDst,
    output wire[WIDTH-1:0]  dstBin_o
);
    
    (* KEEP = "TRUE" *) reg cdc_src_req_trans = 1'b0 /* synthesis syn_keep=1 */;
    (* KEEP = "TRUE" *) reg cdc_src_req_use = 1'b0 /* synthesis syn_keep=1 */;
    
    (* KEEP = "TRUE" *) reg cdc_dst_ack_trans = 1'b0 /* synthesis syn_keep=1 */;
    (* KEEP = "TRUE" *) reg cdc_dst_ack_use   = 1'b0 /* synthesis syn_keep=1 */;
    
    (* KEEP = "TRUE" *) reg[WIDTH-1:0] cdc_src_data_trans = {WIDTH{1'b0}} /* synthesis syn_keep=1 */;
    (* KEEP = "TRUE" *) reg[WIDTH-1:0] cdc_dst_data_latch = {WIDTH{1'b0}} /* synthesis syn_keep=1 */;
    
    (* ASYNC_REG = "TRUE" *) reg[2:0] cdc_dst_req_sync = 3'b000 /* synthesis syn_keep=1 */;
    (* ASYNC_REG = "TRUE" *) reg[2:0] cdc_src_ack_sync = 3'b000 /* synthesis syn_keep=1 */;
    
    wire cdc_dst_req_use    = cdc_dst_req_sync[0];
    wire cdc_src_ack_use    = cdc_src_ack_sync[0];
    
    always @(posedge clkSrc) begin
        cdc_src_ack_sync[2]     <= cdc_dst_ack_trans;
        cdc_src_ack_sync[1]     <= cdc_src_ack_sync[2];
        cdc_src_ack_sync[0]     <= cdc_src_ack_sync[1];
    end
    
    always @(posedge clkSrc)
        if (cdc_src_req_use == cdc_src_ack_use) begin
            cdc_src_data_trans  <= srcBin_i;
            cdc_src_req_trans   <= ~cdc_src_req_use;
            cdc_src_req_use     <= ~cdc_src_req_use;
        end
    
    always @(posedge clkDst) begin
        cdc_dst_req_sync[2]     <= cdc_src_req_trans;
        cdc_dst_req_sync[1]     <= cdc_dst_req_sync[2];
        cdc_dst_req_sync[0]     <= cdc_dst_req_sync[1];
    end
    
    always @(posedge clkDst)
        if (cdc_dst_req_use != cdc_dst_ack_use) begin
            cdc_dst_data_latch  <= cdc_src_data_trans;
            cdc_dst_ack_use     <= ~cdc_dst_ack_use;
            cdc_dst_ack_trans   <= ~cdc_dst_ack_use;
        end
   
    
    assign dstBin_o = cdc_dst_data_latch;
endmodule




module cdcFifo #(
    parameter DEPTH = 512,
    parameter WIDTH = 128
) (
    input   wire                        wr_rst,
    input   wire                        wr_clk,
    input   wire[WIDTH-1:0]             wr_tdata,
    input   wire                        wr_tvalid,
    output  wire                        wr_tready,
    output  wire[$clog2(DEPTH):0]       w_rdptr_o,
    
    input   wire                        rd_rst,
    input   wire                        rd_clk,
    output  wire[WIDTH-1:0]             rd_tdata,
    output  wire                        rd_tvalid,
    input   wire                        rd_tready,
    output  wire[$clog2(DEPTH):0]       r_wrptr_o
);



    reg[WIDTH-1:0] mem[0:DEPTH-1];
    
    localparam DEPTH_W = $clog2(DEPTH);
    
    reg[DEPTH_W:0] r_rdptr = {(DEPTH_W+1){1'b0}};
    reg[DEPTH_W:0] w_wrptr = {(DEPTH_W+1){1'b0}};
    
    wire[DEPTH_W:0] r_wrptr;
    wire[DEPTH_W:0] w_rdptr;
    
    cdcBus #(
        .WIDTH(DEPTH_W + 1)
    ) cdcWrite2Read(
        .clkSrc(wr_clk),
        .srcBin_i(w_wrptr),
        .clkDst(rd_clk),
        .dstBin_o(r_wrptr)
    );
    
    cdcBus #(
        .WIDTH(DEPTH_W + 1)
    ) cdcRead2Write(
        .clkSrc(rd_clk),
        .srcBin_i(r_rdptr),
        .clkDst(wr_clk),
        .dstBin_o(w_rdptr)
    );
    
    
    
    
    reg w_ready_q = 1'b0;
    
    wire w_write_commit = wr_tvalid & w_ready_q;
    wire[DEPTH_W:0] w_wrptr_nxt = w_wrptr + w_write_commit;
    
    always @(posedge wr_clk)
        if (wr_rst)
            w_ready_q <= 1'b0;
        else
            w_ready_q <= {~w_rdptr[DEPTH_W], w_rdptr[DEPTH_W-1:0]} != w_wrptr_nxt;
            
    
    
    always @(posedge wr_clk)
        if (wr_rst)
            w_wrptr <= {DEPTH_W{1'b0}};
        else
            w_wrptr <= w_wrptr_nxt;
    
    always @(posedge wr_clk)
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
    always @(posedge rd_clk)
        if (rd_rst)
            r_rdptr <= {DEPTH_W{1'b0}};
        else
            r_rdptr <= r_rdptr_nxt;
            
     always @(posedge rd_clk)
        if (rd_rst)
            r_rvalid_q <= 1'b0;
        else
            r_rvalid_q <= r_rdptr_nxt != r_wrptr;
    
    
    
    always @(posedge rd_clk)
        if (rd_rst)
            r_latch_rvalid <= 1'b0;
        else if (r_latch_enable)
            r_latch_rvalid <= r_rvalid_q;
    
    reg[WIDTH-1:0] r_latch_data;
    always @(posedge rd_clk)
        if (r_read_commit)
            r_latch_data <= mem[r_rdptr[DEPTH_W-1:0]];
    
    
    always @(posedge rd_clk)
        if (rd_rst)
            r_reg_rvalid <= 1'b0;
        else if (r_reg_enable)
            r_reg_rvalid <= r_latch_rvalid;
    
    reg[WIDTH-1:0] r_reg_data;
    always @(posedge rd_clk)
        if (r_latch_rvalid & r_reg_enable)
            r_reg_data <= r_latch_data;
    
    
    assign rd_tdata  = r_reg_data;
    assign rd_tvalid = r_reg_rvalid;
    assign r_wrptr_o = r_wrptr;
endmodule
