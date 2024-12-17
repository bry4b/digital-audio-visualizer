/*
	Convert to histogram - will need to adjust later for 256 bins
	Also need to fix screen tearing issue
*/
module graphics_controller (
	input clk_50MHz,	//	50 MHz clock
	input rst,
	input [11:0] bin_amplitudes [0:15],		//	16 12-bit values for bin amplitudes
	output hsync,
	output vsync,
	output [3:0] red,
	output [3:0] green,
	output [3:0] blue
);

reg clk_25MHz;

reg [9:0] hc_out;
reg [9:0] vc_out;

reg [5:0] x;
reg [5:0] y;
assign x = hc_out / 40;	//	16 pixels wide
assign y = vc_out >> 4;	//	30 pixels tall

reg [7:0] color_to_vga;
reg rw = 0;

reg [5:0] thresholds [0:15];

//	Scale 12-bit values based on max to somewhere between 0 and 30 to fit within range of y-coord 
genvar i;
generate
	for (i = 0; i < 16; i++) begin : threshold
		assign thresholds[i] = (bin_amplitudes[i] >> 8);		//	scaling: sample >> 8. Works for time sample - adjust for freq samples
	end
endgenerate

/*
    inclk0: 50 MHz
    c0: 25.2 MHz (25 MHz should also work)
*/
pll2 VGA_CLOCK ( .inclk0(clk_50MHz), .c0(clk_25MHz) );
	
vga VGA ( .vgaclk(clk_25MHz), .input_red(color_to_vga[7:5]), .input_green(color_to_vga[4:2]), .input_blue(color_to_vga[1:0]),
			 .rst(rst), .hc_out(hc_out), .vc_out(vc_out), .hsync(hsync), .vsync(vsync),
			 .red(red), .green(green), .blue(blue) );

always @(posedge clk_25MHz) begin
	if (x < 16) begin										//black		//blue
		color_to_vga <= (y < 30 - thresholds[x]) ? 8'h00 : 8'h03;
	end
end

endmodule