`timescale 1ns/1ns

module fft_256_tb (
    output logic clk
);

localparam WIDTH = 12;  // time-domain sample width
localparam N = 256;     // FFT points

logic [WIDTH-1:0] time_samples [0:N-1] = '{
-163, 35, 196, -128, 55, 193, 3, -67, 135, -56, -71, -129, 37, 190, 81, -22, 76, 54, 157, 195, 52, -44, 198, -150, -132, 15, 41, 152, -114, -59, 193, -193, 119, 117, -178, 113, -199, 184, 116, 9, 64, 16, -59, -85, -79, -170, -129, 187, -151, 113, -197, 80, -157, -124, -174, 108, 136, -91, 171, 97, -185, -136, -4, -175, 167, 26, 191, 82, -47, -96, -178, 65, -5, -74, 79, 181, 156, -45, 113, -117, -34, -64, 88, 66, 79, -57, 39, -113, 81, 43, 148, -126, -10, 102, 16, -49, -17, 121, 169, 133, 59, 184, 53, 62, -148, -198, -124, -51, 3, 63, -123, 0, -125, 132, -157, -180, -170, -164, 159, 63, 101, -143, 40, 10, -104, 69, -190, 79, 180, 137, 191, 177, -48, 2, -52, -60, -7, -106, -140, -48, 138, 171, 153, -70, 20, -97, 154, 66, -18, 152, 138, -2, -6, 127, -24, -146, -185, 189, -30, -180, -82, 78, 197, -86, -103, -19, 140, -190, -104, -17, 117, -144, 17, 31, -104, -175, 198, -59, 12, -84, 99, -66, 5, -16, 199, -176, -63, -1, 109, 125, 157, 48, -179, 96, -123, 19, -23, 169, 103, -155, 143, -56, 34, -155, 172, 122, 102, 184, -137, 131, -165, -167, -70, -117, -152, 110, 88, 53, -44, -145, 10, 87, -172, 22, 130, -64, -91, -101, -168, -192, -116, -150, -121, -31, 120, -92, 11, -176, -87, 76, -156, 71, -42, 198, 75, 51, -46, 35, -114, 191, 27, -147, 166, 43, 90, -100
};

logic rst, start;
logic done, done_old;

logic [WIDTH:0] freq_real [0:N-1];
logic [WIDTH:0] freq_imag [0:N-1];
logic [WIDTH+1:0] freq_mag [0:N-1];

logic [WIDTH:0] freq_real_old [0:N-1];
logic [WIDTH:0] freq_imag_old [0:N-1];
logic [WIDTH+1:0] freq_mag_old [0:N-1];

fft_256 #(.WIDTH(WIDTH)) DUT (
    .clk(clk),
    .rst(rst),
    .start(start),
    .done(done),
    .time_samples(time_samples),
    .freq_real(freq_real),
    .freq_imag(freq_imag)
);

mag_est #(.WIDTH(WIDTH)) EST (
    .real_in(freq_real),
    .imag_in(freq_imag),
    .magnitude(freq_mag)
);

fft_256_old #(.WIDTH(WIDTH)) OLD (
    .clk(clk),
    .rst(rst),
    .start(start),
    .done(done_old),
    .time_samples(time_samples),
    .freq_real(freq_real_old),
    .freq_imag(freq_imag_old)
);

mag_est #(.WIDTH(WIDTH)) EST_OLD (
    .real_in(freq_real_old),
    .imag_in(freq_imag_old),
    .magnitude(freq_mag_old)
);

initial begin
    clk <= 0;
    rst <= 1;
    start <= 0;

    #10 rst <= 0;
    start <= 1;
	#10 start <= 0;

    #300 rst <= 1;
	#10 rst <= 0;
	#10 start <= 1;
	#10 start <= 0;
	
	#80 $stop;
end

always begin
    #5 clk = ~clk;
end

endmodule