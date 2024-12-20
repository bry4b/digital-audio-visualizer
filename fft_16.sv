module fft_16 #(
    parameter WIDTH = 18,
    parameter N = 16  // must be power of 4
) (
    input clk,
    input rst,
    input start,
    output done,

    input [WIDTH-1:0] time_samples [0:N-1],
    output logic [WIDTH:0] freq_mag [0:N-1]
);

/*
    N-point decimation-in-time FFT using radix-4 butterfly units. 
    TODO: look into increasing width for more accuracy, especially with smaller twiddle factors

    handy resources for 4-radix FFT implementations: 
        https://www.ti.com/lit/an/spra152/spra152.pdf 
        https://www.cmlab.csie.ntu.edu.tw/cml/dsp/training/coding/transform/fft.html
        https://thescipub.com/abstract/ajassp.2007.570.575 
        https://www.worldscientific.com/doi/abs/10.1142/S021812661240018X 
*/

localparam N_BUTTERFLY = (N+3)/4;
localparam N_LOG2 = $clog2(N);
localparam N_STAGES = N_LOG2/2;
localparam FULL_WIDTH = WIDTH*2;

logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] a;
logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] b;
logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] c;
logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] d;
logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] w0;
logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] w1;
logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] w2;
logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] w3;

// outputs 0:3 of butterfly units 0:N_BUTTERFLY-1, each of width FULL_WIDTH. 
logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] out_d [0:3];
logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] out   [0:3];


logic [FULL_WIDTH-1:0] w_16 [0:9] = '{
    { 18'd131071,    18'd0},        // W0
    { 18'd121094,   -18'd50159},    // W1
    { 18'd92681,    -18'd92681},    // W2
    { 18'd50159,    -18'd121094},   // W3
    { 18'd0,        -18'd131072},   // W4
    {-18'd50159,    -18'd121094},   // W5
    {-18'd92681,    -18'd92681},    // W6
    {-18'd121094,   -18'd50159},    // W7
    {-18'd131072,    18'd0},        // W8
    {-18'd121094,    18'd50159}     // W9
};

// frequency output magnitude estimation
logic [WIDTH-1:0] freq_real [0:N-1];
logic [WIDTH-1:0] freq_imag [0:N-1];
mag_est #(.WIDTH(WIDTH), .N(N)) MAG ( 
	.real_in(freq_real), 
	.imag_in(freq_imag), 
	.magnitude(freq_mag)
);

typedef enum logic [1:0] {SET, STAGE1, STAGE2, DONE} state_t;
state_t state, state_d;

logic [1:0] done_sr;
assign done = (state == DONE);

genvar i;
generate 
    for (i = 0; i < N_BUTTERFLY; i++) begin : gen_butterfly
        butterfly_4 #(.FULL_WIDTH(FULL_WIDTH)) butterfly (
            .a(a[i]),
            .b(b[i]),
            .c(c[i]),
            .d(d[i]),
            .w0(w0[i]),
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
    state <= state_d;

    out <= out_d;

    if (rst) begin
        done_sr <= 2'b0;
    end else begin
        done_sr <= {state_d == DONE, done_sr[1]};
    end
end

// state machine for butterfly unit inputs
always_comb begin
    case (state) 
    SET: begin
        for (int i = 0; i < N_BUTTERFLY; i++) begin
            a[i] = 1'b0;
            b[i] = 1'b0;
            c[i] = 1'b0;
            d[i] = 1'b0;
            w0[i]= 1'b0;
            w1[i]= 1'b0;
            w2[i]= 1'b0;
            w3[i]= 1'b0;
        end
    end

    // load time samples into upper 12 bits (real part) of a,b,c,d inputs 
    // time sample indices are bit-reversed for loading WRONG
    STAGE1: begin   
        for (int i = 0; i < N_BUTTERFLY; i++) begin
            a[i][FULL_WIDTH-1:WIDTH] = $signed(time_samples[i+N_BUTTERFLY*0]);
            b[i][FULL_WIDTH-1:WIDTH] = $signed(time_samples[i+N_BUTTERFLY*1]);
            c[i][FULL_WIDTH-1:WIDTH] = $signed(time_samples[i+N_BUTTERFLY*2]);
            d[i][FULL_WIDTH-1:WIDTH] = $signed(time_samples[i+N_BUTTERFLY*3]);
            a[i][WIDTH-1:0] = 1'b0;
            b[i][WIDTH-1:0] = 1'b0;
            c[i][WIDTH-1:0] = 1'b0;
            d[i][WIDTH-1:0] = 1'b0;
            w0[i]= w_16[0];
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
            w0[i]= w_16[i*0];
            w1[i]= w_16[i*1];
            w2[i]= w_16[i*2];
            w3[i]= w_16[i*3];
        end
    end

    DONE: begin
        for (int i = 0; i < N_BUTTERFLY; i++) begin
            a[i] = 1'b0;
            b[i] = 1'b0;
            c[i] = 1'b0;
            d[i] = 1'b0;
            w0[i]= 1'b0;
            w1[i]= 1'b0;
            w2[i]= 1'b0;
            w3[i]= 1'b0;
        end
    end

    default: begin
        for (int i = 0; i < N_BUTTERFLY; i++) begin
            a[i] = 1'b0;
            b[i] = 1'b0;
            c[i] = 1'b0;
            d[i] = 1'b0;
            w0[i]= 1'b0;
            w1[i]= 1'b0;
            w2[i]= 1'b0;
            w3[i]= 1'b0;
        end

    end
    endcase
end

// state transition logic 
always_comb begin
    case (state)
    SET: begin
        if (start) begin
            state_d = STAGE1;
        end else begin
            state_d = SET;
        end
    end

    STAGE1: begin
        if (rst) begin
            state_d = SET;  
        end else begin
            state_d = STAGE2;
        end
    end

    STAGE2: begin
        if (rst) begin
            state_d = SET;
        end else begin
            state_d = DONE;
        end
    end

    DONE: begin
        // if (rst) begin
        //     state_d = SET;
        // end else begin
        //     state_d = DONE;
        // end

        state_d = SET;
    end

    default: begin
        state_d = SET;
    end

    endcase
end

// catch freq_samples
always_ff @(negedge clk) begin
    if (done_sr == 2'b10) begin
        for (int i = 0; i < N_BUTTERFLY; i++) begin
            freq_real[i+N_BUTTERFLY*0] <= out[0][i][FULL_WIDTH-1:WIDTH];
            freq_real[i+N_BUTTERFLY*1] <= out[1][i][FULL_WIDTH-1:WIDTH];
            freq_real[i+N_BUTTERFLY*2] <= out[2][i][FULL_WIDTH-1:WIDTH];
            freq_real[i+N_BUTTERFLY*3] <= out[3][i][FULL_WIDTH-1:WIDTH];

            freq_imag[i+N_BUTTERFLY*0] <= out[0][i][WIDTH-1:0];
            freq_imag[i+N_BUTTERFLY*1] <= out[1][i][WIDTH-1:0];
            freq_imag[i+N_BUTTERFLY*2] <= out[2][i][WIDTH-1:0];
            freq_imag[i+N_BUTTERFLY*3] <= out[3][i][WIDTH-1:0];
        end
    end else if (state_d == SET) begin
        for (int i = 0; i < N; i++) begin
            freq_real[i] <= 1'b0;
            freq_imag[i] <= 1'b0;
        end
    end
end

endmodule