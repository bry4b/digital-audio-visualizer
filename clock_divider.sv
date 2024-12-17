module clock_divider #( parameter MAX_SPEED = 50000000, parameter SPEED = 25000000 ) (
	input clk,					//	input clk signal
	input rst,
	output reg out_clk		//	output clk signal
);

reg [25:0] count = 0;
reg [25:0] count_d;
reg clk_div = 0;
assign out_clk = clk_div;

reg clk_div_d;

localparam [25:0] DIVISOR = MAX_SPEED / SPEED;

always @(posedge clk) begin
	count <= count_d;
	clk_div <= clk_div_d;
end

always_comb begin
	if (rst || count == DIVISOR - 1) begin
		count_d = 0;
	end else begin
		count_d = count + 1;
	end
	if (rst) begin
		clk_div_d = 0;
	end else if (count < (DIVISOR / 2)) begin
		clk_div_d = 1;
	end else begin
		clk_div_d = 0;
	end
end

endmodule