module dav_top(
	input clk_50MHz,
	input clk_adc,
	input rst,
	input [9:0] switches,

	output logic [9:0] leds,
	output logic hsync,
	output logic vsync,
	output logic [3:0] red,
	output logic [3:0] green,
	output logic [3:0] blue
);

localparam N = 256;
localparam N_STAGES = $clog2(N)/2;
localparam MAX_FREQ = 20000;

logic [11:0] time_samples [0:N-1];
logic [13:0] freq_samples [0:N-1];
logic [12:0] freq_real [0:N-1];
logic [12:0] freq_imag [0:N-1];
logic [13:0] bars [0:N-1];

logic clk_25MHz;
logic fft_clk;

/*
    inclk0: 50 MHz
    c0: 25.2 MHz (25 MHz should also work)
*/
pll2 VGA_CLOCK ( .inclk0(clk_50MHz), .c0(clk_25MHz) );

clock_divider #(50000000, 60*(40)) FFT_CLOCK (.clk(clk_50MHz), .rst(~rst), .out_clk(fft_clk));

mic_sampler #(.N(N), .SAMPLE_RATE(MAX_FREQ)) MIC (
	.clk_10MHz(clk_adc), 
	.rst(~rst), 
	.samples(time_samples)
);

logic fft_rst;
logic start; 
logic done;


fft_256 FFT (
	.clk(fft_clk),
	.rst(fft_rst),
	.start(start),
	.done(done),
	.time_samples(time_samples),
	.freq_mag(freq_samples)
);

graphics_controller #(.N(N)) GFX (
	.clk_25MHz(clk_25MHz), 
	.rst(~rst), 
	.fft_done(done),
	.switches(switches),
	.freq_samples(freq_samples), 
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

	
/*
	Start signal
*/

// detect rising edge of vsync in vga clock domain
logic [1:0] vsync_sr = 2'b00; 
logic vsync_toggle = 1'b0;
always @(posedge clk_50MHz) begin
	vsync_sr <= {vsync_sr[0], vsync};
	if (vsync_sr == 2'b01) begin
		vsync_toggle <= ~vsync_toggle;
	end
end

// start fft on rising edge of vsync in fft clock domain
logic [1:0] vsync_toggle_sr = 2'b00;	
always @(posedge fft_clk) begin
	vsync_toggle_sr <= {vsync_toggle_sr[0], vsync_toggle};
end

assign start = (vsync_toggle_sr[0] ^ vsync_toggle_sr[1]);

// debug leds
assign leds[9] = start;
assign leds[8] = done;
assign leds[7:0] = freq_samples[switches[9:4]][13:6];
// assign leds[0] = ((freq_samples[0] - 512) >> 5) == 0;

endmodule