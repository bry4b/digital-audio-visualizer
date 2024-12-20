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
localparam N_STAGES = 4*8+2;		// 4 stages each with 8 substages, plus 2 stages for set and done
localparam MAX_FREQ = 20000;
localparam WIDTH = 19;				// MAKE SURE THIS MATCHES DESIRED COMPUTATION WIDTH! UPDATE TWIDDLE FACTORS IF CHANGED!

logic [11:0] time_samples [0:N-1];
logic [WIDTH:0] freq_samples [0:N-1];

logic clk_25MHz;
logic fft_clk;

/*
    inclk0: 50 MHz
    c0: 25.2 MHz (25 MHz should also work)
*/
pll2 VGA_CLOCK ( .inclk0(clk_50MHz), .c0(clk_25MHz) );

mic_sampler #(.N(N), .SAMPLE_RATE(MAX_FREQ)) MIC (
	.clk_10MHz(clk_adc), 
	.rst(~rst), 
	.samples(time_samples)
);

logic fft_rst;
logic start; 
logic done;

generate
if (N == 16) begin
	clock_divider #(50000000, 60*4) FFT_CLOCK (.clk(clk_50MHz), .rst(~rst), .out_clk(fft_clk));

	fft_16 #(.WIDTH(WIDTH)) FFT (
		.clk(fft_clk), 
		.rst(fft_rst), 
		.start(start), 
		.done(done), 
		.time_samples(time_samples), 
		.freq_mag(freq_samples)
	);
end else if (N == 256) begin
	clock_divider #(50000000, 60*40) FFT_CLOCK (.clk(clk_50MHz), .rst(~rst), .out_clk(fft_clk));

	fft_256 #(.WIDTH(WIDTH)) FFT (
		.clk(fft_clk),
		.rst(fft_rst),
		.start(start),
		.done(done),
		.time_samples(time_samples),
		.freq_mag(freq_samples)	
	);
end
endgenerate 

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
	Start signal
*/

// detect rising edge of vsync in vga clock domain
logic [1:0] vsync_sr = 2'b00; 
logic vsync_toggle = 1'b0;
always @(posedge clk_25MHz) begin
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
assign leds[9] = vsync_toggle;
assign leds[8] = done;
assign leds[7:0] = freq_samples[switches[9:4]][13:6];
// assign leds[0] = ((freq_samples[0] - 512) >> 5) == 0;

endmodule