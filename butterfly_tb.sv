`timescale 1ns/1ns

module butterfly_tb (
    output logic clk
);

localparam WIDTH = 24;
localparam HALF_WIDTH = WIDTH >> 1;

localparam W0_4 = {13'h0800, 13'h0000};
localparam W1_4 = {13'h0000, 13'h1800};
localparam W2_4 = {13'h1800, 13'h0000};

logic signed [WIDTH-1:0] a, b, c, d;
logic signed [WIDTH-1:0] out0, out1, out2, out3;

butterfly_4 #(.WIDTH(WIDTH)) DUT (
    .a(a),
    .b(b),
    .c(c),
    .d(d),
    .w1(W0_4),
    .w2(W0_4),
    .w3(W0_4),
    .out0(out0),
    .out1(out1),
    .out2(out2),
    .out3(out3)
);

initial begin
    clk = 0;
    a = {12'd100, 12'd0};
    b = {12'd150, 12'd0};
    c = {12'd200, 12'd0};
    d = {12'd250, 12'd0};
	 
	 #10;
	 assert (out0[WIDTH-1:HALF_WIDTH]   == 12'd700)    else $error("Re{0}");
	 assert (out0[HALF_WIDTH-1:0]       == 12'd0)      else $error("Im{0}");
	 assert (out1[WIDTH-1:HALF_WIDTH]   == -12'd100)   else $error("Re{1}");
	 assert (out1[HALF_WIDTH-1:0]       == 12'd100)    else $error("Im{1}");
	 assert (out2[WIDTH-1:HALF_WIDTH]   == -12'd100)   else $error("Re{2}");
	 assert (out2[HALF_WIDTH-1:0]       == 12'd0)      else $error("Im{2}");
	 assert (out3[WIDTH-1:HALF_WIDTH]   == -12'd100)   else $error("Re{3}");
	 assert (out3[HALF_WIDTH-1:0]       == -12'd100)   else $error("Im{3}");
    
    #100 $stop;
end

endmodule