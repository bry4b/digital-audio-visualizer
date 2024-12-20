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
	input [WIDTH+1:0] freq_samples [0:N-1],
	output logic hsync,
	output logic vsync,
	output logic [3:0] red,
	output logic [3:0] green,
	output logic [3:0] blue
);

logic [9:0] hc_out;
logic [9:0] vc_out;

logic [5:0] x;
logic [5:0] y;
assign x = (hc_out >> 3)/5;	//	16 pixels wide
assign y = vc_out >> 4;	//	30 pixels tall

logic [7:0] color_to_vga;

logic [WIDTH-1:0] freq_scaled [0:N-1]; 
logic [WIDTH+3:0] bars [0:BARS-1];

genvar i;
generate 
	for (i = 0; i < N; i++) begin : scale_freq
		assign freq_scaled[i] = freq_samples[i] >> switches[3:0];
	end
endgenerate

logic [WIDTH+3:0] bars_7;
logic [WIDTH+3:0] bars_8;
logic [WIDTH+3:0] bars_9;
logic [WIDTH+3:0] bars_10;
logic [WIDTH+3:0] bars_11;
logic [WIDTH+3:0] bars_12;
logic [WIDTH+3:0] bars_13;
logic [WIDTH+3:0] bars_14;
logic [WIDTH+3:0] bars_15;

always_comb begin
	if (N == 256) begin
		bars_7  = 	((freq_scaled[8] + freq_scaled[9]) + (freq_scaled[10] + freq_scaled[11]));
		bars_8  = 	((freq_scaled[12] + freq_scaled[13]) + (freq_scaled[14] + freq_scaled[15]));
		bars_9  = 	((freq_scaled[16] + freq_scaled[17]) + (freq_scaled[18] + freq_scaled[19])) + ((freq_scaled[20] + freq_scaled[21]) + (freq_scaled[22] + freq_scaled[23]));
		bars_10 = 	((freq_scaled[24] + freq_scaled[25]) + (freq_scaled[26] + freq_scaled[27])) + ((freq_scaled[28] + freq_scaled[29]) + (freq_scaled[30] + freq_scaled[31]));
		bars_11	=	((freq_scaled[32] + freq_scaled[33]) + (freq_scaled[34] + freq_scaled[35])) + ((freq_scaled[36] + freq_scaled[37]) + (freq_scaled[38] + freq_scaled[39])) + 
					((freq_scaled[40] + freq_scaled[41]) + (freq_scaled[42] + freq_scaled[43]));
		bars_12 = 	((freq_scaled[44] + freq_scaled[45]) + (freq_scaled[46] + freq_scaled[47])) + ((freq_scaled[48] + freq_scaled[49]) + (freq_scaled[50] + freq_scaled[51])) + 
					((freq_scaled[52] + freq_scaled[53]) + (freq_scaled[54] + freq_scaled[55]));
		bars_13 = 	(((freq_scaled[56] + freq_scaled[57]) + (freq_scaled[58] + freq_scaled[59])) + ((freq_scaled[60] + freq_scaled[61]) + (freq_scaled[62] + freq_scaled[63]))) + 
					(((freq_scaled[64] + freq_scaled[65]) + (freq_scaled[66] + freq_scaled[67])) + ((freq_scaled[68] + freq_scaled[69]) + (freq_scaled[70] + freq_scaled[71])));
		bars_14 = 	(((freq_scaled[72] + freq_scaled[73]) + (freq_scaled[74] + freq_scaled[75])) + ((freq_scaled[76] + freq_scaled[77]) + (freq_scaled[78] + freq_scaled[79]))) + 
					(((freq_scaled[80] + freq_scaled[81]) + (freq_scaled[82] + freq_scaled[83])) + ((freq_scaled[84] + freq_scaled[85]) + (freq_scaled[86] + freq_scaled[87]))) + 
					(((freq_scaled[88] + freq_scaled[89]) + (freq_scaled[90] + freq_scaled[91])) + ((freq_scaled[92] + freq_scaled[93]) + (freq_scaled[94] + freq_scaled[95])));
		bars_15 = 	(((freq_scaled[96] + freq_scaled[97]) + (freq_scaled[98] + freq_scaled[99])) + ((freq_scaled[100] + freq_scaled[101]) + (freq_scaled[102] + freq_scaled[103]))) + 
					(((freq_scaled[104] + freq_scaled[105]) + (freq_scaled[106] + freq_scaled[107])) + ((freq_scaled[108] + freq_scaled[109]) + (freq_scaled[110] + freq_scaled[111]))) + 
					(((freq_scaled[112] + freq_scaled[113]) + (freq_scaled[114] + freq_scaled[115])) + ((freq_scaled[116] + freq_scaled[117]) + (freq_scaled[118] + freq_scaled[119]))) + 
					(((freq_scaled[120] + freq_scaled[121]) + (freq_scaled[122] + freq_scaled[123])) + ((freq_scaled[124] + freq_scaled[125]) + (freq_scaled[126] + freq_scaled[127])));
	end else begin
		bars_7 = 1'b0;
		bars_8 = 1'b0;
		bars_9 = 1'b0;
		bars_10 = 1'b0;
		bars_11 = 1'b0;
		bars_12 = 1'b0;
		bars_13 = 1'b0;
		bars_14 = 1'b0;
		bars_15 = 1'b0;
	end
end


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
			for (int i = 0; i < 16; i++) begin
				bars[i] <= freq_scaled[i];
			end
			// bars[0] <= freq_scaled[0];
			// bars[1] <= freq_scaled[1];
			// bars[2] <= freq_scaled[2];
			// bars[3] <= freq_scaled[3];
			// bars[4] <= freq_scaled[4];
			// bars[5] <= (freq_scaled[5] + freq_scaled[6]);
			// bars[6] <= (freq_scaled[7] + freq_scaled[8]);
			// // bars[7] <= bars_7 >> 7'd1;
			// // bars[8] <= bars_8 >> 7'd1;
			// // bars[9] <= bars_9 >> 7'd2;
			// // bars[10]<= bars_10 >> 7'd2;
			// // bars[11]<= bars_11 / 7'd6;
			// // bars[12]<= bars_12 / 7'd6;
			// // bars[13]<= bars_13 >> 7'd3;
			// // bars[14]<= bars_14 / 7'd12;
			// // bars[15]<= bars_15 >> 7'd4;
			// bars[7] <= bars_7;
			// bars[8] <= bars_8;
			// bars[9] <= bars_9;
			// bars[10]<= bars_10;
			// bars[11]<= bars_11;
			// bars[12]<= bars_12;
			// bars[13]<= bars_13;
			// bars[14]<= bars_14;
			// bars[15]<= bars_15;
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
		color_to_vga <= (y < 30 - bars[x]) ? 8'h01 : color_gradient[x];
	end
end

endmodule