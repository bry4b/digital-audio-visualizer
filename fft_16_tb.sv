`timescale 1ns/1ns

module fft_16_tb (
    output logic clk
);

localparam WIDTH = 18;
localparam N = 16;

logic rst, start, done;

logic [WIDTH-1:0] time_samples [0:15] = '{
    1061, 235, 3980, 1096, 3839, 905, 2763, 3717, 2895, 960, 144, 129, 4044, 3655, 2797, 2556
};

logic [WIDTH:0] freq_mag [0:N-1];

fft_16 #(.WIDTH(WIDTH)) DUT (
    .clk(clk),
    .rst(rst),
    .start(start),
    .done(done),
    .time_samples(time_samples),
    .freq_mag(freq_mag)
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