`define delay   10

class seq_item_mul;

  rand bit [255:0] rand_A;
  rand bit [255:0] rand_B;
  constraint value_A {rand_A inside {[256'h1:256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF]};}
  constraint value_B {rand_B inside {[256'h1:256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF]};}

endclass


module Multiplier_tb;

reg [511:0] Expect;
reg clk, start;
reg [255:0] A,B;
wire busy;
wire [511:0] C;

Mul256with64 mult(.clk(clk), .start(start), .busy(busy), .A(A), .B(B), .C(C) );
seq_item_mul item;

initial begin
  $dumpfile("dump_mul.vcd");
  $dumpvars;
  #300000 
  $finish;
end

integer i;

always #50  clk = ~clk;

initial begin
    i = 0;
    clk=1;  // initialize clk
    item = new();
    repeat(300) begin
        start = 0;
        item.randomize();
        {A,B} = {item.rand_A, item.rand_B};
        Expect = A * B;
        @(posedge clk)  #`delay;
        start = 1;
        @(posedge clk)  #`delay;
        while (busy == 1) @(posedge clk) i = i+1;
        #10 start = 0;
        if(Expect == C) begin
            $display("Match A=%h B=%h C=%h Expect=%h",A,B,C,Expect);
        end else begin
            $display("Error A=%h B=%h C=%h Expect=%h",A,B,C,Expect);
        end
    end
$finish;
end
endmodule