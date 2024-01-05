`timescale 1ns / 1ps



module acc_core(
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk_core CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET rst_core" *)
    input wire clk_core,

    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst_core RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input wire rst_core,
    
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk_if CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF ina:outa, ASSOCIATED_RESET rst_if" *)
    input wire clk_if,

    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst_if RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input wire rst_if,
    
    input wire[127:0] ina_tdata,
    input wire        ina_tvalid,
    output wire       ina_tready,
    output wire[9:0]  ina_rdptr,
    
    
    output wire[127:0] outa_tdata,
    output wire        outa_tvalid,
    input wire         outa_tready,
    output wire[9:0]   outa_wrptr
    
);



    wire[127:0] rd_tdata;
    wire rd_tvalid;
    wire rd_tready;
    cdcFifo #(
        .DEPTH(512),
        .WIDTH(128)
    ) ina_fifo(
        .wr_rst(rst_if),
        .wr_clk(clk_if),
        .wr_tdata(ina_tdata),
        .wr_tvalid(ina_tvalid),
        .wr_tready(ina_tready),
        .w_rdptr_o(ina_rdptr),
        
        .rd_rst(rst_core),
        .rd_clk(clk_core),
        .rd_tdata(rd_tdata),
        .rd_tvalid(rd_tvalid),
        .rd_tready(rd_tready),
        .r_wrptr_o()
    );
    
    
    
    reg[255:0] ecdsa_in_data;
    wire ecdsa_in_valid;
    wire ecdsa_in_ready;
    
    reg[1:0] des_counter = 0;
    
    always @(posedge clk_core)
        if (rd_tvalid & rd_tready)
            ecdsa_in_data <= {rd_tdata, ecdsa_in_data[255:128]};
    
    always @(posedge clk_core)
        if (rst_core)
            des_counter <= 0;
        else if (ecdsa_in_valid & ecdsa_in_ready)
            des_counter <= 0;
        else if (rd_tvalid & rd_tready)
            des_counter <= des_counter + 1'b1;
    
    assign rd_tready = des_counter < 2;
    assign ecdsa_in_valid = des_counter >= 2;
    
    wire[255:0] ecdsa_out_data;
    
    wire ecdsa_out_valid;
    wire ecdsa_out_ready;
    
    aes_accel ecdsa_if(
        .clk(clk_core),
        .rst_n(~rst_core),
        
        .ina_tdata(ecdsa_in_data),
        .ina_tvalid(ecdsa_in_valid),
        .ina_tready(ecdsa_in_ready),
        
        .outa_tdata(ecdsa_out_data),
        .outa_tvalid(ecdsa_out_valid),
        .outa_tready(ecdsa_out_ready)
    );
    
    reg[255:0] ecdsa_out_data_q;
    always @(posedge clk_core)
        if (ecdsa_out_valid & ecdsa_out_ready)
            ecdsa_out_data_q <= ecdsa_out_data;
        else if (wr_tvalid & wr_tready)
            ecdsa_out_data_q <= {128'h0, ecdsa_out_data_q[255:128]};
    reg[1:0] ser_counter = 0;
    
    wire[127:0] wr_tdata;
    wire wr_tvalid;
    wire wr_tready;
    
    always @(posedge clk_core)
        if (rst_core)
            ser_counter <= 0;
        else if (ecdsa_out_valid & ecdsa_out_ready)
            ser_counter <= 2;
        else if (wr_tvalid & wr_tready)
            ser_counter <= ser_counter - 1'b1;
    
    assign wr_tvalid = ser_counter != 0;
    assign ecdsa_out_ready = ser_counter == 0;
    
    assign wr_tdata = ecdsa_out_data_q[127:0];
    
    
    cdcFifo #(
        .DEPTH(512),
        .WIDTH(128)
    ) outa_fifo(
        .wr_rst(rst_core),
        .wr_clk(clk_core),
        .wr_tdata(wr_tdata),
        .wr_tvalid(wr_tvalid),
        .wr_tready(wr_tready),
        .w_rdptr_o(),
        
        .rd_rst(rst_if),
        .rd_clk(clk_if),
        .rd_tdata(outa_tdata),
        .rd_tvalid(outa_tvalid),
        .rd_tready(outa_tready),
        .r_wrptr_o(outa_wrptr)
    );
    
endmodule
