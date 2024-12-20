module mic_sampler # (
    parameter N = 256,
    parameter SAMPLE_RATE = 5000
) (
    input clk_10MHz,
    input rst,
    output reg [11:0] samples [0:N-1]
);
    reg [11:0] sample;
    reg mic_sampling_clk;
	
    clock_divider #(10000000, SAMPLE_RATE) SAMPLING_CLOCK (.clk(clk_10MHz), .rst(rst), .out_clk(mic_sampling_clk));

    /*
        ADC parameters
        board: DE-10 lite
        ADC clock freq: 10.0 MHz
        system clock freq: 50.0 MHz
        no. channels: 1 (CH0)
    */

    adc ADC (.CLOCK(clk_10MHz), .CH0(sample), .RESET(0)); 

    always @(posedge mic_sampling_clk) begin
        samples[N-1] <= sample;
        for (int i = 0; i < N-1; i++) begin
            samples[i] <= samples[i+1];
        end
    end

endmodule
