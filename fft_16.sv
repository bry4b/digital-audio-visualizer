module fft_16 #(
    parameter WIDTH = 12,
    parameter N = 16  // must be power of 4
) (
    input clk,
    input rst,
    input start,
    output done,

    input [WIDTH-1:0]       time_samples    [0:N-1],
    output logic [WIDTH:0]  freq_real       [0:N-1],
    output logic [WIDTH:0]  freq_imag       [0:N-1]
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
localparam FULL_WIDTH = (WIDTH+1)*2;

logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] a;
logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] b;
logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] c;
logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] d;

// outputs 0:3 of butterfly units 0:N_BUTTERFLY-1, each of width FULL_WIDTH. 
logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] out   [0:3];
logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] out_d [0:3];   // next outputs

logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] w0;
logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] w1;
logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] w2;
logic [0:N_BUTTERFLY-1] [FULL_WIDTH-1:0] w3;

logic [FULL_WIDTH-1:0] w_16 [0:9] = '{
    {{1'b0, (12'd1<<11)},   {1'b0, (12'd0)}},       // W0
    {{1'b0, (12'd1892)},    {1'b1, (-12'd784)}},     // W1
    {{1'b0, (12'd1448)},    {1'b1, (-12'd1448)}},    // W2
    {{1'b0, (12'd784)},     {1'b1, (-12'd1892)}},    // W3
    {{1'b0, (12'd0)},       {1'b1, (-12'd1<<11)}},   // W4
    {{1'b1, (-12'd784)},    {1'b1, (-12'd1892)}},    // W5
    {{1'b1, (-12'd1448)},   {1'b1, (-12'd1448)}},    // W6
    {{1'b1, (-12'd1892)},   {1'b1, (-12'd784)}},     // W7
    {{1'b1, (-12'd1<<11)},  {1'b0, (12'd0)}},       // W8
    {{1'b1, (-12'd1892)},   {1'b0, (12'd784)}}      // W9
};

typedef enum logic [1:0] {SET, STAGE1, STAGE2, DONE} state_t;
state_t state, state_d;

logic [1:0] done_sr;
assign done = (state == DONE);

genvar i;
generate 
    for (i = 0; i < N_BUTTERFLY; i++) begin : gen_butterfly
        butterfly_4 #(.WIDTH(FULL_WIDTH)) butterfly (
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
            a[i] = $signed({time_samples[i+N_BUTTERFLY*0], 14'b0}) >>> 1'b1;
            b[i] = $signed({time_samples[i+N_BUTTERFLY*1], 14'b0}) >>> 1'b1;
            c[i] = $signed({time_samples[i+N_BUTTERFLY*2], 14'b0}) >>> 1'b1;
            d[i] = $signed({time_samples[i+N_BUTTERFLY*3], 14'b0}) >>> 1'b1;
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
            freq_real[i+N_BUTTERFLY*0] <= out[0][i][FULL_WIDTH-1:WIDTH+1];
            freq_real[i+N_BUTTERFLY*1] <= out[1][i][FULL_WIDTH-1:WIDTH+1];
            freq_real[i+N_BUTTERFLY*2] <= out[2][i][FULL_WIDTH-1:WIDTH+1];
            freq_real[i+N_BUTTERFLY*3] <= out[3][i][FULL_WIDTH-1:WIDTH+1];

            freq_imag[i+N_BUTTERFLY*0] <= out[0][i][WIDTH:0];
            freq_imag[i+N_BUTTERFLY*1] <= out[1][i][WIDTH:0];
            freq_imag[i+N_BUTTERFLY*2] <= out[2][i][WIDTH:0];
            freq_imag[i+N_BUTTERFLY*3] <= out[3][i][WIDTH:0];
        end
    end else if (state_d == SET) begin
        for (int i = 0; i < N; i++) begin
            freq_real[i] <= 1'b0;
            freq_imag[i] <= 1'b0;
        end
    end
end

endmodule