module mic_sampler(
    input clk_10MHz,
    input rst,
    output reg [11:0] samples [0:15]
);
    reg [11:0] sample;
    reg mic_sampling_clk;
	 
    clock_divider #(10000000, 5000) SAMPLING_CLOCK (.clk(clk_10MHz), .rst(rst), .out_clk(mic_sampling_clk));

    /*
        ADC parameters
        board: DE-10 lite
        ADC clock freq: 10.0 MHz
        system clock freq: 50.0 MHz
        no. channels: 1 (CH0)
    */

    adc ADC (.CLOCK(clk_10MHz), .CH0(sample), .RESET(0)); 

    always @(posedge mic_sampling_clk) begin
        samples[15] <= sample;
        samples[14] <= samples[15];
        samples[13] <= samples[14];
        samples[12] <= samples[13];
        samples[11] <= samples[12];
        samples[10] <= samples[11];
        samples[9] <= samples[10];
        samples[8] <= samples[9];
        samples[7] <= samples[8];
        samples[6] <= samples[7];
        samples[5] <= samples[6];
        samples[4] <= samples[5];
        samples[3] <= samples[4];
        samples[2] <= samples[3];
        samples[1] <= samples[2];
        samples[0] <= samples[1];
    end

endmodule
