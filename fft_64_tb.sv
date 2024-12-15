`timescale 1ns/1ns

module fft_64_tb (
    output logic clk
);

localparam WIDTH = 12;

logic rst, start, done;

logic [WIDTH-1:0] time_samples [0:63] = '{
    -163, 35, 196, -128, 55, 193, 3, -67, 135, -56, -71, -129, 37, 190, 81, -22, 76, 54, 157, 195, 52, -44, 198, -150, -132, 15, 41, 152, -114, -59, 193, -193, 119, 117, -178, 113, -199, 184, 116, 9, 64, 16, -59, -85, -79, -170, -129, 187, -151, 113, -197, 80, -157, -124, -174, 108, 136, -91, 171, 97, -185, -136, -4, -175
};

logic [WIDTH-1:0] freq_samples [0:63];

fft_64 DUT (
    .clk(clk),
    .rst(rst),
    .start(start),
    .done(done),
    .time_samples(time_samples),
    .freq_samples(freq_samples)
);

initial begin
    clk <= 0;
    rst <= 1;
    start <= 0;

    #10 rst <= 0;
    start <= 1;

    #60 $stop;
end

always begin
    #5 clk = ~clk;
end

endmodule