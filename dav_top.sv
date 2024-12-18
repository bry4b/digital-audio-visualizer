module dav_top(
	input clk_50MHz,
	input clk_adc,
	input rst,

	output logic [9:0] leds,
	output logic hsync,
	output logic vsync,
	output logic [3:0] red,
	output logic [3:0] green,
	output logic [3:0] blue
);

	logic [11:0] time_samples [0:15];
	logic [13:0] freq_samples [0:15];
	logic [12:0] freq_real [0:15];
	logic [12:0] freq_imag [0:15];
	logic [13:0] bars [0:15];

	logic [1:0] counter = 0;
	
	logic out_clk_60Hz;
	logic fft_clk;
		
	clock_divider #(50000000, 60) VGA_CLOCK (.clk(clk_50MHz), .rst(~rst), .out_clk(out_clk_60Hz));
	clock_divider #(50000000, 240) FFT_CLOCK (.clk(clk_50MHz), .rst(~rst), .out_clk(fft_clk));
	
	mic_sampler MIC (
		.clk_10MHz(clk_adc), 
		.rst(~rst), 
		.samples(time_samples)
	);
							
	fft_16 FFT (
		.clk(fft_clk), 
		.rst(fft_rst), 
		.start(start), 
		.done(done), 
		.time_samples(time_samples), 
		.freq_real(freq_real), 
		.freq_imag(freq_imag) 
	);
	
	mag_est #(.N(16)) MAG ( 
		.real_in(freq_real), 
		.imag_in(freq_imag), 
		.magnitude(freq_samples)
	);

	graphics_controller GFX (
		.clk_50MHz(clk_50MHz), 
		.rst(~rst), 
		.bin_amplitudes(bars), 
		.hsync(hsync), 
		.vsync(vsync), 
		.red(red), 
		.green(green), 
		.blue(blue) 
	);
				

	/*
	initial begin
		test_samples[0] = 12'hfff; test_samples[1] = 12'h000; test_samples[2] = 12'h000; test_samples[3] = 12'h000;
		test_samples[4] = 12'h000; test_samples[5] = 12'hfff; test_samples[6] = 12'h000; test_samples[7] = 12'h000;
		test_samples[8] = 12'h000; test_samples[9] = 12'h000; test_samples[10] = 12'hfff; test_samples[11] = 12'h000;
		test_samples[12] = 12'h000; test_samples[13] = 12'hfff; test_samples[14] = 12'h000; test_samples[15] = 12'hfff;
	end	
	*/
	
	// update bars on rising edge of done signal from fft
	logic done;
	logic [1:0] done_sr; 

	always @(posedge clk_50MHz) begin
		done_sr <= {done_sr[0], done};
		if (done_sr == 2'b01) begin
			for (int i = 0; i < 15; i = i + 1) begin
				bars[i] <= freq_samples[i];
			end
		end
	end
	
	/*
		Start signal
	*/
	logic start; 

	// // reset fft on rising edge of vsync signal, start fft on falling edge 
	// logic [1:0] vsync_sr = 2'b00; 
	// logic fft_rst;
	// // assign start = (vsync_sr == 2'b10);
	// // assign fft_rst = (vsync_sr == 2'b01);

	// logic vsync_toggle = 1'b0; 

	// always @(posedge clk_50MHz) begin
	// 	if (vsync_sr != 2'b00) begin
	// 		vsync_toggle <= 1'b0;
	// 	end else if (vsync) begin
	// 		vsync_toggle <= 1'b1;
	// 	end
	// end
	
	always @(posedge fft_clk) begin
		// vsync_sr <= {vsync_sr[0], vsync_toggle};

		counter <= counter + 1'b1;
		start <= counter == 2'b00;
	end
	
	// debug leds
	assign leds[9] = start;
	assign leds[8] = done;
	assign leds[7:0] = freq_samples[0][13:6];
	// assign leds[0] = ((freq_samples[0] - 512) >> 5) == 0;
endmodule