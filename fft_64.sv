module fft_64 #(
    parameter WIDTH = 12,
    parameter N = 64  // must be power of 4
) (
    input clk,
    input rst,
    input start,
    output done,

    input [WIDTH-1:0] time_samples [0:N-1],
    output logic [WIDTH-1:0] freq_samples [0:N-1]
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

logic [FULL_WIDTH-1:0] a [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] b [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] c [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] d [0:N_BUTTERFLY-1];

// outputs 0:3 of butterfly units 0:N_BUTTERFLY-1, each of width FULL_WIDTH. 
logic [FULL_WIDTH-1:0] out   [0:3] [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] out_d [0:3] [0:N_BUTTERFLY-1];   // next outputs

logic [FULL_WIDTH+1:0] w0 [0:N_BUTTERFLY-1];
logic [FULL_WIDTH+1:0] w1 [0:N_BUTTERFLY-1];
logic [FULL_WIDTH+1:0] w2 [0:N_BUTTERFLY-1];
logic [FULL_WIDTH+1:0] w3 [0:N_BUTTERFLY-1];

// twiddle factors for 64-point FFT
// TODO: look into loading ROM
logic [FULL_WIDTH+1:0] w_64 [0:63] = '{
{{1'b0, 12'd2048},      {1'b0, 12'd0}},         // W0
{{1'b0, 12'd2038},      {1'b1, -12'd200}},      // W1
{{1'b0, 12'd2008},      {1'b1, -12'd399}},      // W2
{{1'b0, 12'd1959},      {1'b1, -12'd594}},      // W3
{{1'b0, 12'd1892},      {1'b1, -12'd783}},      // W4
{{1'b0, 12'd1806},      {1'b1, -12'd965}},      // W5
{{1'b0, 12'd1702},      {1'b1, -12'd1137}},     // W6
{{1'b0, 12'd1583},      {1'b1, -12'd1299}},     // W7
{{1'b0, 12'd1448},      {1'b1, -12'd1448}},     // W8
{{1'b0, 12'd1299},      {1'b1, -12'd1583}},     // W9
{{1'b0, 12'd1137},      {1'b1, -12'd1702}},     // W10
{{1'b0, 12'd965},       {1'b1, -12'd1806}},     // W11
{{1'b0, 12'd783},       {1'b1, -12'd1892}},     // W12
{{1'b0, 12'd594},       {1'b1, -12'd1959}},     // W13
{{1'b0, 12'd399},       {1'b1, -12'd2008}},     // W14
{{1'b0, 12'd200},       {1'b1, -12'd2038}},     // W15
{{1'b0, 12'd0},         {1'b1, -12'd2048}},     // W16
{{1'b1, -12'd200},      {1'b1, -12'd2038}},     // W17
{{1'b1, -12'd399},      {1'b1, -12'd2008}},     // W18
{{1'b1, -12'd594},      {1'b1, -12'd1959}},     // W19
{{1'b1, -12'd783},      {1'b1, -12'd1892}},     // W20
{{1'b1, -12'd965},      {1'b1, -12'd1806}},     // W21
{{1'b1, -12'd1137},     {1'b1, -12'd1702}},     // W22
{{1'b1, -12'd1299},     {1'b1, -12'd1583}},     // W23
{{1'b1, -12'd1448},     {1'b1, -12'd1448}},     // W24
{{1'b1, -12'd1583},     {1'b1, -12'd1299}},     // W25
{{1'b1, -12'd1702},     {1'b1, -12'd1137}},     // W26
{{1'b1, -12'd1806},     {1'b1, -12'd965}},      // W27
{{1'b1, -12'd1892},     {1'b1, -12'd783}},      // W28
{{1'b1, -12'd1959},     {1'b1, -12'd594}},      // W29
{{1'b1, -12'd2008},     {1'b1, -12'd399}},      // W30
{{1'b1, -12'd2038},     {1'b1, -12'd200}},      // W31
{{1'b1, -12'd2048},     {1'b0, 12'd0}},         // W32
{{1'b1, -12'd2038},     {1'b0, 12'd200}},       // W33
{{1'b1, -12'd2008},     {1'b0, 12'd399}},       // W34
{{1'b1, -12'd1959},     {1'b0, 12'd594}},       // W35
{{1'b1, -12'd1892},     {1'b0, 12'd783}},       // W36
{{1'b1, -12'd1806},     {1'b0, 12'd965}},       // W37
{{1'b1, -12'd1702},     {1'b0, 12'd1137}},      // W38
{{1'b1, -12'd1583},     {1'b0, 12'd1299}},      // W39
{{1'b1, -12'd1448},     {1'b0, 12'd1448}},      // W40
{{1'b1, -12'd1299},     {1'b0, 12'd1583}},      // W41
{{1'b1, -12'd1137},     {1'b0, 12'd1702}},      // W42
{{1'b1, -12'd965},      {1'b0, 12'd1806}},      // W43
{{1'b1, -12'd783},      {1'b0, 12'd1892}},      // W44
{{1'b1, -12'd594},      {1'b0, 12'd1959}},      // W45
{{1'b1, -12'd399},      {1'b0, 12'd2008}},      // W46
{{1'b1, -12'd200},      {1'b0, 12'd2038}},      // W47
{{1'b0, 12'd0},         {1'b0, 12'd2048}},      // W48
{{1'b0, 12'd200},       {1'b0, 12'd2038}},      // W49
{{1'b0, 12'd399},       {1'b0, 12'd2008}},      // W50
{{1'b0, 12'd594},       {1'b0, 12'd1959}},      // W51
{{1'b0, 12'd783},       {1'b0, 12'd1892}},      // W52
{{1'b0, 12'd965},       {1'b0, 12'd1806}},      // W53
{{1'b0, 12'd1137},      {1'b0, 12'd1702}},      // W54
{{1'b0, 12'd1299},      {1'b0, 12'd1583}},      // W55
{{1'b0, 12'd1448},      {1'b0, 12'd1448}},      // W56
{{1'b0, 12'd1583},      {1'b0, 12'd1299}},      // W57
{{1'b0, 12'd1702},      {1'b0, 12'd1137}},      // W58
{{1'b0, 12'd1806},      {1'b0, 12'd965}},       // W59
{{1'b0, 12'd1892},      {1'b0, 12'd783}},       // W60
{{1'b0, 12'd1959},      {1'b0, 12'd594}},       // W61
{{1'b0, 12'd2008},      {1'b0, 12'd399}},       // W62
{{1'b0, 12'd2038},      {1'b0, 12'd200}}        // W63
};

