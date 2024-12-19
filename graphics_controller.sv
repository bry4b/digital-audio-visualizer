/*
	Convert to histogram - will need to adjust later for 256 bins
	Also need to fix screen tearing issue
*/
module graphics_controller # ( 
	parameter WIDTH = 12,
	parameter N = 256, 
	parameter BARS = 16
) (
	input clk_50MHz,	//	50 MHz clock
	input rst,
	input fft_done,
	input [WIDTH+1:0] freq_samples [0:N-1],
	output logic hsync,
	output logic vsync,
	output logic [3:0] red,
	output logic [3:0] green,
	output logic [3:0] blue
);

logic clk_25MHz;

logic [9:0] hc_out;
logic [9:0] vc_out;

logic [5:0] x;
logic [5:0] y;
assign x = hc_out / 40;	//	16 pixels wide
assign y = vc_out >> 4;	//	30 pixels tall

logic [7:0] color_to_vga;
logic rw = 0;

logic [WIDTH-6:0] freq_scaled [0:N-1]; 
logic [6:0] bars [0:BARS-1];

logic [6:0] bin_div_256_16 [0:16] = '{
	7'd0, 7'd1, 7'd2, 7'd3, 7'd4, 7'd5, 7'd6, 7'd7, 7'd10, 7'd14, 7'd19, 7'd27, 7'd37, 7'd50, 7'd68, 7'd94, 7'd127 
};

genvar i;
generate 
	for (i = 0; i < N; i++) begin : scale_freq
		assign freq_scaled[i] = freq_samples[i] >> 3'd7;
	end
endgenerate

logic [11:0] bars_7;
logic [11:0] bars_8;
logic [11:0] bars_9;
logic [11:0] bars_10;
logic [11:0] bars_11;
logic [11:0] bars_12;
logic [11:0] bars_13;
logic [11:0] bars_14;
logic [11:0] bars_15;

always_comb begin
	bars_7  = 1'b0;
	bars_8  = 1'b0;
	bars_9  = 1'b0;
	bars_10 = 1'b0;
	bars_11 = 1'b0;
	bars_12 = 1'b0;
	bars_13 = 1'b0;
	bars_14 = 1'b0;
	bars_15 = 1'b0;

	for (int i = 8; i < 8+4; i++) begin
		bars_7 = bars_7 + freq_scaled[i];
	end 
	for (int i = 12; i < 12+4; i++) begin
		bars_8 = bars_8 + freq_scaled[i];
	end
	for (int i = 16; i < 16+8; i++) begin
		bars_9 = bars_9 + freq_scaled[i];
	end 
	for (int i = 24; i < 24+8; i++) begin
		bars_10 = bars_10 + freq_scaled[i];
	end
	for (int i = 32; i < 32+12; i++) begin
		bars_11 = bars_11 + freq_scaled[i];
	end
	for (int i = 44; i < 44+12; i++) begin
		bars_12 = bars_12 + freq_scaled[i];
	end
	for (int i = 56; i < 56+16; i++) begin
		bars_13 = bars_13 + freq_scaled[i];
	end
	for (int i = 72; i < 72+24; i++) begin
		bars_14 = bars_14 + freq_scaled[i];
	end 
	for (int i = 96; i < 128; i++) begin
		bars_15 = bars_15 + freq_scaled[i];
	end
end


// update bars on rising edge of vsync 
logic [1:0] vsync_sr = 2'b00; 
always @(posedge clk_50MHz) begin
	vsync_sr <= {vsync_sr[0], vsync};
	if (vsync_sr == 2'b01) begin
		if (N == 16) begin
			for (int i = 0; i < N; i = i + 1) begin
				bars[i] <= freq_scaled;
			end
		end else if (N == 256) begin
			bars[0] <= freq_scaled[0];
			bars[1] <= freq_scaled[1];
			bars[2] <= freq_scaled[2];
			bars[3] <= freq_scaled[3];
			bars[4] <= freq_scaled[4];
			bars[5] <= (freq_scaled[5] + freq_scaled[6]) >> 7'd1;
			bars[6] <= (freq_scaled[7] + freq_scaled[8]) >> 7'd1;
			bars[7] <= bars_7 >> 7'd2;
			bars[8] <= bars_8 >> 7'd2;
			bars[9] <= bars_9 >> 7'd3;
			bars[10]<= bars_10 >> 7'd3;
			bars[11]<= bars_11 / 7'd12;
			bars[12]<= bars_12 / 7'd12;
			bars[13]<= bars_13 >> 7'd4;
			bars[14]<= bars_14 / 7'd24;
			bars[15]<= bars_15 >> 7'd5;
		end
	end
end

//	Scale 12-bit values based on max to somewhere between 0 and 30 to fit within range of y-coord 
// genvar i;
// generate
// 	for (i = 0; i < 16; i++) begin : threshold
// 		assign bars[i] = (bin_amplitudes[i] >> 7);		//	scaling: sample >> 8. Works for time sample - adjust for freq samples
// 	end
// endgenerate

/*
    inclk0: 50 MHz
    c0: 25.2 MHz (25 MHz should also work)
*/
pll2 VGA_CLOCK ( .inclk0(clk_50MHz), .c0(clk_25MHz) );
	
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
	if (x < 16) begin										//black		//blue
		color_to_vga <= (y < 30 - bars[x]) ? 8'h00 : color_gradient[x];
	end
end

endmodule