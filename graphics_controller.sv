module graphics_controller # (
	parameter GFX_WIDTH = 6,
	parameter N = 256, 
	parameter USED_SAMPLES = 70,
	parameter BARS = 32
) (
	input clk_25MHz,	//	25 MHz clock
	input rst,
	input fft_done,
	input [9:0] switches,
	input [GFX_WIDTH-1:0] freq_scaled [0:USED_SAMPLES-1],	// pass in scaled freq_samples for USED_SAMPLES = 99
	output logic hsync,
	output logic vsync,
	output logic [3:0] red,
	output logic [3:0] green,
	output logic [3:0] blue
);

// VGA SIGNALS
logic [9:0] hc_out;
logic [9:0] vc_out;
logic [5:0] x;
logic [5:0] y;
assign x = (hc_out >> 2)/5;	//	16 pixels wide: 16 frequency bins displayed
assign y = vc_out >> 4;	//	30 pixels tall: using 6-bit wide bars, which ranges up to 64
logic [7:0] color_to_vga;

// HISTOGRAM LOGIC
// logic [0:100] [5:0] freq_scaled; 
logic [0:BARS-1] [GFX_WIDTH-1:0] bars;

// moving average control
logic [1:0] ema_alpha;
logic [3:0] ema_decay;
assign ema_alpha = switches[1:0];
assign ema_decay = (3'b1 << ema_alpha) - 1'b1;

// genvar i;
// generate 
// 	for (i = 0; i < 101; i++) begin : scale_freq
// 		assign freq_scaled[i] = freq_samples[i] >> 4'd8;
// 	end
// endgenerate

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
			if (USED_SAMPLES == 99 && BARS == 16) begin
				bars[0]  <= (freq_scaled[0]  >> ema_alpha) + ((bars[0]  * ema_decay) >> ema_alpha);
				bars[1]  <= (freq_scaled[1]  >> ema_alpha) + ((bars[1]  * ema_decay) >> ema_alpha);
				bars[2]  <= (freq_scaled[2]  >> ema_alpha) + ((bars[2]  * ema_decay) >> ema_alpha);
				bars[3]  <= (freq_scaled[3]  >> ema_alpha) + ((bars[3]  * ema_decay) >> ema_alpha);
				bars[4]  <= (freq_scaled[4]  >> ema_alpha) + ((bars[4]  * ema_decay) >> ema_alpha);
				bars[5]  <= (freq_scaled[5]  >> ema_alpha) + ((bars[5]  * ema_decay) >> ema_alpha);
				bars[6]  <= (freq_scaled[6]  >> ema_alpha) + ((bars[6]  * ema_decay) >> ema_alpha);
				bars[7]  <= ((freq_scaled[7] >> 1  + freq_scaled[8] >> 1) >> ema_alpha) + ((bars[7]  * ema_decay) >> ema_alpha);
				bars[8]  <= ((freq_scaled[9] >> 1  + freq_scaled[10]>> 1) >> ema_alpha) + ((bars[8]  * ema_decay) >> ema_alpha);
				bars[9]  <= ((((freq_scaled[11] >> 1) + (freq_scaled[12] >> 1)) +
							  ((freq_scaled[13] >> 1) + (freq_scaled[14] >> 1))) >> ema_alpha) +
							((bars[9] * ema_decay) >> ema_alpha);
				bars[10] <= ((((freq_scaled[15] >> 1) + (freq_scaled[16] >> 1)) +
							  ((freq_scaled[17] >> 1) + (freq_scaled[18] >> 1))) >> ema_alpha) +
							((bars[10] * ema_decay) >> ema_alpha);
				bars[11] <= (((((freq_scaled[19] >> 2) + (freq_scaled[20] >> 2))  +
							   ((freq_scaled[21] >> 2) + (freq_scaled[22] >> 2))) +
							  (((freq_scaled[23] >> 2) + (freq_scaled[24] >> 2))  +
							   ((freq_scaled[25] >> 2) + (freq_scaled[26] >> 2)))) >> ema_alpha) +
							((bars[11] * ema_decay) >> ema_alpha);
				bars[12] <= (((((freq_scaled[27] >> 2) + (freq_scaled[28] >> 2))  +
							   ((freq_scaled[29] >> 2) + (freq_scaled[30] >> 2))) +
							  (((freq_scaled[31] >> 2) + (freq_scaled[32] >> 2))  +
							   ((freq_scaled[33] >> 2) + (freq_scaled[34] >> 2)))) >> ema_alpha) +
							((bars[12] * ema_decay) >> ema_alpha);
				bars[13] <= ((((((freq_scaled[35] >> 3) + (freq_scaled[36] >> 3))   +
								((freq_scaled[37] >> 3) + (freq_scaled[38] >> 3)))  +
							   (((freq_scaled[39] >> 3) + (freq_scaled[40] >> 3))   +
								((freq_scaled[41] >> 3) + (freq_scaled[42] >> 3)))) +
							  ((((freq_scaled[43] >> 3) + (freq_scaled[44] >> 3))   +
								((freq_scaled[45] >> 3) + (freq_scaled[46] >> 3)))  +
							   (((freq_scaled[47] >> 3) + (freq_scaled[48] >> 3))   +
								((freq_scaled[49] >> 3) + (freq_scaled[50] >> 3))))) >> ema_alpha) +
							((bars[13] * ema_decay) >> ema_alpha);
				bars[14] <= ((((((freq_scaled[51] >> 3) + (freq_scaled[52] >> 3))   +
								((freq_scaled[53] >> 3) + (freq_scaled[54] >> 3)))  +
							   (((freq_scaled[55] >> 3) + (freq_scaled[56] >> 3))   +
								((freq_scaled[57] >> 3) + (freq_scaled[58] >> 3)))) +
							  ((((freq_scaled[59] >> 3) + (freq_scaled[60] >> 3))   +
								((freq_scaled[61] >> 3) + (freq_scaled[62] >> 3)))  +
							   (((freq_scaled[63] >> 3) + (freq_scaled[64] >> 3))   +
								((freq_scaled[65] >> 3) + (freq_scaled[66] >> 3))))) >> ema_alpha) +
							((bars[14] * ema_decay) >> ema_alpha);
				bars[15] <= (((((((freq_scaled[67] >> 4) | (freq_scaled[68] >> 4))    |
								 ((freq_scaled[69] >> 4) | (freq_scaled[70] >> 4)))   |
								(((freq_scaled[71] >> 4) | (freq_scaled[72] >> 4))    |
								 ((freq_scaled[73] >> 4) | (freq_scaled[74] >> 4))))  |
							   ((((freq_scaled[75] >> 4) | (freq_scaled[76] >> 4))    |
								 ((freq_scaled[77] >> 4) | (freq_scaled[78] >> 4)))   |
								(((freq_scaled[79] >> 4) | (freq_scaled[80] >> 4))    |
								 ((freq_scaled[81] >> 4) | (freq_scaled[82] >> 4))))) |
							  (((((freq_scaled[83] >> 4) | (freq_scaled[84] >> 4))    |
								 ((freq_scaled[85] >> 4) | (freq_scaled[86] >> 4)))   |
								(((freq_scaled[87] >> 4) | (freq_scaled[88] >> 4))    |
								 ((freq_scaled[89] >> 4) | (freq_scaled[90] >> 4))))  |
							   ((((freq_scaled[91] >> 4) | (freq_scaled[92] >> 4))    |
								 ((freq_scaled[93] >> 4) | (freq_scaled[94] >> 4)))   |
								(((freq_scaled[95] >> 4) | (freq_scaled[96] >> 4))    |
								 ((freq_scaled[97] >> 4) | (freq_scaled[98] >> 4)))))) >> ema_alpha) +
							((bars[15] * ema_decay) >> ema_alpha);

			// 	bars[0] <= 		(freq_scaled[2]>>ema_alpha) + ((bars[0]*ema_decay)>>ema_alpha);
			// 	bars[1] <=		(freq_scaled[3]>>ema_alpha) + ((bars[1]*ema_decay)>>ema_alpha);
			// 	bars[2] <=		(freq_scaled[4]>>ema_alpha) + ((bars[2]*ema_decay)>>ema_alpha);
			// 	bars[3] <=		(freq_scaled[5]>>ema_alpha) + ((bars[3]*ema_decay)>>ema_alpha);
			// 	bars[4] <=		(freq_scaled[6]>>ema_alpha) + ((bars[4]*ema_decay)>>ema_alpha);
			// 	bars[5] <=		(freq_scaled[7]>>ema_alpha) + ((bars[5]*ema_decay)>>ema_alpha);
			// 	bars[6] <=		(freq_scaled[8]>>ema_alpha) + ((bars[6]*ema_decay)>>ema_alpha);
			// 	bars[7] <=	 ((((freq_scaled[9])    + (freq_scaled[10])))>>ema_alpha) + ((bars[7]*ema_decay)>>ema_alpha);
			// 	bars[8] <=	 ((((freq_scaled[11])   + (freq_scaled[12])))>>ema_alpha) + ((bars[8]*ema_decay)>>ema_alpha);
			// 	bars[9] <=	(((((freq_scaled[13]>>1) + (freq_scaled[14]>>1))) + (((freq_scaled[15]>>1) + (freq_scaled[16]>>1))))>>ema_alpha) + ((bars[9]*ema_decay)>>ema_alpha);
			// 	bars[10]<= 	(((((freq_scaled[17]>>1) + (freq_scaled[18]>>1))) + (((freq_scaled[19]>>1) + (freq_scaled[20]>>1))))>>ema_alpha) + ((bars[10]*ema_decay)>>ema_alpha);
			// 	bars[11]<= ((((((freq_scaled[21]>>2) + (freq_scaled[22]>>2))) + (((freq_scaled[23]>>2) + (freq_scaled[24]>>2)))) + 
			// 				((((freq_scaled[25]>>2) + (freq_scaled[26]>>2))) + (((freq_scaled[27]>>2) + (freq_scaled[28]>>2)))))>>ema_alpha) + ((bars[11]*ema_decay)>>ema_alpha);
			// 	bars[12]<= ((((((freq_scaled[29]>>2) + (freq_scaled[30]>>2))) + (((freq_scaled[31]>>2) + (freq_scaled[32]>>2)))) + 
			// 				((((freq_scaled[33]>>2) + (freq_scaled[34]>>2))) + (((freq_scaled[35]>>2) + (freq_scaled[36]>>2)))))>>ema_alpha) + ((bars[12]*ema_decay)>>ema_alpha);
			// 	bars[13]<= ((((((freq_scaled[37]>>3) + (freq_scaled[38]>>3))) + (((freq_scaled[39]>>3) + (freq_scaled[40]>>3)))) +
			// 				((((freq_scaled[41]>>3) + (freq_scaled[42]>>3))) + (((freq_scaled[43]>>3) + (freq_scaled[44]>>3)))) +
			// 				((((freq_scaled[45]>>3) + (freq_scaled[46]>>3))) + (((freq_scaled[47]>>3) + (freq_scaled[48]>>3)))) +
			// 				((((freq_scaled[49]>>3) + (freq_scaled[50]>>3))) + (((freq_scaled[51]>>3) + (freq_scaled[52]>>3)))))>>ema_alpha) + ((bars[13]*ema_decay)>>ema_alpha);
			// 	bars[14]<= ((((((freq_scaled[53]>>3) + (freq_scaled[54]>>3))) + (((freq_scaled[55]>>3) + (freq_scaled[56]>>3)))) + 
			// 				((((freq_scaled[57]>>3) + (freq_scaled[58]>>3))) + (((freq_scaled[59]>>3) + (freq_scaled[60]>>3)))) + 
			// 				((((freq_scaled[61]>>3) + (freq_scaled[62]>>3))) + (((freq_scaled[63]>>3) + (freq_scaled[64]>>3)))) + 
			// 				((((freq_scaled[65]>>3) + (freq_scaled[66]>>3))) + (((freq_scaled[67]>>3) + (freq_scaled[68]>>3)))))>>ema_alpha) + ((bars[14]*ema_decay)>>ema_alpha);
			// 	bars[15]<=(((((((freq_scaled[69]>>4) | (freq_scaled[70]>>4))  | ((freq_scaled[71]>>4) | (freq_scaled[72]>>4))) + 
			// 				(((freq_scaled[73]>>4) | (freq_scaled[74]>>4))  | ((freq_scaled[75]>>4) | (freq_scaled[76]>>4)))) + 
			// 				(((((freq_scaled[77]>>4) | (freq_scaled[78]>>4))  | ((freq_scaled[79]>>4) | (freq_scaled[80]>>4)))) + 
			// 				(((freq_scaled[81]>>4) | (freq_scaled[82]>>4))) | ((freq_scaled[83]>>4) | (freq_scaled[84]>>4)))) + 
			// 				(((((freq_scaled[85]>>4) | (freq_scaled[86]>>4))  | ((freq_scaled[87]>>4) | (freq_scaled[88]>>4))) + 
			// 				(((freq_scaled[89]>>4) | (freq_scaled[90]>>4))  | ((freq_scaled[91]>>4) | (freq_scaled[92]>>4)))) + 
			// 				(((((freq_scaled[93]>>4) | (freq_scaled[94]>>4))  | ((freq_scaled[95]>>4) | (freq_scaled[96]>>4)))) + 
			// 				(((freq_scaled[97]>>4) | (freq_scaled[98]>>4))) | ((freq_scaled[99]>>4) | (freq_scaled[100]>>4)))))>>ema_alpha) + ((bars[15]*ema_decay)>>ema_alpha);
			end else if (USED_SAMPLES == 70 && BARS == 16) begin
				bars[0] <= 		(freq_scaled[0]>>ema_alpha) + ((bars[0]*ema_decay)>>ema_alpha);
				bars[1] <=		(freq_scaled[1]>>ema_alpha) + ((bars[1]*ema_decay)>>ema_alpha);
				bars[2] <=		(freq_scaled[2]>>ema_alpha) + ((bars[2]*ema_decay)>>ema_alpha);
				bars[3] <=		(freq_scaled[3]>>ema_alpha) + ((bars[3]*ema_decay)>>ema_alpha);
				bars[4] <=		(freq_scaled[4]>>ema_alpha) + ((bars[4]*ema_decay)>>ema_alpha);
				bars[5] <=		(freq_scaled[5]>>ema_alpha) + ((bars[5]*ema_decay)>>ema_alpha);
				bars[6] <=		(freq_scaled[6]>>ema_alpha) + ((bars[6]*ema_decay)>>ema_alpha);
				bars[7] <=		(freq_scaled[7]>>ema_alpha) + ((bars[7]*ema_decay)>>ema_alpha);
				bars[8] <=	 ((((freq_scaled[8])    + (freq_scaled[9])))>>ema_alpha) + ((bars[8]*ema_decay)>>ema_alpha);
				bars[9] <= 	 ((((freq_scaled[10])   + (freq_scaled[11])))>>ema_alpha) + ((bars[9]*ema_decay)>>ema_alpha);
				bars[10]<=	(((((freq_scaled[12]>>1) + (freq_scaled[13]>>1))) + (((freq_scaled[14]>>1) + (freq_scaled[15]>>1))))>>ema_alpha) + ((bars[10]*ema_decay)>>ema_alpha);
				bars[11]<=  (((((freq_scaled[16]>>1) + (freq_scaled[17]>>1))) + (((freq_scaled[18]>>1) + (freq_scaled[19]>>1))))>>ema_alpha) + ((bars[11]*ema_decay)>>ema_alpha);
				bars[12]<= ((((((freq_scaled[20]>>2) + (freq_scaled[21]>>2))) + (((freq_scaled[22]>>2) + (freq_scaled[23]>>2)))) + 
						 	 ((((freq_scaled[24]>>2) + (freq_scaled[25]>>2))) + (((freq_scaled[26]>>2) + (freq_scaled[27]>>2)))))>>ema_alpha) + ((bars[12]*ema_decay)>>ema_alpha);
				bars[13]<= ((((((freq_scaled[28]>>2) + (freq_scaled[29]>>2))) + (((freq_scaled[30]>>2) + (freq_scaled[31]>>2)))) + 
						 	 ((((freq_scaled[32]>>2) + (freq_scaled[33]>>2))) + (((freq_scaled[34]>>2) + (freq_scaled[35]>>2)))))>>ema_alpha) + ((bars[13]*ema_decay)>>ema_alpha);
				bars[14]<= ((((((freq_scaled[36]>>3) + (freq_scaled[37]>>3))) + (((freq_scaled[38]>>3) + (freq_scaled[39]>>3)))) +
						 	 ((((freq_scaled[40]>>3) + (freq_scaled[41]>>3))) + (((freq_scaled[42]>>3) + (freq_scaled[43]>>3)))) +
						 	 ((((freq_scaled[44]>>3) + (freq_scaled[45]>>3))) + (((freq_scaled[46]>>3) + (freq_scaled[47]>>3)))) +
						 	 ((((freq_scaled[48]>>3) + (freq_scaled[49]>>3))) + (((freq_scaled[50]>>3) + (freq_scaled[51]>>3)))))>>ema_alpha) + ((bars[14]*ema_decay)>>ema_alpha);
				bars[15]<= ((((((freq_scaled[52]>>3) + (freq_scaled[53]>>3))) + (((freq_scaled[54]>>3) + (freq_scaled[55]>>3)))) + 
						 	 ((((freq_scaled[56]>>3) + (freq_scaled[57]>>3))) + (((freq_scaled[58]>>3) + (freq_scaled[59]>>3)))) + 
						 	 ((((freq_scaled[60]>>3) + (freq_scaled[61]>>3))) + (((freq_scaled[62]>>3) + (freq_scaled[63]>>3)))) + 
						 	 ((((freq_scaled[64]>>3) + (freq_scaled[65]>>3))) + (((freq_scaled[66]>>3) + (freq_scaled[67]>>3)))))>>ema_alpha) + ((bars[15]*ema_decay)>>ema_alpha);
			end else if (USED_SAMPLES == 70 && BARS == 32) begin
				bars[0] <= (freq_scaled[0]>>ema_alpha) + 
							((bars[0]*ema_decay)>>ema_alpha);
				bars[1] <= (freq_scaled[1]>>ema_alpha) + 
							((bars[1]*ema_decay)>>ema_alpha);
				bars[2] <= (freq_scaled[2]>>ema_alpha) + 
							((bars[2]*ema_decay)>>ema_alpha);
				bars[3] <= (freq_scaled[3]>>ema_alpha) + 
							((bars[3]*ema_decay)>>ema_alpha);
				bars[4] <= (freq_scaled[4]>>ema_alpha) + 
							((bars[4]*ema_decay)>>ema_alpha);
				bars[5] <= (freq_scaled[5]>>ema_alpha) + 
							((bars[5]*ema_decay)>>ema_alpha);
				bars[6] <= (freq_scaled[6]>>ema_alpha) + 
							((bars[6]*ema_decay)>>ema_alpha);
				bars[7] <= (freq_scaled[7]>>ema_alpha) + 
							((bars[7]*ema_decay)>>ema_alpha);
				bars[8] <= (freq_scaled[8]>>ema_alpha) + 
							((bars[8]*ema_decay)>>ema_alpha);
				bars[9] <= (freq_scaled[9]>>ema_alpha) + 
							((bars[9]*ema_decay)>>ema_alpha);
				bars[10]<= (((freq_scaled[10]>>1) + (freq_scaled[11]>>1))>>ema_alpha) + 
							((bars[10]*ema_decay)>>ema_alpha);
				bars[11]<= (((freq_scaled[12]>>1) + (freq_scaled[13]>>1))>>ema_alpha) + 
							((bars[11]*ema_decay)>>ema_alpha);
				bars[12]<= (((freq_scaled[14]>>1) + (freq_scaled[15]>>1))>>ema_alpha) + 
							((bars[12]*ema_decay)>>ema_alpha);
				bars[13]<= (((freq_scaled[16]>>1) + (freq_scaled[17]>>1))>>ema_alpha) + 
							((bars[13]*ema_decay)>>ema_alpha);
				bars[14]<= (((freq_scaled[18]>>1) + (freq_scaled[19]>>1))>>ema_alpha) + 
							((bars[14]*ema_decay)>>ema_alpha);
				bars[15]<= (((freq_scaled[20]>>1) + (freq_scaled[21]>>1))>>ema_alpha) + 
							((bars[15]*ema_decay)>>ema_alpha);
				bars[16]<= (((freq_scaled[22]>>1) + (freq_scaled[23]>>1))>>ema_alpha) + 
							((bars[16]*ema_decay)>>ema_alpha);
				bars[17]<= (((freq_scaled[24]>>1) + (freq_scaled[25]>>1))>>ema_alpha) + 
							((bars[17]*ema_decay)>>ema_alpha);
				bars[18]<= (((freq_scaled[26]>>1) + (freq_scaled[27]>>1))>>ema_alpha) + 
							((bars[18]*ema_decay)>>ema_alpha);
				bars[19]<= (((freq_scaled[28]>>1) + (freq_scaled[29]>>1))>>ema_alpha) + 
							((bars[19]*ema_decay)>>ema_alpha);
				bars[20]<= (((freq_scaled[30]>>1) + (freq_scaled[31]>>1))>>ema_alpha) + 
							((bars[20]*ema_decay)>>ema_alpha);
				bars[21]<= (((freq_scaled[32]>>1) + (freq_scaled[33]>>1))>>ema_alpha) + 
							((bars[21]*ema_decay)>>ema_alpha);
				bars[22]<= (((freq_scaled[34]>>1) + (freq_scaled[35]>>1))>>ema_alpha) + 
							((bars[22]*ema_decay)>>ema_alpha);
				bars[23]<= (((freq_scaled[36]>>1) + (freq_scaled[37]>>1))>>ema_alpha) + 
							((bars[23]*ema_decay)>>ema_alpha);
				bars[24]<= ((((freq_scaled[38]>>2) + (freq_scaled[39]>>2)) +
						     ((freq_scaled[40]>>2) + (freq_scaled[41]>>2)))>>ema_alpha) + 
							((bars[24]*ema_decay)>>ema_alpha);
				bars[25]<= ((((freq_scaled[42]>>2) + (freq_scaled[43]>>2)) +
						     ((freq_scaled[44]>>2) + (freq_scaled[45]>>2)))>>ema_alpha) + 
							((bars[25]*ema_decay)>>ema_alpha);
				bars[26]<= ((((freq_scaled[46]>>2) + (freq_scaled[47]>>2)) +
						     ((freq_scaled[48]>>2) + (freq_scaled[49]>>2)))>>ema_alpha) + 
							((bars[26]*ema_decay)>>ema_alpha);
				bars[27]<= ((((freq_scaled[50]>>2) + (freq_scaled[51]>>2)) +
						     ((freq_scaled[52]>>2) + (freq_scaled[53]>>2)))>>ema_alpha) + 
							((bars[27]*ema_decay)>>ema_alpha);
				bars[28]<= ((((freq_scaled[54]>>2) + (freq_scaled[55]>>2)) +
						     ((freq_scaled[56]>>2) + (freq_scaled[57]>>2)))>>ema_alpha) + 
							((bars[28]*ema_decay)>>ema_alpha);
				bars[29]<= ((((freq_scaled[58]>>2) + (freq_scaled[59]>>2)) +
						     ((freq_scaled[60]>>2) + (freq_scaled[61]>>2)))>>ema_alpha) + 
							((bars[29]*ema_decay)>>ema_alpha);
				bars[30]<= ((((freq_scaled[62]>>2) + (freq_scaled[63]>>2)) +
						     ((freq_scaled[64]>>2) + (freq_scaled[65]>>2)))>>ema_alpha) + 
							((bars[30]*ema_decay)>>ema_alpha);
				bars[31]<= ((((freq_scaled[66]>>2) + (freq_scaled[67]>>2)) +
						     ((freq_scaled[68]>>2) + (freq_scaled[69]>>2)))>>ema_alpha) + 
							((bars[31]*ema_decay)>>ema_alpha);
			end
			// bars[0] <= 	(freq_scaled[1]>>ema_alpha) + ((bars[0]*ema_decay)>>ema_alpha);
			// bars[1] <= 	(freq_scaled[2]>>ema_alpha) + ((bars[1]*ema_decay)>>ema_alpha);
			// bars[2] <= 	(freq_scaled[3]>>ema_alpha) + ((bars[2]*ema_decay)>>ema_alpha);
			// bars[3] <= 	(freq_scaled[4]>>ema_alpha) + ((bars[3]*ema_decay)>>ema_alpha);
			// bars[4] <= 	(freq_scaled[5]>>ema_alpha) + ((bars[4]*ema_decay)>>ema_alpha);
			// bars[5] <= 	(freq_scaled[6]>>ema_alpha) + ((bars[5]*ema_decay)>>ema_alpha);
			// bars[6] <= 	(freq_scaled[7]>>ema_alpha) + ((bars[6]*ema_decay)>>ema_alpha);
			// bars[7] <= 	(freq_scaled[8]>>ema_alpha) + ((bars[7]*ema_decay)>>ema_alpha);
			// bars[8] <= 	((((freq_scaled[9])  + (freq_scaled[10])))>>ema_alpha) + ((bars[8]*ema_decay)>>ema_alpha);
			// bars[9] <= 	((((freq_scaled[11]) + (freq_scaled[12])))>>ema_alpha) + ((bars[9]*ema_decay)>>ema_alpha);
			// bars[10]<= 	((((freq_scaled[13]>>1) + (freq_scaled[14]>>1))) + (((freq_scaled[15]>>1) + (freq_scaled[16]>>1)))>>ema_alpha) + ((bars[10]*ema_decay)>>ema_alpha);
			// bars[11]<= 	((((freq_scaled[17]>>1) + (freq_scaled[18]>>1))) + (((freq_scaled[19]>>1) + (freq_scaled[20]>>1)))>>ema_alpha) + ((bars[11]*ema_decay)>>ema_alpha);
			// bars[12]<= (((((freq_scaled[21]>>2) + (freq_scaled[22]>>2))) + (((freq_scaled[23]>>2) + (freq_scaled[24]>>2)))) + 
			// 			((((freq_scaled[25]>>2) + (freq_scaled[26]>>2))) + (((freq_scaled[27]>>2) + (freq_scaled[28]>>2))))>>ema_alpha) + ((bars[12]*ema_decay)>>ema_alpha);
			// bars[13]<= (((((freq_scaled[29]>>2) + (freq_scaled[30]>>2))) + (((freq_scaled[31]>>2) + (freq_scaled[32]>>2)))) + 
			// 			((((freq_scaled[33]>>2) + (freq_scaled[34]>>2))) + (((freq_scaled[35]>>2) + (freq_scaled[36]>>2))))>>ema_alpha) + ((bars[13]*ema_decay)>>ema_alpha);
			// bars[14]<= (((((freq_scaled[37]>>3) + (freq_scaled[38]>>3))) + (((freq_scaled[39]>>3) + (freq_scaled[40]>>3)))) +
			// 			((((freq_scaled[41]>>3) + (freq_scaled[42]>>3))) + (((freq_scaled[43]>>3) + (freq_scaled[44]>>3)))) +
			// 			((((freq_scaled[45]>>3) + (freq_scaled[46]>>3))) + (((freq_scaled[47]>>3) + (freq_scaled[48]>>3)))) +
			// 			((((freq_scaled[49]>>3) + (freq_scaled[50]>>3))) + (((freq_scaled[51]>>3) + (freq_scaled[52]>>3))))>>ema_alpha) + ((bars[14]*ema_decay)>>ema_alpha);
			// bars[15]<= (((((freq_scaled[53]>>3) + (freq_scaled[54]>>3))) + (((freq_scaled[55]>>3) + (freq_scaled[56]>>3)))) + 
			// 			((((freq_scaled[57]>>3) + (freq_scaled[58]>>3))) + (((freq_scaled[59]>>3) + (freq_scaled[60]>>3)))) + 
			// 			((((freq_scaled[61]>>3) + (freq_scaled[62]>>3))) + (((freq_scaled[63]>>3) + (freq_scaled[64]>>3)))) + 
			// 			((((freq_scaled[65]>>3) + (freq_scaled[66]>>3))) + (((freq_scaled[67]>>3) + (freq_scaled[68]>>3))))>>ema_alpha) + ((bars[15]*ema_decay)>>ema_alpha);
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
	if (BARS == 16 && x < 16) begin
		color_to_vga <= (y < (bars[x])) ? 8'h00 : color_gradient[x];
	end else if (x < 32) begin
		color_to_vga <= (y < ((bars[x] > 30) ? 0 : 30-bars[x])) ? 8'h00 : color_gradient[x];	
	end
end

endmodule