/*
TOP module for 256-pt digital audio visualizer sampling at 20 kHz. first ~69~ 99 frequencies are placed in 16 bins for display on VGA monitor. exponential averaging is used to smooth out display bars.

MAX4466 adjustable gain microphone amplifier (https://www.adafruit.com/product/1063)
	OUT -> ADC0 (leftmost header pin of JP8)
	GND -> GND
	VCC -> 3V3 (CHECK VOLTAGE LEVELS BEFORE CONNECTING) - this is used because it is a less noisy source

switches [9:6] control frequency scaling for display. 0x0 = no scaling, 0x1 = divide by 2, 0x2 = divide by 4, 0x3 = divide by 8, etc. 
	tested with these switches set to 4'b1000. 

switches [1:0] control the exponential averaging factor. 0x0 = no averaging, 0x1 = 1/2, 0x2 = 1/4, 0x3 = 1/8, etc. 
	tested with these switches set to 2'b01. 

*/
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
localparam N_STAGES = 6*16;			// 4 computation stages each with 16 substages, plus 2 stages for set and done
localparam MAX_FREQ = 4000;
localparam WIDTH = 18;				// MAKE SURE THIS MATCHES DESIRED COMPUTATION WIDTH! UPDATE TWIDDLE FACTORS IF CHANGED!
localparam USED_SAMPLES = 70;		// 69 samples are placed in 32 bins
//localparam USED_SAMPLES = 66;
localparam GFX_WIDTH = 6;			// only top 6 bits passed into graphics for frequency scaling

logic [11:0] time_samples [0:N-1];
logic [WIDTH:0] freq_samples [0:USED_SAMPLES-1];
logic [GFX_WIDTH-1:0] freq_scaled [0:USED_SAMPLES-1];

logic clk_25MHz;
logic fft_clk;

/*
    inclk0: 50 MHz
    c0: 25.2 MHz (25 MHz should also work)
*/
pll2 VGA_CLOCK ( .inclk0(clk_50MHz), .c0(clk_25MHz) );

mic_sampler #(.N(N), .SAMPLE_RATE(MAX_FREQ*2)) MIC (
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
	clock_divider #(50000000, 60*96) FFT_CLOCK (.clk(clk_50MHz), .rst(~rst), .out_clk(fft_clk));

	fft_256 #(.WIDTH(WIDTH), .USED_SAMPLES(USED_SAMPLES)) FFT (
		.clk(fft_clk),
		.rst(fft_rst),
		.start(start),
		.done(done),
		.time_samples(time_samples),
		.freq_mag(freq_samples)	
	);
end
endgenerate 

// scale frequencies before passing into graphics controller
genvar i;
generate 
	for (i = 0; i < USED_SAMPLES; i++) begin : scale_freq
		assign freq_scaled[i] = freq_samples[i] >> switches[9:6];
	end
endgenerate

graphics_controller #(.N(N), .USED_SAMPLES(USED_SAMPLES)) GFX (
	.clk_25MHz(clk_25MHz), 
	.rst(~rst), 
	.fft_done(done),
	.switches(switches),
	.freq_scaled(freq_scaled), 
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