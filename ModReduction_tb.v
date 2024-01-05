`define delay   10

class seq_item;

  rand bit [511:0] rand_A;
  constraint value_A {rand_A inside {[511'h1:511'hF]};}

endclass

module ModularReduction_tb;

reg [255:0] Expect;

reg clk, start;
reg [511:0] A;
wire busy;
wire [255:0] B;

ModRed ModRed (.clk(clk), .start(start), .busy(busy), .A(A), .B(B));
seq_item item;

initial begin
  $dumpfile("dump.vcd");
  $dumpvars;
  #10000 
  $finish;
end

always #50  clk = ~clk;

initial begin

    clk=1;  // initialize clk
    item = new();

    repeat(10) begin
        start = 0;
        item.randomize();
        A = item.rand_A;
        Expect = A % 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
        @(posedge clk)  #`delay;
        start = 1;
        @(posedge clk)  #`delay;
        while (busy==1) @(posedge clk);
            if(Expect==B) begin
                $display("Match: A=%h B=%h , timescale=",A,B,$realtime);
            end else begin
                $display("Error: A=%h B=%h , timescale=",A,B,$realtime);
        end
    end
$finish;
end

endmodule