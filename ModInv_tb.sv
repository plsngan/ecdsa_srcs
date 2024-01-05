
`include "state_define.vh"

`define delay   10

class seq_item_inv_rand;

  rand bit [255:0] rand_A;
  constraint value_A {rand_A inside {[256'h1:256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F]};}

endclass

module ModInv_tb;

reg Expect;
reg [511:0] Mul;
reg [255:0] Mod;

reg clk, start;
reg [255:0] A;
wire [255:0] B;
wire busy;
integer i;

ModInv ModInv(.clk(clk), .A(A), .B(B), .start(start), .busy(busy));
seq_item_inv_rand item;

initial begin
  $dumpfile("dump_ModInv.vcd");
  $dumpvars;
end
always #5  clk = ~clk;

initial begin
    //p = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    clk=0;  // initialize clk
    item = new();
    
  repeat (3) begin
        i = 0;
        start = 0;
        #10
        item.randomize();
        A = item.rand_A;
        @(posedge clk)  #`delay;
        start = 1;
        @(posedge clk)  #`delay;
        while (busy==1) @(posedge clk) i = i+1;
        Mul = A * B; 
        Mod = Mul % `prime;
        if(Mod==1) begin
            $display("A=%h, B=%h, Expect=1, Timescale=",A,B, $realtime);
        end else begin
            $display("A=%h, B=%h, Expect=0, Timescale=",A,B, $realtime);
        end
    end
$finish;
end

endmodule