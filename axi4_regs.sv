`timescale 1ns / 1ps


module axi4_regs#(
    parameter DW = 1,
    parameter AW = 1,
    parameter IDW = 1,
    parameter M_AW = 1
) (
    input   wire                        clk,
    input   wire                        rst_n,

    input   wire                        arvalid,
    input   wire[15:0]                  aruser,
    input   wire                        arlock,
    input   wire[3:0]                   arcache,
    input   wire[2:0]                   arprot,
    input   wire[3:0]                   arqos,
    input   wire[IDW-1:0]               arid,
    input   wire[AW-1:0]                araddr,
    input   wire[1:0]                   arburst,
    input   wire[2:0]                   arsize,
    input   wire[7:0]                   arlen,
    output  reg                         arready,

    output  reg[IDW-1:0]                rid,
    output  wire[1:0]                   rresp,
    output  reg[DW-1:0]                 rdata,
    output  reg                         rvalid,
    input   wire                        rready,
    output  wire                        rlast,
    
    input   wire                        awvalid,
    input   wire[15:0]                  awuser,
    input   wire                        awlock,
    input   wire[3:0]                   awcache,
    input   wire[2:0]                   awprot,
    input   wire[3:0]                   awqos,
    input   wire[IDW-1:0]               awid,
    input   wire[AW-1:0]                awaddr,
    input   wire[1:0]                   awburst,
    input   wire[2:0]                   awsize,
    input   wire[7:0]                   awlen,
    output  reg                         awready,
    
    input   wire[DW/8-1:0]              wstrb,
    input   wire[DW-1:0]                wdata,
    input   wire                        wvalid,
    output  reg                         wready,
    input   wire                        wlast,

    output  reg[IDW-1:0]                bid,
    output  wire[1:0]                   bresp,
    output  reg                         bvalid,
    input   wire                        bready,
    
    input   wire[31:0]                  pl2ps_wrptr_nxt,
    output  wire[31:0]                  pl2ps_wrptr,
    output  wire[31:0]                  pl2ps_rdptr,

    input   wire[31:0]                  ps2pl_rdptr_nxt,
    output  wire[31:0]                  ps2pl_wrptr,
    output  wire[31:0]                  ps2pl_rdptr,
    output  wire[31:0]                  pl2ps_size,
    output  wire[31:0]                  ps2pl_size,

    output  wire[127:0]                 aes_key,
    output  wire[M_AW-1:0]              ps2pl_baseaddr,
    output  wire[M_AW-1:0]              pl2ps_baseaddr          
);
    
    
    localparam MSIZE = 4;
    localparam LSB = $clog2(DW) - 3;

    reg[DW-1:0] mem[MSIZE] = '{default: 128'h0};
    
    initial arready = 1'b1;
    always_ff @(posedge clk)
        if (!rst_n)
            arready <= 1'b1;
        else if (arready & arvalid)
            arready <= 1'b0;
        else if (rlast & rready & rvalid)
            arready <= 1'b1;
    
    initial rvalid = 1'b0;
    always_ff @(posedge clk)
        if (!rst_n)
            rvalid <= 1'b0;
        else if (arready & arvalid)
            rvalid <= 1'b1;
        else if (rlast & rready & rvalid)
            rvalid <= 1'b0;
    
    reg[1:0] arburst_q;
    reg[7:0] araddr_inc;
    reg[11:0] arwrap_boundary;

    always_ff @(posedge clk)
        if (arready & arvalid) begin
            arburst_q       <= arburst;
            araddr_inc      <= 1 << arsize;
            arwrap_boundary <= arlen << arsize;
            rid             <= arid;
        end
    
    reg[AW-1:0] araddr_q;
    
    wire[11:0] araddr_inc_lo    = araddr_q[11:0] + araddr_inc;
    wire[11:0] araddr_wrap_lo   = (araddr_q[11:0] & arwrap_boundary) == arwrap_boundary ? araddr_q[11:0] ^ arwrap_boundary : araddr_inc_lo;
    
    reg[AW-1:0] araddr_nxt;
    always_comb
        if (arready & arvalid)
            araddr_nxt = araddr;
        else if (rready & rvalid)
            case (arburst_q)
                2'b00: araddr_nxt = araddr_q;
                2'b01: araddr_nxt = {araddr_q[AW-1:12], araddr_inc_lo};
                2'b10: araddr_nxt = {araddr_q[AW-1:12], araddr_wrap_lo};
                2'b11: araddr_nxt = 'x;
            endcase
        else
            araddr_nxt = araddr_q;
    
    
    always_ff @(posedge clk)
        araddr_q <= araddr_nxt;
    
    always_ff @(posedge clk)
        rdata <= mem[araddr_nxt[LSB+:$clog2(MSIZE)]];
        
    reg[7:0] arlen_q;
    
    always_ff @(posedge clk)
        if (arready & arvalid)
            arlen_q <= arlen;
        else if (rready & rvalid)
            arlen_q <= arlen_q - 1'b1;
    
    assign rlast = arlen_q == 8'd0;

    

    initial awready = 1'b1;
    always_ff @(posedge clk)
        if (!rst_n)
            awready <= 1'b1;
        else if (awvalid & awready)
            awready <= 1'b0;
        else if (bvalid & bready)
            awready <= 1'b1;

    initial wready = 1'b0;        
    always_ff @(posedge clk)
        if (!rst_n)
            wready <= 1'b0;
        else if (awvalid & awready)
            wready <= 1'b1;
        else if (wlast & wready & wvalid)
            wready <= 1'b0;
    
    initial bvalid = 1'b0;
    always_ff @(posedge clk)
        if (!rst_n)
            bvalid <= 1'b0;
        else if (wlast & wready & wvalid)
            bvalid <= 1'b1;
        else if (bvalid & bready)
            bvalid <= 1'b0;
    
    
    reg[1:0] awburst_q;
    reg[7:0] awaddr_inc;
    reg[11:0] awwrap_boundary;

    always_ff @(posedge clk)
        if (awvalid & awready) begin
            awburst_q       <= awburst;
            awaddr_inc      <= 1 << awsize;
            awwrap_boundary <= awlen << awsize;
            bid             <= awid;    
        end

    reg[AW-1:0] awaddr_q;

    wire[11:0] awaddr_inc_lo    = awaddr_q[11:0] + awaddr_inc;
    wire[11:0] awaddr_wrap_lo   = (awaddr_q[11:0] & awwrap_boundary) == awwrap_boundary ? awaddr_q[11:0] ^ awwrap_boundary : awaddr_inc_lo;

    reg[AW-1:0] awaddr_nxt;
    always_comb
        if (awvalid & awready)
            awaddr_nxt = awaddr;
        else if (wvalid & wready)
            case (awburst_q)
                2'b00: awaddr_nxt = awaddr_q;
                2'b01: awaddr_nxt = {awaddr_q[AW-1:12], awaddr_inc_lo};
                2'b10: awaddr_nxt = {awaddr_q[AW-1:12], awaddr_wrap_lo};
                2'b11: awaddr_nxt = 'x;
            endcase
        else
            awaddr_nxt = awaddr_q;

    
    always_ff @(posedge clk)
        awaddr_q <= awaddr_nxt;
    
    generate
        for (genvar g = 0; g < MSIZE; ++g) begin
            if (g != 1) begin
                always_ff @(posedge clk)
                    if (!rst_n)
                        mem[g] <= 128'h0;
                    else
                        for (int i = 0; i < DW/8; ++i)
                            if (wvalid && wready && awaddr_q[LSB+:$clog2(MSIZE)] == g && wstrb[i])
                                mem[g][(8*i)+:8] <= wdata[(8*i)+:8];
            end
        end
    endgenerate
    
    always_ff @(posedge clk)
        if (!rst_n)
            mem[1] <= 128'h0;
        else begin
            mem[1][0+:32]  <= pl2ps_wrptr_nxt; 
            mem[1][32+:32] <= ps2pl_rdptr_nxt;
        end
    


    assign pl2ps_rdptr      = mem[0][0+:32];
    assign pl2ps_size       = mem[0][32+:32];
    assign ps2pl_wrptr      = mem[0][64+:32];
    assign ps2pl_size       = mem[0][96+:32];

    assign pl2ps_wrptr      = mem[1][0+:32];
    assign ps2pl_rdptr      = mem[1][32+:32];

    assign pl2ps_baseaddr   = mem[2][0+:M_AW];
    assign ps2pl_baseaddr   = mem[2][64+:M_AW];

    assign aes_key          = mem[3];

    assign rresp        = 2'b00;
    assign bresp        = 2'b00;
endmodule
			
			
			
			