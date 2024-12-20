`timescale 1ns/1ns

module butterfly_tb (
    output logic clk
);

localparam WIDTH = 16;
localparam FULL_WIDTH = WIDTH*2;

localparam W0_4 = { 16'd32767,     16'd0};        // W0
localparam W1_4 = { 16'd0,        -16'd32768};    // W1
localparam W2_4 = {-16'd32768,     16'd0};        // W2

logic [FULL_WIDTH-1:0] a, b, c, d;
logic [FULL_WIDTH-1:0] out0, out1, out2, out3;
logic [WIDTH-1:0] out0_re, out0_im, out1_re, out1_im, out2_re, out2_im, out3_re, out3_im;

assign out0_re = out0[FULL_WIDTH-1:WIDTH];
assign out0_im = out0[WIDTH-1:0];
assign out1_re = out1[FULL_WIDTH-1:WIDTH];
assign out1_im = out1[WIDTH-1:0];
assign out2_re = out2[FULL_WIDTH-1:WIDTH];
assign out2_im = out2[WIDTH-1:0];
assign out3_re= out3[FULL_WIDTH-1:WIDTH];
assign out3_im = out3[WIDTH-1:0];

butterfly_4 #(.FULL_WIDTH(FULL_WIDTH)) DUT (
    .a(a),
    .b(b),
    .c(c),
    .d(d),
    .w0(W0_4),
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
    a = {16'd100, 16'd0};
    b = {16'd150, 16'd0};
    c = {16'd200, 16'd0};
    d = {16'd250, 16'd0};
	 
    #10;
	//  assert (out0[WIDTH-1:HALF]   == 12'd700)    else $error("Re{0}");
	//  assert (out0[HALF-1:0]       == 12'd0)      else $error("Im{0}");
	//  assert (out1[WIDTH-1:HALF]   == -12'd100)   else $error("Re{1}");
	//  assert (out1[HALF-1:0]       == 12'd100)    else $error("Im{1}");
	//  assert (out2[WIDTH-1:HALF]   == -12'd100)   else $error("Re{2}");
	//  assert (out2[HALF-1:0]       == 12'd0)      else $error("Im{2}");
	//  assert (out3[WIDTH-1:HALF]   == -12'd100)   else $error("Re{3}");
	//  assert (out3[HALF-1:0]       == -12'd100)   else $error("Im{3}");
    
    #100 $stop;
end

endmodule