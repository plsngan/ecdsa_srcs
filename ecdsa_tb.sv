class seq_item_ecdsa;

  //rand bit [511:0] rand_h, rand_p;
  rand bit [511:0] rand_p;
  //constraint value_h {rand_h inside {[512'h1:512'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F]};}
  constraint value_p {rand_p inside {[256'h1:256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F]};}

endclass

module ECDSA_tb();

reg clk, start;
reg [255:0] key;
wire [511:0] sign;
wire busy;
integer i;

wire [511:0] message;
assign message =512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;

ECDSA ECDSA(.clk(clk), .message(message), .key(key), .sign(sign), .start(start), .busy(busy));
seq_item_ecdsa item;

//initial begin
//  $dumpfile("dump.vcd");
//  $dumpvars;
//  $finish;
//end

always #5 clk = ~clk;

initial begin
    clk = 1;  // initialize clk
    //item = new();
    start = 0;
    i = 0;
    #50
    //item.randomize();
    key = 256'hC9AFA9D845BA75166B5C215767B1D6934E50C3DB36E89B127B8A622B120F6721;
    @(posedge clk)

    start = 1;
    while (busy == 1) begin 
        @(posedge clk); 
        i=i+1; 
    end  
        //while (busy==1) @(posedge clk);
    $monitor("private=%h, message=%h, signature=%h, timescale=",key,message,sign, $realtime);
    $finish;

end
    
endmodule