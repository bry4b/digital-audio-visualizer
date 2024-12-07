`timescale 1ns/1ns

module fft_16_tb (
    output logic clk
);

localparam WIDTH = 12;

logic rst, start, done;

logic [WIDTH-1:0] time_samples [0:15] = '{
    -163, 35, 196, -128, 55, 193, 3, -67, 135, -56, -71, -129, 37, 190, 81, -22
};

logic [WIDTH-1:0] freq_samples [0:15];

fft_16 DUT (
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

    #50 $stop;
end

always begin
    #5 clk = ~clk;
end

endmodule