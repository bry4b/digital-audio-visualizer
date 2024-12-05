module butterfly_4 #(
	parameter WIDTH=32
) (
	input signed [WIDTH-1:0] a, b, c, d,
	input signed [WIDTH+1:0] w0, w1, w2,	// +1 bit per side for sign extension

	output logic signed [WIDTH-1:0] out0, out1, out2, out3
);
/*
	A, B, C, D: 32bit time domain inputs 	-> 16bit real, 16bit imaginary
	W0, W1, W2: 32bit twiddle factors << 15 -> 16bit real, 16bit imaginary
	OUT0, OUT1, OUT2, OUT3: 32bit freq domain outputs -> 16bit real, 16bit imaginary
*/

localparam HALF_WIDTH = WIDTH >> 1;

logic signed [HALF_WIDTH-1:0] a_real, a_imag, b_real, b_imag, c_real, c_imag, d_real, d_imag;
logic signed [HALF_WIDTH:0] w0_real, w0_imag, w1_real, w1_imag, w2_real, w2_imag;

logic signed [WIDTH:0] t1_real, t1_imag, t2_real, t2_imag, t3_real, t3_imag;

assign a_real 	= a	[WIDTH-1:HALF_WIDTH];
assign a_imag 	= a [HALF_WIDTH-1:0];
assign b_real	= b	[WIDTH-1:HALF_WIDTH];
assign b_imag	= b	[HALF_WIDTH-1:0];
assign c_real 	= c	[WIDTH-1:HALF_WIDTH];
assign c_imag 	= c	[HALF_WIDTH-1:0];
assign d_real 	= d	[WIDTH-1:HALF_WIDTH];
assign d_imag 	= d	[HALF_WIDTH-1:0];
assign w0_real	= w0[WIDTH+1:HALF_WIDTH+1];
assign w0_imag	= w0[HALF_WIDTH:0]; 
assign w1_real	= w1[WIDTH+1:HALF_WIDTH+1];
assign w1_imag	= w1[HALF_WIDTH:0]; 
assign w2_real	= w2[WIDTH+1:HALF_WIDTH+1];
assign w2_imag	= w2[HALF_WIDTH:0]; 

assign t1_real = b_real * w0_real - b_imag * w0_imag;
assign t1_imag = b_imag * w0_real + b_real * w0_imag;
assign t2_real = c_real * w1_real - c_imag * w1_imag;
assign t2_imag = c_imag * w1_real + c_real * w1_imag;
assign t3_real = d_real * w2_real - d_imag * w2_imag;
assign t3_imag = d_imag * w2_real + d_real * w2_imag;

assign out0[WIDTH-1:HALF_WIDTH] = a_real + t1_real[WIDTH-2:HALF_WIDTH-1] + t2_real[WIDTH-2:HALF_WIDTH-1] + t3_real[WIDTH-2:HALF_WIDTH-1];	// Re{out0}
assign out0[HALF_WIDTH-1:0] 	= a_imag + t1_imag[WIDTH-2:HALF_WIDTH-1] + t2_imag[WIDTH-2:HALF_WIDTH-1] + t3_imag[WIDTH-2:HALF_WIDTH-1];	// Im{out0}
assign out1[WIDTH-1:HALF_WIDTH] = a_real + t1_imag[WIDTH-2:HALF_WIDTH-1] - t2_real[WIDTH-2:HALF_WIDTH-1] - t3_imag[WIDTH-2:HALF_WIDTH-1];	// Re{out1}
assign out1[HALF_WIDTH-1:0] 	= a_imag - t1_real[WIDTH-2:HALF_WIDTH-1] - t2_imag[WIDTH-2:HALF_WIDTH-1] + t3_real[WIDTH-2:HALF_WIDTH-1];	// Im{out1}
assign out2[WIDTH-1:HALF_WIDTH] = a_real - t1_real[WIDTH-2:HALF_WIDTH-1] + t2_real[WIDTH-2:HALF_WIDTH-1] - t3_real[WIDTH-2:HALF_WIDTH-1];	// Re{out2}
assign out2[HALF_WIDTH-1:0] 	= a_imag - t1_imag[WIDTH-2:HALF_WIDTH-1] + t2_imag[WIDTH-2:HALF_WIDTH-1] - t3_imag[WIDTH-2:HALF_WIDTH-1];	// Im{out2}
assign out3[WIDTH-1:HALF_WIDTH] = a_real - t1_imag[WIDTH-2:HALF_WIDTH-1] - t2_real[WIDTH-2:HALF_WIDTH-1] + t3_imag[WIDTH-2:HALF_WIDTH-1];	// Re{out3}
assign out3[HALF_WIDTH-1:0] 	= a_imag + t1_real[WIDTH-2:HALF_WIDTH-1] - t2_imag[WIDTH-2:HALF_WIDTH-1] - t3_real[WIDTH-2:HALF_WIDTH-1];	// Im{out3}

endmodule
	