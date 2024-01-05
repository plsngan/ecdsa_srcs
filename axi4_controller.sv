module axi4_controller #(
    // master params
    parameter M_UW = 1,
    parameter M_IDW = 6,
    parameter M_AW = 49,
    parameter M_DW = 128,
    // slave params
    parameter S_AW = 28,
    parameter S_DW = 128,
    parameter S_IDW = 16
) (
    input wire clk,

    input wire rst_n,

    input wire[S_IDW-1:0] s_awid, // Write address ID (optional)
    input wire[S_AW-1:0] s_awaddr, // Write address (optional)
    input wire[7:0] s_awlen, // Burst length (optional)
    input wire[2:0] s_awsize, // Burst size (optional)
    input wire[1:0] s_awburst, // Burst type (optional)
    input wire s_awlock, // Lock type (optional)
    input wire[3:0] s_awcache, // Cache type (optional)
    input wire[2:0] s_awprot, // Protection type (optional)
    input wire[3:0] s_awqos, // Transaction Quality of Service token (optional)
    input wire[15:0] s_awuser, // Write address user sideband (optional)
    input wire s_awvalid, // Write address valid (optional)
    output wire s_awready, // Write address ready (optional)
    input wire[S_DW-1:0] s_wdata, // Write data (optional)
    input wire[S_DW/8-1:0] s_wstrb, // Write strobes (optional)
    input wire s_wlast, // Write last beat (optional)
    input wire s_wvalid, // Write valid (optional)
    output wire s_wready, // Write ready (optional)
    output wire[S_IDW-1:0] s_bid, // Response ID (optional)
    output wire[1:0] s_bresp, // Write response (optional)
    output wire s_bvalid, // Write response valid (optional)
    input wire s_bready, // Write response ready (optional)
    input wire[S_IDW-1:0] s_arid, // Read address ID (optional)
    input wire[S_AW-1:0] s_araddr, // Read address (optional)
    input wire[7:0] s_arlen, // Burst length (optional)
    input wire[2:0] s_arsize, // Burst size (optional)
    input wire[1:0] s_arburst, // Burst type (optional)
    input wire s_arlock, // Lock type (optional)
    input wire[3:0] s_arcache, // Cache type (optional)
    input wire[2:0] s_arprot, // Protection type (optional)
    input wire[3:0] s_arqos, // Quality of service token (optional)
    input wire[15:0] s_aruser, // Read address user sideband (optional)
    input wire s_arvalid, // Read address valid (optional)
    output wire s_arready, // Read address ready (optional)
    output wire[S_IDW-1:0] s_rid, // Read ID tag (optional)
    output wire[S_DW-1:0] s_rdata, // Read data (optional)
    output wire[1:0] s_rresp, // Read response (optional)
    output wire s_rlast, // Read last beat (optional)
    output wire s_rvalid, // Read valid (optional)
    input wire s_rready, // Read ready (optional)


    output wire[M_UW-1:0]   m_aruser,
    output wire[M_UW-1:0]   m_awuser,

    output wire[M_IDW-1:0]  m_awid,
    output reg[M_AW-1:0]    m_awaddr,
    output wire[7:0]        m_awlen,
    output wire[2:0]        m_awsize,
    output wire[1:0]        m_awburst,
    output wire             m_awlock,
    output wire[3:0]        m_awcache,
    output wire[2:0]        m_awprot,
    output wire             m_awvalid,
    input  wire             m_awready,

    output wire[M_DW-1:0]   m_wdata,
    output wire[M_DW/8-1:0] m_wstrb,
    output wire             m_wlast,
    output wire             m_wvalid,
    input  wire             m_wready,

    input  wire[M_IDW-1:0]  m_bid,
    input  wire[1:0]        m_bresp,
    input  wire             m_bvalid,
    output wire             m_bready,

    output wire[M_IDW-1:0]  m_arid,
    output reg[M_AW-1:0]    m_araddr,
    output wire[7:0]        m_arlen,
    output wire[2:0]        m_arsize,
    output wire[1:0]        m_arburst,
    output wire             m_arlock,
    output wire[3:0]        m_arcache,
    output wire[2:0]        m_arprot,
    output wire             m_arvalid,
    input  wire             m_arready,

    input  wire[M_IDW-1:0]  m_rid,
    input  wire[M_DW-1:0]   m_rdata,
    input  wire[1:0]        m_rresp,
    input  wire             m_rlast,
    input  wire             m_rvalid,
    output wire             m_rready,

    output wire[3:0]        m_awqos,
    output wire[3:0]        m_arqos,

    output reg intr_out, //  (required)
    output reg fan_ctrl,
    
    output wire[127:0] toaccel_tdata,
    output wire        toaccel_tvalid,
    input wire         toaccel_tready,
    input wire[9:0]    toaccel_rdptr,
    
    input wire[127:0]  fromaccel_tdata,
    input wire         fromaccel_tvalid,
    output wire        fromaccel_tready,
    input wire[9:0]    fromaccel_wrptr
    
);
    
    initial fan_ctrl = 1'b0;
    always @(posedge clk)
        fan_ctrl <= 1'b0;
    

    initial intr_out = 1'b0;
    always @(posedge clk)
        intr_out <= 1'b0;

    assign m_aruser = {M_UW{1'b0}};
    assign m_awuser = {M_UW{1'b0}};
    
    
    localparam M_DWBYTES = M_DW / 8;
    localparam M_AWLEN = 8'd1;
    localparam M_ARLEN = 8'd1;
    localparam M_WBURST_BYTES = (M_AWLEN + 1) * M_DWBYTES;
    localparam M_RBURST_BYTES = (M_ARLEN + 1) * M_DWBYTES;
    

    wire[31:0] pl2ps_wrptr;
    wire[31:0] pl2ps_rdptr;
    wire[31:0] pl2ps_wrptr_nxt = (m_bready & m_bvalid) ? (pl2ps_wrptr + M_WBURST_BYTES) : pl2ps_wrptr;

    wire[31:0] ps2pl_wrptr;
    wire[31:0] ps2pl_rdptr;
    wire[31:0] ps2pl_rdptr_nxt = (m_rready & m_rvalid) ? (ps2pl_rdptr + M_DWBYTES) : ps2pl_rdptr;

    wire[31:0] pl2ps_size;
    wire[31:0] ps2pl_size;


    wire[127:0] aes_key;
    wire[M_AW-1:0] ps2pl_baseaddr;
    wire[M_AW-1:0] pl2ps_baseaddr;
    axi4_regs #(
        .DW(S_DW),
        .IDW(S_IDW),
        .AW(S_AW),
        .M_AW(M_AW)
    ) slv_regs(
        .clk(clk),
        .rst_n(rst_n),
        
        .arvalid(s_arvalid),
        .aruser(s_aruser),
        .arlock(s_arlock),
        .arcache(s_arcache),
        .arprot(s_arprot),
        .arqos(s_arqos),
        .arid(s_arid),
        .araddr(s_araddr),
        .arburst(s_arburst),
        .arsize(s_arsize),
        .arlen(s_arlen),
        .arready(s_arready),
        .rid(s_rid),
        
        .rresp(s_rresp),
        .rdata(s_rdata),
        .rvalid(s_rvalid),
        .rready(s_rready),
        .rlast(s_rlast),
        
        .awvalid(s_awvalid),
        .awuser(s_awuser),
        .awlock(s_awlock),
        .awcache(s_awcache),
        .awprot(s_awprot),
        .awqos(s_awqos),
        .awid(s_awid),
        .awaddr(s_awaddr),
        .awburst(s_awburst),
        .awsize(s_awsize),
        .awlen(s_awlen),
        .awready(s_awready),
        .bid(s_bid),
        .wstrb(s_wstrb),
        .wdata(s_wdata),
        .wvalid(s_wvalid),
        .wready(s_wready),
        .wlast(s_wlast),
        .bresp(s_bresp),
        .bvalid(s_bvalid),
        .bready(s_bready),
        
        .pl2ps_wrptr_nxt(pl2ps_wrptr_nxt),
        .pl2ps_wrptr(pl2ps_wrptr),
        .pl2ps_rdptr(pl2ps_rdptr),
        
        .ps2pl_rdptr_nxt(ps2pl_rdptr_nxt),
        .ps2pl_rdptr(ps2pl_rdptr),
        .ps2pl_wrptr(ps2pl_wrptr),
        
        .aes_key(aes_key),
        .ps2pl_baseaddr(ps2pl_baseaddr),
        .pl2ps_baseaddr(pl2ps_baseaddr),
        .pl2ps_size(pl2ps_size),
        .ps2pl_size(ps2pl_size)
    );

    // write address channel
    assign m_awid       = {M_IDW{1'b0}};
    assign m_awqos      = 4'h0;
    assign m_awsize     = 3'b100;
    assign m_awlock     = 1'b0;
    assign m_awcache    = 4'b0000;
    assign m_awprot     = 3'b000;


    assign m_awlen      = M_AWLEN;
    assign m_awburst    = 2'b01;

    
    
    
    

    reg m_awvalid_q = 1'b0;

    wire m_awvalid_q_ready = ~m_awvalid_q | m_awready;
    wire m_awvalid_w;

    always @(posedge clk)
        if (!rst_n)
            m_awvalid_q <= 1'b0;
        else if (m_awvalid_q_ready)
            m_awvalid_q <= m_awvalid_w;

    assign m_awvalid = m_awvalid_q;
    

    localparam TX_FIFODEPTH = 512;
    localparam TXPTR_WIDTH = $clog2(TX_FIFODEPTH);
    localparam TX_INC = M_AWLEN + 1;
    
    
    wire[TXPTR_WIDTH:0] tx_fifo_wrptr;
    reg[TXPTR_WIDTH:0] srdptr = {(TXPTR_WIDTH+1){1'b0}};
    
    wire[TXPTR_WIDTH:0] sptr_diff = tx_fifo_wrptr - srdptr;

    wire inc_srdptr = sptr_diff >= TX_INC;

    always @(posedge clk)
        if (!rst_n)
            srdptr <= {(TXPTR_WIDTH+1){1'b0}};
        else if (inc_srdptr)
            srdptr <= srdptr + TX_INC;
    
    reg[31:0] pending_awaddr_bursts = 32'd0;
    always @(posedge clk)
        if (!rst_n)
            pending_awaddr_bursts <= 32'd0;
        else
            pending_awaddr_bursts <= pending_awaddr_bursts + inc_srdptr - (m_awvalid_w & m_awvalid_q_ready);

    reg[31:0] scheduled_awaddr_ptr = 32'd0;

    wire[31:0] scheduled_ptr_diff = scheduled_awaddr_ptr - pl2ps_rdptr;
    wire inc_scheduled_awaddr_ptr = M_WBURST_BYTES <= pl2ps_size - scheduled_ptr_diff;
    always @(posedge clk)
        if (!rst_n)
            scheduled_awaddr_ptr <= 32'd0;
        else if (inc_scheduled_awaddr_ptr)
            scheduled_awaddr_ptr <= scheduled_awaddr_ptr + M_WBURST_BYTES;
    
    reg[31:0] pending_awaddr_ptr = 32'd0;
    always @(posedge clk)
        if (!rst_n)
            pending_awaddr_ptr <= 32'd0;
        else
            pending_awaddr_ptr <= pending_awaddr_ptr + inc_scheduled_awaddr_ptr - (m_awvalid_w & m_awvalid_q_ready);

    reg[31:0]   awaddr_ptr      = 32'd0;
    wire[31:0]  awaddr_ptr_nxt  = (m_awvalid_q & m_awready) ? awaddr_ptr + M_WBURST_BYTES : awaddr_ptr;
    always @(posedge clk)
        if (!rst_n)
            awaddr_ptr <= 32'd0;
        else
            awaddr_ptr <= awaddr_ptr_nxt;
    
    always @(posedge clk)
        m_awaddr <= pl2ps_baseaddr + (awaddr_ptr_nxt & (pl2ps_size - 1));
        

    assign tx_fifo_wrptr    = fromaccel_wrptr;
    assign m_wvalid         = fromaccel_tvalid;
    assign m_wdata          = fromaccel_tdata;
    assign fromaccel_tready = m_wready;



    
    
    // write data channel
    
            
    assign m_wstrb      = {(M_DW/8){1'b1}};

    reg[7:0] m_wlen_q = M_AWLEN;
    always @(posedge clk)
        if (!rst_n)
            m_wlen_q <= M_AWLEN;
        else if (m_wvalid & m_wready)
            m_wlen_q <= m_wlast ? M_AWLEN : m_wlen_q - 1'b1;

    assign m_wlast = m_wlen_q == 8'h0;
    
    // write response channel
    assign m_bready = 1'b1;



    assign m_awvalid_w = pending_awaddr_ptr != 32'd0 && pending_awaddr_bursts != 32'd0;

    
    
    // read address channel
    assign m_arid       = {M_IDW{1'b0}};
    assign m_arqos      = 4'h0;
    assign m_arsize     = 3'b100;
    assign m_arlock     = 1'b0;
    assign m_arcache    = 4'b0000;
    assign m_arprot     = 3'b000;
    assign m_arlen      = M_ARLEN;
    assign m_arburst    = 2'b01;


    localparam RX_FIFODEPTH = 512;
    localparam RXPTR_WIDTH  = $clog2(RX_FIFODEPTH);
    localparam RX_INC       = M_ARLEN + 1;

    

    assign m_rready = 1'b1;
    
    wire[RXPTR_WIDTH:0] rx_fifo_rdptr = toaccel_rdptr;
    assign toaccel_tdata = m_rdata;
    assign toaccel_tvalid = m_rvalid;

    
    reg[31:0] sched_araddr_ptr = 32'd0;
    wire[31:0] araddr_ptr_diff = ps2pl_wrptr - sched_araddr_ptr;
    wire sched_araddr_ptr_inc = araddr_ptr_diff >= M_RBURST_BYTES;
    always @(posedge clk)
        if (!rst_n)
            sched_araddr_ptr <= 32'd0;
        else if (sched_araddr_ptr_inc)
            sched_araddr_ptr <= sched_araddr_ptr + M_RBURST_BYTES;
    
    reg[31:0] pending_araddr_ptr = 32'd0;
    always @(posedge clk)
        if (!rst_n)
            pending_araddr_ptr <= 32'd0;
        else
            pending_araddr_ptr <= pending_araddr_ptr + sched_araddr_ptr_inc - (m_arvalid & m_arready);

    reg[RXPTR_WIDTH:0] sched_rx_fifo_wrptr = {(RXPTR_WIDTH+1){1'b0}};
    wire[RXPTR_WIDTH:0] sched_rx_fifo_ptr_diff = sched_rx_fifo_wrptr - rx_fifo_rdptr;
    wire sched_rx_fifo_wrptr_inc = sched_rx_fifo_ptr_diff <= (RX_FIFODEPTH - RX_INC);

    always @(posedge clk)
        if (!rst_n)
            sched_rx_fifo_wrptr <= {(RXPTR_WIDTH+1){1'b0}};
        else if (sched_rx_fifo_wrptr_inc)
            sched_rx_fifo_wrptr <= sched_rx_fifo_wrptr + RX_INC;
    
    reg[31:0] pending_rx_fifo_wrptr = 32'd0;
    always @(posedge clk)
        if (!rst_n)
            pending_rx_fifo_wrptr <= 32'd0;
        else
            pending_rx_fifo_wrptr <= pending_rx_fifo_wrptr + sched_rx_fifo_wrptr_inc - (m_arvalid & m_arready);

    assign m_arvalid = pending_rx_fifo_wrptr != 32'd0 && pending_araddr_ptr != 32'd0;
    
    reg[31:0]               araddr_ptr                  = 32'd0;
    wire[31:0]              araddr_ptr_nxt              = (m_arvalid & m_arready) ? araddr_ptr + M_RBURST_BYTES : araddr_ptr;
    always @(posedge clk)
        if (!rst_n)
            araddr_ptr <= 32'd0;
        else
            araddr_ptr <= araddr_ptr_nxt;
    always @(posedge clk)
        m_araddr <= ps2pl_baseaddr + (araddr_ptr_nxt & (ps2pl_size - 1));

endmodule