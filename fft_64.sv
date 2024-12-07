module fft_64 #(
    parameter WIDTH=12,
    parameter N=16  // must be power of 4
) (
    input clk,
    input rst,
    input start,
    output done,

    input [WIDTH-1:0] time_samples [0:N-1],
    output [WIDTH-1:0] freq_samples [0:N-1]
);

/*
    N-point decimation-in-time FFT using radix-4 butterfly units. 

    handy resources for FFT theory: 
        https://www.ti.com/lit/an/spra152/spra152.pdf 
        https://www.cmlab.csie.ntu.edu.tw/cml/dsp/training/coding/transform/fft.html
*/

localparam N_BUTTERFLY = (N+3)/4;
localparam N_STAGES = $clog2(N)/2;
localparam FULL_WIDTH = WIDTH/21;

logic [FULL_WIDTH-1:0] a [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] b [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] c [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] d [0:N_BUTTERFLY-1];

// logic [FULL_WIDTH-1:0] out0 [0:N_BUTTERFLY-1];
// logic [FULL_WIDTH-1:0] out1 [0:N_BUTTERFLY-1];
// logic [FULL_WIDTH-1:0] out2 [0:N_BUTTERFLY-1];
// logic [FULL_WIDTH-1:0] out3 [0:N_BUTTERFLY-1];

// logic [FULL_WIDTH-1:0] out0_d [0:N_BUTTERFLY-1];
// logic [FULL_WIDTH-1:0] out1_d [0:N_BUTTERFLY-1];
// logic [FULL_WIDTH-1:0] out2_d [0:N_BUTTERFLY-1];
// logic [FULL_WIDTH-1:0] out3_d [0:N_BUTTERFLY-1];

// outputs 0:3 of butterfly units 0:N_BUTTERFLY-1, each of width FULL_WIDTH. 
logic [FULL_WIDTH-1:0] out   [0:3] [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] out_l [0:3] [0:N_BUTTERFLY-1];   // last stage outputs
logic [FULL_WIDTH-1:0] out_d [0:3] [0:N_BUTTERFLY-1];   // next outputs

logic [FULL_WIDTH-1:0] w1 [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] w2 [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] w3 [0:N_BUTTERFLY-1];

logic [FULL_WIDTH+1:0] w_16 [0:9] = '{
    {{1'b0, (12'd1<<11)},   {1'b0, (12'd0)}},       // W0
    {{1'b0, (12'd1892)},    {1'b1, (12'd784)}},     // W1
    {{1'b0, (12'd1448)},    {1'b1, (12'd1448)}},    // W2
    {{1'b0, (12'd784)},     {1'b1, (12'd1892)}},    // W3
    {{1'b0, (12'd0)},       {1'b1, (12'd1<<11)}},   // W4
    {{1'b1, (12'd784)},     {1'b1, (12'd1892)}},    // W5
    {{1'b1, (12'd1448)},    {1'b1, (12'd1448)}},    // W6
    {{1'b1, (12'd1892)},    {1'b1, (12'd784)}},     // W7
    {{1'b1, (12'd1<<11)},   {1'b0, (12'd0)}},       // W8
    {{1'b1, (12'd1892)},    {1'b0, (12'd784)}}      // W9
};

typedef enum logic [1:0] {SET, STAGE1, STAGE2, DONE} state_t;
state_t state, state_d;

logic [1:0] start_sr, reset_sr;

assign done = (state == DONE);

genvar i;
generate 
    for (i = 0; i < N_BUTTERFLY; i++) begin : gen_butterfly
        butterfly_4 #(.WIDTH(FULL_WIDTH)) DUT (
            .a(a[i]),
            .b(b[i]),
            .c(c[i]),
            .d(d[i]),
            .w1(w1[i]),
            .w2(w2[i]),
            .w3(w3[i]),
            .out0(out_d[0][i]),
            .out1(out_d[1][i]),
            .out2(out_d[2][i]),
            .out3(out_d[3][i])
        );
    end
endgenerate

always_ff @(posedge clk) begin
    start_sr <= {start_sr[0], start};
    reset_sr <= {reset_sr[0], rst};
    state <= state_d;

    // out0 <= out0_d;
    // out1 <= out1_d;
    // out2 <= out2_d;
    // out3 <= out3_d;

    out <= out_d;
    out_l <= out;
end

// assign inputs to butterfly units
always_comb begin
    case (state) 
        SET: begin
            for (int i = 0; i < N_BUTTERFLY; i++) begin
                a[i] = 1'b0;
                b[i] = 1'b0;
                c[i] = 1'b0;
                d[i] = 1'b0;
                w1[i]= 1'b0;
                w2[i]= 1'b0;
                w3[i]= 1'b0;
            end
        end

        STAGE1: begin
            for (int i = 0; i < N_BUTTERFLY; i++) begin
                a[i] = time_samples[i+N_STAGES*0];
                b[i] = time_samples[i+N_STAGES*1];
                c[i] = time_samples[i+N_STAGES*2];
                d[i] = time_samples[i+N_STAGES*3];
                w1[i]= w_16[0];
                w2[i]= w_16[0];
                w3[i]= w_16[0];
            end
        end

        STAGE2: begin
            for (int i = 0; i < N_BUTTERFLY; i++) begin
                a[i] = out[i][0];
                b[i] = out[i][1];
                c[i] = out[i][2];
                d[i] = out[i][3];
                w1[i]= w_16[i*1];
                w2[i]= w_16[i*2];
                w3[i]= w_16[i*3];
            end
        end

        DONE: begin
            for (int i = 0; i < N_BUTTERFLY; i++) begin
                a[i] = out_l[i][0];
                b[i] = out_l[i][1];
                c[i] = out_l[i][2];
                d[i] = out_l[i][3];
                w1[i]= w_16[i*1];
                w2[i]= w_16[i*2];
                w3[i]= w_16[i*3];
            end
        end

    endcase
end

// output freq_samples
always_comb begin
    if (state == DONE) begin
        for (int i = 0; i < N_BUTTERFLY; i++) begin
            freq_samples[i+N_STAGES*0] = out[0][i][FULL_WIDTH-1:WIDTH];
            freq_samples[i+N_STAGES*1] = out[1][i][FULL_WIDTH-1:WIDTH];
            freq_samples[i+N_STAGES*2] = out[2][i][FULL_WIDTH-1:WIDTH];
            freq_samples[i+N_STAGES*3] = out[3][i][FULL_WIDTH-1:WIDTH];
        end
    end else begin
        for (int i = 0; i < N; i++) begin
            freq_samples[i] = 1'b0;
        end
    end
end

endmodule