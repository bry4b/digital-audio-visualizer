/*
	Convert to histogram - will need to adjust later for 256 bins
	Also need to fix screen tearing issue
*/
module graphics_controller # ( 
	parameter WIDTH = 12,
	parameter N = 256, 
	parameter BARS = 16
) (
	input clk_25MHz,	//	25 MHz clock
	input rst,
	input fft_done,
	input [9:0] switches,
	input [WIDTH:0] freq_samples [0:N-1],
	output logic hsync,
	output logic vsync,
	output logic [3:0] red,
	output logic [3:0] green,
	output logic [3:0] blue
);

localparam USED_BINS = 69;
logic [9:0] hc_out;
logic [9:0] vc_out;

logic [5:0] x;
logic [5:0] y;
assign x = (hc_out >> 3)/5;	//	16 pixels wide
assign y = vc_out >> 4;	//	30 pixels tall

logic [7:0] color_to_vga;

logic [0:USED_BINS-1] [5:0] freq_scaled; 
logic [0:BARS-1] [5:0] bars ;

genvar i;
generate 
	for (i = 0; i < USED_BINS; i++) begin : scale_freq
		assign freq_scaled[i] = freq_samples[i] >> 4'd8;
	end
endgenerate

// update bars on rising edge of vsync 
logic [1:0] vsync_sr = 2'b00; 
always @(posedge clk_25MHz) begin
	vsync_sr <= {vsync_sr[0], vsync};
	if (vsync_sr == 2'b01) begin
		if (N == 16) begin
			for (int i = 0; i < N; i = i + 1) begin
				bars[i] <= freq_scaled[i];
			end
		end else if (N == 256) begin
			// for (int i = 0; i < 16; i++) begin
			// 	bars[i] <= freq_scaled[i];
			// end
			bars[0] <= 	(freq_scaled[1]>>3) + ((bars[0]*7)>>3);
			bars[1] <= 	(freq_scaled[2]>>3) + ((bars[1]*7)>>3);
			bars[2] <= 	(freq_scaled[3]>>3) + ((bars[2]*7)>>3);
			bars[3] <= 	(freq_scaled[4]>>3) + ((bars[3]*7)>>3);
			bars[4] <= 	(freq_scaled[5]>>3) + ((bars[4]*7)>>3);
			bars[5] <= 	(freq_scaled[6]>>3) + ((bars[5]*7)>>3);
			bars[6] <= 	(freq_scaled[7]>>3) + ((bars[6]*7)>>3);
			bars[7] <= 	(freq_scaled[8]>>3) + ((bars[7]*7)>>3);
			bars[8] <= 	((((freq_scaled[9]/1)  + (freq_scaled[10]/1)))>>3) + ((bars[8]*7)>>3);
			bars[9] <= 	((((freq_scaled[11]/1) + (freq_scaled[12]/1)))>>3) + ((bars[9]*7)>>3);
			bars[10]<= 	((((freq_scaled[13]/2) + (freq_scaled[14]/2))) + (((freq_scaled[15]/2) + (freq_scaled[16]/2)))>>3) + ((bars[10]*7)>>3);
			bars[11]<= 	((((freq_scaled[17]/2) + (freq_scaled[18]/2))) + (((freq_scaled[19]/2) + (freq_scaled[20]/2)))>>3) + ((bars[11]*7)>>3);
			bars[12]<= (((((freq_scaled[21]/4) + (freq_scaled[22]/4))) + (((freq_scaled[23]/4) + (freq_scaled[24]/4)))) + 
						((((freq_scaled[25]/4) + (freq_scaled[26]/4))) + (((freq_scaled[27]/4) + (freq_scaled[28]/4))))>>3) + ((bars[12]*7)>>3);
			bars[13]<= (((((freq_scaled[29]/4) + (freq_scaled[30]/4))) + (((freq_scaled[31]/4) + (freq_scaled[32]/4)))) + 
						((((freq_scaled[33]/4) + (freq_scaled[34]/4))) + (((freq_scaled[35]/4) + (freq_scaled[36]/4))))>>3) + ((bars[13]*7)>>3);
			bars[14]<= (((((freq_scaled[37]/8) + (freq_scaled[38]/8))) + (((freq_scaled[39]/8) + (freq_scaled[40]/8)))) +
						((((freq_scaled[41]/8) + (freq_scaled[42]/8))) + (((freq_scaled[43]/8) + (freq_scaled[44]/8)))) +
						((((freq_scaled[45]/8) + (freq_scaled[46]/8))) + (((freq_scaled[47]/8) + (freq_scaled[48]/8)))) +
						((((freq_scaled[49]/8) + (freq_scaled[50]/8))) + (((freq_scaled[51]/8) + (freq_scaled[52]/8))))>>3) + ((bars[14]*7)>>3);
			bars[15]<= (((((freq_scaled[53]/8) + (freq_scaled[54]/8))) + (((freq_scaled[55]/8) + (freq_scaled[56]/8)))) + 
						((((freq_scaled[57]/8) + (freq_scaled[58]/8))) + (((freq_scaled[59]/8) + (freq_scaled[60]/8)))) + 
						((((freq_scaled[61]/8) + (freq_scaled[62]/8))) + (((freq_scaled[63]/8) + (freq_scaled[64]/8)))) + 
						((((freq_scaled[65]/8) + (freq_scaled[66]/8))) + (((freq_scaled[67]/8) + (freq_scaled[68]/8))))>>3) + ((bars[15]*7)>>3);
			// bars[0] <= 	freq_scaled[1];
			// bars[1] <= 	freq_scaled[2];
			// bars[2] <= 	freq_scaled[3];
			// bars[3] <= 	freq_scaled[4];
			// bars[4] <= 	freq_scaled[5];
			// bars[5] <= 	freq_scaled[6];
			// bars[6] <= 	freq_scaled[7];
			// bars[7] <= 	freq_scaled[8];
			// bars[8] <= 	((freq_scaled[9] + freq_scaled[10]));
			// bars[9] <= 	((freq_scaled[11] + freq_scaled[12]));
			// bars[10]<= 	((freq_scaled[13] + freq_scaled[14])) + ((freq_scaled[15] + freq_scaled[16]));
			// bars[11]<= 	((freq_scaled[17] + freq_scaled[18])) + ((freq_scaled[19] + freq_scaled[20]));
			// bars[12]<= 	(((freq_scaled[21] + freq_scaled[22])) + ((freq_scaled[23] + freq_scaled[24]))) + 
			// 			(((freq_scaled[25] + freq_scaled[26])) + ((freq_scaled[27] + freq_scaled[28])));
			// bars[13]<= 	(((freq_scaled[29] + freq_scaled[30])) + ((freq_scaled[31] + freq_scaled[32]))) + 
			// 			(((freq_scaled[33] + freq_scaled[34])) + ((freq_scaled[35] + freq_scaled[36])));
			// bars[14]<= 	(((freq_scaled[37] + freq_scaled[38])) + ((freq_scaled[39] + freq_scaled[40]))) +
			// 			(((freq_scaled[41] + freq_scaled[42])) + ((freq_scaled[43] + freq_scaled[44]))) +
			// 			(((freq_scaled[45] + freq_scaled[46])) + ((freq_scaled[47] + freq_scaled[48]))) +
			// 			(((freq_scaled[49] + freq_scaled[50])) + ((freq_scaled[51] + freq_scaled[52])));
			// bars[15]<= 	(((freq_scaled[53] + freq_scaled[54])) + ((freq_scaled[55] + freq_scaled[56]))) + 
			// 			(((freq_scaled[57] + freq_scaled[58])) + ((freq_scaled[59] + freq_scaled[60]))) + 
			// 			(((freq_scaled[61] + freq_scaled[62])) + ((freq_scaled[63] + freq_scaled[64]))) + 
			// 			(((freq_scaled[65] + freq_scaled[66])) + ((freq_scaled[67] + freq_scaled[68])));
		end
	end
end
	
vga VGA (
	.vgaclk(clk_25MHz), 
	.input_red(color_to_vga[7:5]), 
	.input_green(color_to_vga[4:2]), 
	.input_blue(color_to_vga[1:0]),
	.rst(rst), 
	.hc_out(hc_out), 
	.vc_out(vc_out), 
	.hsync(hsync), 
	.vsync(vsync),
	.red(red), 
	.green(green), 
	.blue(blue) 
);

logic [7:0] color_gradient [0:15] = '{
	8'hE0, 8'hC4, 8'hA8, 8'h8C, 8'h70, 8'h54, 8'h38, 8'h1C, 8'h18, 8'h1A, 8'h1E, 8'h1F, 8'h3F, 8'h5F, 8'h7F, 8'h9F
};

always @(posedge clk_25MHz) begin
	if (x < 16) begin
		color_to_vga <= (y < ((bars[x] > 30) ? 0 : 30-bars[x])) ? 8'h00 : color_gradient[x];
	end
end

endmodule