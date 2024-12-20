module butterfly_4 #(
	parameter FULL_WIDTH=32
) (
	input signed [FULL_WIDTH-1:0] a, b, c, d,
	input signed [FULL_WIDTH-1:0] w0, w1, w2, w3,

	output logic signed [FULL_WIDTH-1:0] out0, out1, out2, out3
);
/*
	A, B, C, D: time domain inputs 	-> 16bit real, 16bit imaginary
	W0, W1, W2, W3: twiddle factors << 15 -> 16bit real, 16bit imaginary
	OUT0, OUT1, OUT2, OUT3: freq domain outputs -> 16bit real, 16bit imaginary
*/

localparam WIDTH = FULL_WIDTH / 2;

logic signed [WIDTH-1:0] a_real, a_imag, b_real, b_imag, c_real, c_imag, d_real, d_imag;
logic signed [WIDTH-1:0] w0_real, w0_imag, w1_real, w1_imag, w2_real, w2_imag, w3_real, w3_imag;

logic signed [FULL_WIDTH-1:0] t0_real, t0_imag, t1_real, t1_imag, t2_real, t2_imag, t3_real, t3_imag;

assign a_real 	= a	[FULL_WIDTH-1:WIDTH];
assign a_imag 	= a [WIDTH-1:0];
assign b_real	= b	[FULL_WIDTH-1:WIDTH];
assign b_imag	= b	[WIDTH-1:0];
assign c_real 	= c	[FULL_WIDTH-1:WIDTH];
assign c_imag 	= c	[WIDTH-1:0];
assign d_real 	= d	[FULL_WIDTH-1:WIDTH];
assign d_imag 	= d	[WIDTH-1:0];
assign w0_real 	= w0[FULL_WIDTH-1:WIDTH];
assign w0_imag 	= w0[WIDTH-1:0];
assign w1_real	= w1[FULL_WIDTH-1:WIDTH];
assign w1_imag	= w1[WIDTH-1:0]; 
assign w2_real	= w2[FULL_WIDTH-1:WIDTH];
assign w2_imag	= w2[WIDTH-1:0]; 
assign w3_real	= w3[FULL_WIDTH-1:WIDTH];
assign w3_imag	= w3[WIDTH-1:0]; 

assign t0_real = a_real * w0_real - a_imag * w0_imag;
assign t0_imag = a_imag * w0_real + a_real * w0_imag;
assign t1_real = b_real * w1_real - b_imag * w1_imag;
assign t1_imag = b_imag * w1_real + b_real * w1_imag;
assign t2_real = c_real * w2_real - c_imag * w2_imag;
assign t2_imag = c_imag * w2_real + c_real * w2_imag;
assign t3_real = d_real * w3_real - d_imag * w3_imag;
assign t3_imag = d_imag * w3_real + d_real * w3_imag;

assign out0[FULL_WIDTH-1:WIDTH] = t0_real[FULL_WIDTH-2:WIDTH-1] + t1_real[FULL_WIDTH-2:WIDTH-1] + t2_real[FULL_WIDTH-2:WIDTH-1] + t3_real[FULL_WIDTH-2:WIDTH-1];	// Re{out0}
assign out0[WIDTH-1:0] 			= t0_imag[FULL_WIDTH-2:WIDTH-1] + t1_imag[FULL_WIDTH-2:WIDTH-1] + t2_imag[FULL_WIDTH-2:WIDTH-1] + t3_imag[FULL_WIDTH-2:WIDTH-1];	// Im{out0}
assign out1[FULL_WIDTH-1:WIDTH] = t0_real[FULL_WIDTH-2:WIDTH-1] + t1_imag[FULL_WIDTH-2:WIDTH-1] - t2_real[FULL_WIDTH-2:WIDTH-1] - t3_imag[FULL_WIDTH-2:WIDTH-1];	// Re{out1}
assign out1[WIDTH-1:0] 			= t0_imag[FULL_WIDTH-2:WIDTH-1] - t1_real[FULL_WIDTH-2:WIDTH-1] - t2_imag[FULL_WIDTH-2:WIDTH-1] + t3_real[FULL_WIDTH-2:WIDTH-1];	// Im{out1}
assign out2[FULL_WIDTH-1:WIDTH] = t0_real[FULL_WIDTH-2:WIDTH-1] - t1_real[FULL_WIDTH-2:WIDTH-1] + t2_real[FULL_WIDTH-2:WIDTH-1] - t3_real[FULL_WIDTH-2:WIDTH-1];	// Re{out2}
assign out2[WIDTH-1:0] 			= t0_imag[FULL_WIDTH-2:WIDTH-1] - t1_imag[FULL_WIDTH-2:WIDTH-1] + t2_imag[FULL_WIDTH-2:WIDTH-1] - t3_imag[FULL_WIDTH-2:WIDTH-1];	// Im{out2}
assign out3[FULL_WIDTH-1:WIDTH] = t0_real[FULL_WIDTH-2:WIDTH-1] - t1_imag[FULL_WIDTH-2:WIDTH-1] - t2_real[FULL_WIDTH-2:WIDTH-1] + t3_imag[FULL_WIDTH-2:WIDTH-1];	// Re{out3}
assign out3[WIDTH-1:0] 			= t0_imag[FULL_WIDTH-2:WIDTH-1] + t1_real[FULL_WIDTH-2:WIDTH-1] - t2_imag[FULL_WIDTH-2:WIDTH-1] - t3_real[FULL_WIDTH-2:WIDTH-1];	// Im{out3}

endmodule
	