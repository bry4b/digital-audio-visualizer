module mic_test_led (
    input clk_10MHz,
    input rst,
    output mic_vcc,
    output wire [9:0] leds
);
    wire [11:0] sample;

    /*
        ADC parameters
        board: DE-10 lite
        ADC clock freq: 10.0 MHz
        system clock freq: 50.0 MHz
        no. channels: 1 (CH0)
    */

    adc ADC (.CLOCK(clk_10MHz), .CH0(sample), .RESET(0)); 

    assign leds = sample[11:2];
    assign mic_vcc = 1'b1; 

endmodule