typedef enum logic [2:0] {SET, STAGE1, STAGE2, STAGE3, DONE} state_t;
state_t state, state_d;

logic [1:0] done_sr;
assign done = (state == DONE);

genvar i;
generate 
    for (i = 0; i < N_BUTTERFLY; i++) begin : gen_butterfly
        butterfly_4 #(.WIDTH(FULL_WIDTH)) DUT (
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

    // out0 <= out0_d;
    // out1 <= out1_d;
    // out2 <= out2_d;
    // out3 <= out3_d;

    out <= out_d;

    if (rst) begin
        done_sr <= 2'b0;
    end else begin
        done_sr <= {(state_d == DONE), done_sr[1]};
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
    STAGE1: begin   
        for (int i = 0; i < N_BUTTERFLY; i++) begin
            a[i] = {time_samples[i+N_BUTTERFLY*0], 12'b0};
            b[i] = {time_samples[i+N_BUTTERFLY*1], 12'b0};
            c[i] = {time_samples[i+N_BUTTERFLY*2], 12'b0};
            d[i] = {time_samples[i+N_BUTTERFLY*3], 12'b0};
            w0[i]= w_64[0];
            w1[i]= w_64[0];
            w2[i]= w_64[0];
            w3[i]= w_64[0];
        end
    end

    STAGE2: begin
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                a[i*4+j] = out[i][j+0];
                b[i*4+j] = out[i][j+4];
                c[i*4+j] = out[i][j+8];
                d[i*4+j] = out[i][j+12];
                w0[i*4+j]= w_64[i*(j+0)];
                w1[i*4+j]= w_64[i*(j+4)];
                w2[i*4+j]= w_64[i*(j+8)];
                w3[i*4+j]= w_64[i*(j+12)];
            end
        end
    end

    STAGE3: begin
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                a[i*4+j] = out[j][i*4+0];
                b[i*4+j] = out[j][i*4+1];
                c[i*4+j] = out[j][i*4+2];
                d[i*4+j] = out[j][i*4+3];
                w0[i*4+j]= w_64[j*0];
                w1[i*4+j]= w_64[j*4];
                w2[i*4+j]= w_64[j*8];
                w3[i*4+j]= w_64[j*12];
            end
        end
    end
    
    DONE: begin
        for (int i = 0; i < N_BUTTERFLY; i++) begin
            // a[i] = out_l[i][0];
            // b[i] = out_l[i][1];
            // c[i] = out_l[i][2];
            // d[i] = out_l[i][3];
            // w1[i]= w_16[i*1];
            // w2[i]= w_16[i*2];
            // w3[i]= w_16[i*3];
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
            state_d = STAGE3;
        end
    end

    STAGE3: begin
        if (rst) begin
            state_d = SET;
        end else begin 
            state_d = DONE;
        end
    end

    DONE: begin
        if (rst) begin
            state_d = SET;
        end else begin
            state_d = DONE;
        end
    end

    default: begin
        state_d = SET;
    end

    endcase
end

// catch freq_samples
always_ff @(negedge clk) begin
    if (state_d == SET) begin
        for (int i = 0; i < N; i++) begin
            freq_samples[i] <= 1'b0;
        end
    end else if (done_sr == 2'b10) begin
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                freq_samples[i+j*4+N_BUTTERFLY*0] <= out[0][i*4+j][FULL_WIDTH-1:WIDTH];
                freq_samples[i+j*4+N_BUTTERFLY*1] <= out[1][i*4+j][FULL_WIDTH-1:WIDTH];
                freq_samples[i+j*4+N_BUTTERFLY*2] <= out[2][i*4+j][FULL_WIDTH-1:WIDTH];
                freq_samples[i+j*4+N_BUTTERFLY*3] <= out[3][i*4+j][FULL_WIDTH-1:WIDTH];
            end
        end
    end
end

endmodule