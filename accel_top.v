`timescale 1ns / 1ps

module accel_top #(
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
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s:m:toaccel:fromaccel, ASSOCIATED_RESET rst_n" *)
    input wire clk,

    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst_n RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
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
    output wire[M_AW-1:0]   m_awaddr,
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
    output wire[M_AW-1:0]   m_araddr,
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

    (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 intr_out INTERRUPT" *)
    (* X_INTERFACE_PARAMETER = "SENSITIVITY LEVEL_HIGH" *)
    output wire intr_out, //  (required)
    output wire fan_ctrl,
    
    output wire[127:0] toaccel_tdata,
    output wire        toaccel_tvalid,
    input wire         toaccel_tready,
    input wire[9:0]    toaccel_rdptr,
    
    input wire[127:0]  fromaccel_tdata,
    input wire         fromaccel_tvalid,
    output wire        fromaccel_tready,
    input wire[9:0]    fromaccel_wrptr
    
);
    axi4_controller #(
        .M_UW(M_UW),
        .M_IDW(M_IDW),
        .M_AW(M_AW),
        .M_DW(M_DW),
        .S_AW(S_AW),
        .S_DW(S_DW),
        .S_IDW(S_IDW)
    ) axi4_control(
    .clk(clk),
    
    .rst_n(rst_n),
    .s_awid(s_awid),
    .s_awaddr(s_awaddr), 
    .s_awlen(s_awlen),
    .s_awsize(s_awsize),
    .s_awburst(s_awburst),
    .s_awlock(s_awlock), 
    .s_awcache(s_awcache), 
    .s_awprot(s_awprot), 
    .s_awqos(s_awqos), 
    .s_awuser(s_awuser), 
    .s_awvalid(s_awvalid), 
    .s_awready(s_awready), 
    .s_wdata(s_wdata), 
    .s_wstrb(s_wstrb), 
    .s_wlast(s_wlast), 
    .s_wvalid(s_wvalid), 
    .s_wready(s_wready), 
    .s_bid(s_bid), 
    .s_bresp(s_bresp), 
    .s_bvalid(s_bvalid), 
    .s_bready(s_bready), 
    .s_arid(s_arid), 
    .s_araddr(s_araddr), 
    .s_arlen(s_arlen), 
    .s_arsize(s_arsize), 
    .s_arburst(s_arburst), 
    .s_arlock(s_arlock), 
    .s_arcache(s_arcache), 
    .s_arprot(s_arprot), 
    .s_arqos(s_arqos), 
    .s_aruser(s_aruser), 
    .s_arvalid(s_arvalid), 
    .s_arready(s_arready),
    .s_rid(s_rid), 
    .s_rdata(s_rdata), 
    .s_rresp(s_rresp), 
    .s_rlast(s_rlast),
    .s_rvalid(s_rvalid), 
    .s_rready(s_rready),

    .m_aruser(m_aruser),
    .m_awuser(m_awuser),

    .m_awid(m_awid),
    .m_awaddr(m_awaddr),
    .m_awlen(m_awlen),
    .m_awsize(m_awsize),
    .m_awburst(m_awburst),
    .m_awlock(m_awlock),
    .m_awcache(m_awcache),
    .m_awprot(m_awprot),
    .m_awvalid(m_awvalid),
    .m_awready(m_awready),

    .m_wdata(m_wdata),
    .m_wstrb(m_wstrb),
    .m_wlast(m_wlast),
    .m_wvalid(m_wvalid),
    .m_wready(m_wready),

    .m_bid(m_bid),
    .m_bresp(m_bresp),
    .m_bvalid(m_bvalid),
    .m_bready(m_bready),
    
    .m_arid(m_arid),
    .m_araddr(m_araddr),
    .m_arlen(m_arlen),
    .m_arsize(m_arsize),
    .m_arburst(m_arburst),
    .m_arlock(m_arlock),
    .m_arcache(m_arcache),
    .m_arprot(m_arprot),
    .m_arvalid(m_arvalid),
    .m_arready(m_arready),

    .m_rid(m_rid),
    .m_rdata(m_rdata),
    .m_rresp(m_rresp),
    .m_rlast(m_rlast),
    .m_rvalid(m_rvalid),
    .m_rready(m_rready),

    .m_awqos(m_awqos),
    .m_arqos(m_arqos),

    .intr_out(intr_out),
    .fan_ctrl(fan_ctrl),
    
    .toaccel_tdata(toaccel_tdata),
    .toaccel_tvalid(toaccel_tvalid),
    .toaccel_tready(toaccel_tready),
    .toaccel_rdptr(toaccel_rdptr),
    
    .fromaccel_tdata(fromaccel_tdata),
    .fromaccel_tvalid(fromaccel_tvalid),
    .fromaccel_tready(fromaccel_tready),
    .fromaccel_wrptr(fromaccel_wrptr)
    
);

endmodule