module vga(
	input vgaclk,
	// 8-bit color allocates 3 bits for red, 3 for green, 2 for blue
	input [2:0] input_red,
	input [2:0] input_green,
	input [1:0] input_blue,
	input rst,
	output [9:0] hc_out,
	output [9:0] vc_out,
	output hsync,
	output vsync,
	output reg [3:0] red,
	output reg [3:0] green,
	output reg [3:0] blue
);
	
	/* TODO(1): Video protocol constants
    * You can find these described in the VGA specification for 640x480
	 */
	localparam HPIXELS = 'd640;    // number of visible pixels per horizontal line
	localparam HFP = 'd16; 	      // length (in pixels) of horizontal front porch
	localparam HSPULSE = 'd96; 	// length (in pixels) of hsync pulse
	localparam HBP = 'd48; 	      // length (in pixels) of horizontal back porch
	
	localparam VPIXELS = 'd480;    // number of visible horizontal lines per frame
	localparam VFP = 'd10; 	      // length (in pixels) of vertical front porch
	localparam VSPULSE = 'd2;    // length (in pixels) of vsync pulse
	localparam VBP = 'd33; 		   // length (in pixels) of vertical back porch
	
	/* no need to mess with this -- this is a basic sanity check that will
	 * cause the compiler to yell at you if the values above don't add up
	 */
	initial begin
		if (HPIXELS + HFP + HSPULSE + HBP != 800 || VPIXELS + VFP + VSPULSE + VBP != 525) begin
			$error("Expected horizontal pixels to add up to 800 and vertical pixels to add up to 525");
		end
	end
	
	/* these registers are for storing the horizontal & vertical counters
	 * we're outputting the counter values from this module so that 
	 *     other modules can stay in sync with the VGA
	 * (it's a surprise tool that will help us later!)
	 */
	reg [9:0] hc;
	reg [9:0] vc;
	
	initial begin
		hc = 1'd0;
		vc = 1'd0;
	end
	
	assign hc_out = hc;
	assign vc_out = vc;
	
   // in the sequential block, we update hc and vc based on their current values
	always_ff @(posedge vgaclk) begin
		/* TODO(2): update the counters, paying careful attention to
		 *       a) the reset condition, and
		 *       b) the conditions that cause hc and vc to go back to 0
		 */
		
		//	Update hc, vc
		if (rst == 'd1) begin
			vc <= 'd0;
			hc <= 'd0;
		end else begin
			if (hc == HPIXELS + HFP + HSPULSE + HBP - 1'd1) begin
				vc <= (vc == VPIXELS + VFP + VSPULSE + VBP - 1'd1) ? 1'd0 : vc + 1'd1;
				hc <= 1'd0;
			end else begin
				hc <= hc + 1'd1;
			end
		end
		
	end
	
	/* TODO(3): when should hsync and vsync go low?
	 */
	assign hsync = !(hc >= HPIXELS + HFP  && hc < HPIXELS + HFP + HSPULSE);
	assign vsync = !(vc >= VPIXELS + VFP  && vc < VPIXELS + VFP + VSPULSE);
	
   // in the combinational block, we set red, green, blue outputs
	always_comb begin
		/* TODO(4): check if we're within the active video range;
		 *       if we are, drive the RGB outputs with the input color values
		 *       if not, we're in the blanking interval, so set them all to 0
		 * NOTE: our inputs are fewer bits than the outputs, so left-shift accordingly!
		 */
		red = (hc < HPIXELS && vc < VPIXELS && rst == 'd0) ? input_red << 1'd1 : 1'd0;
		green = (hc < HPIXELS && vc < VPIXELS && rst == 'd0) ? input_green << 1'd1 : 1'd0;
		blue = (hc < HPIXELS && vc < VPIXELS && rst == 'd0)  ? input_blue << 2'd2 : 1'd0;
	end

endmodule
