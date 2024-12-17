module dav(
	input clk_50MHz,
	input clk_adc,
	input rst,
	output [9:0] leds,
	output hsync,
	output vsync,
	output [3:0] red,
	output [3:0] green,
	output [3:0] blue
);

	reg [11:0] time_samples [0:15];
	reg [11:0] freq_samples [0:15];
	reg [11:0] bars [0:15];
	//	reg [11:0] test_samples [0:15];
	logic done;
	logic start = 1;
	
	reg out_clk_60Hz;
	reg slow_clk;
	
	mic_sampler MIC (.clk_10MHz(clk_adc), .rst(rst), .samples(time_samples));
	
	clock_divider #(50000000, 60) VGA_CLOCK (.clk(clk_50MHz), .rst(rst), .out_clk(out_clk_60Hz));
	clock_divider #(50000000, 30) SLOW_CLOCK (.clk(clk_50MHz), .rst(rst), .out_clk(slow_clk));
	
	graphics_controller GRAPHICS (.clk_50MHz(clk_50MHz), .rst(rst), .bin_amplitudes(bars), .hsync(hsync),
											.vsync(vsync), .red(red), .green(green), .blue(blue) );
											
	fft_16 FFT ( .clk(out_clk_60Hz), .rst(rst), .start(start), .done(done), .time_samples(time_samples), .freq_samples(freq_samples) );

	/*
	initial begin
		test_samples[0] = 12'hfff; test_samples[1] = 12'h000; test_samples[2] = 12'h000; test_samples[3] = 12'h000;
		test_samples[4] = 12'h000; test_samples[5] = 12'hfff; test_samples[6] = 12'h000; test_samples[7] = 12'h000;
		test_samples[8] = 12'h000; test_samples[9] = 12'h000; test_samples[10] = 12'hfff; test_samples[11] = 12'h000;
		test_samples[12] = 12'h000; test_samples[13] = 12'hfff; test_samples[14] = 12'h000; test_samples[15] = 12'hfff;
	end	
	*/
	
	assign leds[9] = (rst == 1);
	
	always @(posedge slow_clk) begin
		bars[0] <= time_samples[0];
		bars[1] <= freq_samples[1];
		bars[2] <= freq_samples[2];
		bars[3] <= freq_samples[3];
		bars[4] <= freq_samples[4];
		bars[5] <= freq_samples[5];
		bars[6] <= freq_samples[6];
		bars[7] <= freq_samples[7];
		bars[8] <= freq_samples[8];
		bars[9] <= freq_samples[9];
		bars[10] <= freq_samples[10];
		bars[11] <= freq_samples[11];
		bars[12] <= freq_samples[12];
		bars[13] <= freq_samples[13];
		bars[14] <= freq_samples[14];
		bars[15] <= freq_samples[15];
	end
	
	/*
		Start signal
	*/
	
endmodule