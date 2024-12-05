module fft #(
    parameter WIDTH=12,
    parameter N=256
) (
    input clk,
    input rst,
    input start,

    input [WIDTH-1:0] time_samples [0:N-1],
    output [WIDTH-1:0] freq_samples [0:N-1]
);

localparam N_BUTTERFLY = N+3 >> 2;
localparam FULL_WIDTH = WIDTH << 1;

logic [FULL_WIDTH-1:0] a_in [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] b_in [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] c_in [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] d_in [0:N_BUTTERFLY-1];

logic [FULL_WIDTH-1:0] out0 [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] out1 [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] out2 [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] out3 [0:N_BUTTERFLY-1];

genvar i;
generate 
    for (i = 0; i < N_BUTTERFLY; i++) begin
        butterfly_4 #(.WIDTH(FULL_WIDTH)) DUT (
            .a(a_in[i]),
            .b(b_in[i]),
            .c(c_in[i]),
            .d(d_in[i]),
            .w0(),
            .w1(),
            .w2(),
            .out0(out0[i]),
            .out1(out1[i]),
            .out2(out2[i]),
            .out3(out3[i])
        );
    end
endgenerate

endmodule