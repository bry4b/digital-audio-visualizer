module fft_256_old #(
    parameter WIDTH = 16,
    parameter N = 256  // must be power of 4
) (
    input clk,
    input rst,
    input start,
    output done,

    input [WIDTH-1:0] time_samples [0:N-1],
    output logic [WIDTH:0] freq_mag [0:N-1]
    // output logic [WIDTH:0] freq_real [0:N-1],
    // output logic [WIDTH:0] freq_imag [0:N-1]
);

/*
    256-point decimation-in-time FFT using radix-4 butterfly units. 
    64 butterfly units are needed, but due to device (Intel MAX10 10M50DAF484C7G) limitations, we can only instantiate 16 at a time. 
    each stage is split into four sub-stages to perform computations in parallel. 
    12b twiddle factor (plus sign bit) is necessary to retain uniqueness of finest granularity twiddle factors.
    increased width yields higher accuracy at the cost of more resources.
    this module assumes a 12b input bus of time-domain data, and outputs a 14b bus of approximated complex frequency magnitudes. 
    computations are performed using 13b numbers to prevent signed overflow

    TODO: look into loading ROM for twiddle factors? not sure if read latency will be an issue, currently stored in logic array

    handy resources for 4-radix FFT implementations: 
        https://www.ti.com/lit/an/spra152/spra152.pdf 
        https://www.cmlab.csie.ntu.edu.tw/cml/dsp/training/coding/transform/fft.html
        https://thescipub.com/abstract/ajassp.2007.570.575 
        https://www.worldscientific.com/doi/abs/10.1142/S021812661240018X
*/

localparam N_BFLY = (N+3)/4;
localparam N_LOG2 = $clog2(N);
localparam N_STAGES = N_LOG2/2;
localparam FULL_WIDTH = WIDTH*2;

// inputs to instantiated butterfly units
logic [0:N_BFLY-1] [FULL_WIDTH-1:0] a;
logic [0:N_BFLY-1] [FULL_WIDTH-1:0] b;
logic [0:N_BFLY-1] [FULL_WIDTH-1:0] c;
logic [0:N_BFLY-1] [FULL_WIDTH-1:0] d;
logic [0:N_BFLY-1] [FULL_WIDTH-1:0] w0;
logic [0:N_BFLY-1] [FULL_WIDTH-1:0] w1;
logic [0:N_BFLY-1] [FULL_WIDTH-1:0] w2;
logic [0:N_BFLY-1] [FULL_WIDTH-1:0] w3;

// outputs of instantiated butterfly units
logic [0:N_BFLY-1] [FULL_WIDTH-1:0] out_d [0:3];

// outputs of butterfly units 0:N_BFLY-1 from previous stage 
logic [0:N_BFLY-1] [FULL_WIDTH-1:0] out [0:3];

// twiddle factors for 256-point FFT, generated by gen_twiddle.py
logic [0:N-1] [FULL_WIDTH-1:0] w_256 = '{
    { 16'd32767,     16'd0},        // W0
    { 16'd32758,    -16'd804},      // W1
    { 16'd32728,    -16'd1607},     // W2
    { 16'd32679,    -16'd2410},     // W3
    { 16'd32610,    -16'd3211},     // W4
    { 16'd32521,    -16'd4011},     // W5
    { 16'd32413,    -16'd4808},     // W6
    { 16'd32285,    -16'd5602},     // W7
    { 16'd32138,    -16'd6392},     // W8
    { 16'd31971,    -16'd7179},     // W9
    { 16'd31785,    -16'd7961},     // W10
    { 16'd31581,    -16'd8739},     // W11
    { 16'd31357,    -16'd9512},     // W12
    { 16'd31114,    -16'd10278},    // W13
    { 16'd30852,    -16'd11039},    // W14
    { 16'd30572,    -16'd11793},    // W15
    { 16'd30273,    -16'd12539},    // W16
    { 16'd29956,    -16'd13278},    // W17
    { 16'd29621,    -16'd14010},    // W18
    { 16'd29269,    -16'd14732},    // W19
    { 16'd28898,    -16'd15446},    // W20
    { 16'd28511,    -16'd16151},    // W21
    { 16'd28106,    -16'd16846},    // W22
    { 16'd27684,    -16'd17530},    // W23
    { 16'd27245,    -16'd18204},    // W24
    { 16'd26790,    -16'd18868},    // W25
    { 16'd26319,    -16'd19519},    // W26
    { 16'd25832,    -16'd20159},    // W27
    { 16'd25330,    -16'd20787},    // W28
    { 16'd24812,    -16'd21403},    // W29
    { 16'd24279,    -16'd22005},    // W30
    { 16'd23732,    -16'd22594},    // W31
    { 16'd23170,    -16'd23170},    // W32
    { 16'd22594,    -16'd23732},    // W33
    { 16'd22005,    -16'd24279},    // W34
    { 16'd21403,    -16'd24812},    // W35
    { 16'd20787,    -16'd25330},    // W36
    { 16'd20159,    -16'd25832},    // W37
    { 16'd19519,    -16'd26319},    // W38
    { 16'd18868,    -16'd26790},    // W39
    { 16'd18204,    -16'd27245},    // W40
    { 16'd17530,    -16'd27684},    // W41
    { 16'd16846,    -16'd28106},    // W42
    { 16'd16151,    -16'd28511},    // W43
    { 16'd15446,    -16'd28898},    // W44
    { 16'd14732,    -16'd29269},    // W45
    { 16'd14010,    -16'd29621},    // W46
    { 16'd13278,    -16'd29956},    // W47
    { 16'd12539,    -16'd30273},    // W48
    { 16'd11793,    -16'd30572},    // W49
    { 16'd11039,    -16'd30852},    // W50
    { 16'd10278,    -16'd31114},    // W51
    { 16'd9512,     -16'd31357},    // W52
    { 16'd8739,     -16'd31581},    // W53
    { 16'd7961,     -16'd31785},    // W54
    { 16'd7179,     -16'd31971},    // W55
    { 16'd6392,     -16'd32138},    // W56
    { 16'd5602,     -16'd32285},    // W57
    { 16'd4808,     -16'd32413},    // W58
    { 16'd4011,     -16'd32521},    // W59
    { 16'd3211,     -16'd32610},    // W60
    { 16'd2410,     -16'd32679},    // W61
    { 16'd1607,     -16'd32728},    // W62
    { 16'd804,      -16'd32758},    // W63
    { 16'd0,        -16'd32768},    // W64
    {-16'd804,      -16'd32758},    // W65
    {-16'd1607,     -16'd32728},    // W66
    {-16'd2410,     -16'd32679},    // W67
    {-16'd3211,     -16'd32610},    // W68
    {-16'd4011,     -16'd32521},    // W69
    {-16'd4808,     -16'd32413},    // W70
    {-16'd5602,     -16'd32285},    // W71
    {-16'd6392,     -16'd32138},    // W72
    {-16'd7179,     -16'd31971},    // W73
    {-16'd7961,     -16'd31785},    // W74
    {-16'd8739,     -16'd31581},    // W75
    {-16'd9512,     -16'd31357},    // W76
    {-16'd10278,    -16'd31114},    // W77
    {-16'd11039,    -16'd30852},    // W78
    {-16'd11793,    -16'd30572},    // W79
    {-16'd12539,    -16'd30273},    // W80
    {-16'd13278,    -16'd29956},    // W81
    {-16'd14010,    -16'd29621},    // W82
    {-16'd14732,    -16'd29269},    // W83
    {-16'd15446,    -16'd28898},    // W84
    {-16'd16151,    -16'd28511},    // W85
    {-16'd16846,    -16'd28106},    // W86
    {-16'd17530,    -16'd27684},    // W87
    {-16'd18204,    -16'd27245},    // W88
    {-16'd18868,    -16'd26790},    // W89
    {-16'd19519,    -16'd26319},    // W90
    {-16'd20159,    -16'd25832},    // W91
    {-16'd20787,    -16'd25330},    // W92
    {-16'd21403,    -16'd24812},    // W93
    {-16'd22005,    -16'd24279},    // W94
    {-16'd22594,    -16'd23732},    // W95
    {-16'd23170,    -16'd23170},    // W96
    {-16'd23732,    -16'd22594},    // W97
    {-16'd24279,    -16'd22005},    // W98
    {-16'd24812,    -16'd21403},    // W99
    {-16'd25330,    -16'd20787},    // W100
    {-16'd25832,    -16'd20159},    // W101
    {-16'd26319,    -16'd19519},    // W102
    {-16'd26790,    -16'd18868},    // W103
    {-16'd27245,    -16'd18204},    // W104
    {-16'd27684,    -16'd17530},    // W105
    {-16'd28106,    -16'd16846},    // W106
    {-16'd28511,    -16'd16151},    // W107
    {-16'd28898,    -16'd15446},    // W108
    {-16'd29269,    -16'd14732},    // W109
    {-16'd29621,    -16'd14010},    // W110
    {-16'd29956,    -16'd13278},    // W111
    {-16'd30273,    -16'd12539},    // W112
    {-16'd30572,    -16'd11793},    // W113
    {-16'd30852,    -16'd11039},    // W114
    {-16'd31114,    -16'd10278},    // W115
    {-16'd31357,    -16'd9512},     // W116
    {-16'd31581,    -16'd8739},     // W117
    {-16'd31785,    -16'd7961},     // W118
    {-16'd31971,    -16'd7179},     // W119
    {-16'd32138,    -16'd6392},     // W120
    {-16'd32285,    -16'd5602},     // W121
    {-16'd32413,    -16'd4808},     // W122
    {-16'd32521,    -16'd4011},     // W123
    {-16'd32610,    -16'd3211},     // W124
    {-16'd32679,    -16'd2410},     // W125
    {-16'd32728,    -16'd1607},     // W126
    {-16'd32758,    -16'd804},      // W127
    {-16'd32768,     16'd0},        // W128
    {-16'd32758,     16'd804},      // W129
    {-16'd32728,     16'd1607},     // W130
    {-16'd32679,     16'd2410},     // W131
    {-16'd32610,     16'd3211},     // W132
    {-16'd32521,     16'd4011},     // W133
    {-16'd32413,     16'd4808},     // W134
    {-16'd32285,     16'd5602},     // W135
    {-16'd32138,     16'd6392},     // W136
    {-16'd31971,     16'd7179},     // W137
    {-16'd31785,     16'd7961},     // W138
    {-16'd31581,     16'd8739},     // W139
    {-16'd31357,     16'd9512},     // W140
    {-16'd31114,     16'd10278},    // W141
    {-16'd30852,     16'd11039},    // W142
    {-16'd30572,     16'd11793},    // W143
    {-16'd30273,     16'd12539},    // W144
    {-16'd29956,     16'd13278},    // W145
    {-16'd29621,     16'd14010},    // W146
    {-16'd29269,     16'd14732},    // W147
    {-16'd28898,     16'd15446},    // W148
    {-16'd28511,     16'd16151},    // W149
    {-16'd28106,     16'd16846},    // W150
    {-16'd27684,     16'd17530},    // W151
    {-16'd27245,     16'd18204},    // W152
    {-16'd26790,     16'd18868},    // W153
    {-16'd26319,     16'd19519},    // W154
    {-16'd25832,     16'd20159},    // W155
    {-16'd25330,     16'd20787},    // W156
    {-16'd24812,     16'd21403},    // W157
    {-16'd24279,     16'd22005},    // W158
    {-16'd23732,     16'd22594},    // W159
    {-16'd23170,     16'd23170},    // W160
    {-16'd22594,     16'd23732},    // W161
    {-16'd22005,     16'd24279},    // W162
    {-16'd21403,     16'd24812},    // W163
    {-16'd20787,     16'd25330},    // W164
    {-16'd20159,     16'd25832},    // W165
    {-16'd19519,     16'd26319},    // W166
    {-16'd18868,     16'd26790},    // W167
    {-16'd18204,     16'd27245},    // W168
    {-16'd17530,     16'd27684},    // W169
    {-16'd16846,     16'd28106},    // W170
    {-16'd16151,     16'd28511},    // W171
    {-16'd15446,     16'd28898},    // W172
    {-16'd14732,     16'd29269},    // W173
    {-16'd14010,     16'd29621},    // W174
    {-16'd13278,     16'd29956},    // W175
    {-16'd12539,     16'd30273},    // W176
    {-16'd11793,     16'd30572},    // W177
    {-16'd11039,     16'd30852},    // W178
    {-16'd10278,     16'd31114},    // W179
    {-16'd9512,      16'd31357},    // W180
    {-16'd8739,      16'd31581},    // W181
    {-16'd7961,      16'd31785},    // W182
    {-16'd7179,      16'd31971},    // W183
    {-16'd6392,      16'd32138},    // W184
    {-16'd5602,      16'd32285},    // W185
    {-16'd4808,      16'd32413},    // W186
    {-16'd4011,      16'd32521},    // W187
    {-16'd3211,      16'd32610},    // W188
    {-16'd2410,      16'd32679},    // W189
    {-16'd1607,      16'd32728},    // W190
    {-16'd804,       16'd32758},    // W191
    { 16'd0,         16'd32767},    // W192
    { 16'd804,       16'd32758},    // W193
    { 16'd1607,      16'd32728},    // W194
    { 16'd2410,      16'd32679},    // W195
    { 16'd3211,      16'd32610},    // W196
    { 16'd4011,      16'd32521},    // W197
    { 16'd4808,      16'd32413},    // W198
    { 16'd5602,      16'd32285},    // W199
    { 16'd6392,      16'd32138},    // W200
    { 16'd7179,      16'd31971},    // W201
    { 16'd7961,      16'd31785},    // W202
    { 16'd8739,      16'd31581},    // W203
    { 16'd9512,      16'd31357},    // W204
    { 16'd10278,     16'd31114},    // W205
    { 16'd11039,     16'd30852},    // W206
    { 16'd11793,     16'd30572},    // W207
    { 16'd12539,     16'd30273},    // W208
    { 16'd13278,     16'd29956},    // W209
    { 16'd14010,     16'd29621},    // W210
    { 16'd14732,     16'd29269},    // W211
    { 16'd15446,     16'd28898},    // W212
    { 16'd16151,     16'd28511},    // W213
    { 16'd16846,     16'd28106},    // W214
    { 16'd17530,     16'd27684},    // W215
    { 16'd18204,     16'd27245},    // W216
    { 16'd18868,     16'd26790},    // W217
    { 16'd19519,     16'd26319},    // W218
    { 16'd20159,     16'd25832},    // W219
    { 16'd20787,     16'd25330},    // W220
    { 16'd21403,     16'd24812},    // W221
    { 16'd22005,     16'd24279},    // W222
    { 16'd22594,     16'd23732},    // W223
    { 16'd23170,     16'd23170},    // W224
    { 16'd23732,     16'd22594},    // W225
    { 16'd24279,     16'd22005},    // W226
    { 16'd24812,     16'd21403},    // W227
    { 16'd25330,     16'd20787},    // W228
    { 16'd25832,     16'd20159},    // W229
    { 16'd26319,     16'd19519},    // W230
    { 16'd26790,     16'd18868},    // W231
    { 16'd27245,     16'd18204},    // W232
    { 16'd27684,     16'd17530},    // W233
    { 16'd28106,     16'd16846},    // W234
    { 16'd28511,     16'd16151},    // W235
    { 16'd28898,     16'd15446},    // W236
    { 16'd29269,     16'd14732},    // W237
    { 16'd29621,     16'd14010},    // W238
    { 16'd29956,     16'd13278},    // W239
    { 16'd30273,     16'd12539},    // W240
    { 16'd30572,     16'd11793},    // W241
    { 16'd30852,     16'd11039},    // W242
    { 16'd31114,     16'd10278},    // W243
    { 16'd31357,     16'd9512},     // W244
    { 16'd31581,     16'd8739},     // W245
    { 16'd31785,     16'd7961},     // W246
    { 16'd31971,     16'd7179},     // W247
    { 16'd32138,     16'd6392},     // W248
    { 16'd32285,     16'd5602},     // W249
    { 16'd32413,     16'd4808},     // W250
    { 16'd32521,     16'd4011},     // W251
    { 16'd32610,     16'd3211},     // W252
    { 16'd32679,     16'd2410},     // W253
    { 16'd32728,     16'd1607},     // W254
    { 16'd32758,     16'd804}       // W255
};

// frequency output magnitude estimation
logic [WIDTH-1:0] freq_real [0:N-1];
logic [WIDTH-1:0] freq_imag [0:N-1];
mag_est #(.WIDTH(WIDTH), .N(N)) MAG ( 
	.real_in(freq_real), 
	.imag_in(freq_imag), 
	.magnitude(freq_mag)
);

typedef enum logic [2:0] {SET, STAGE1, STAGE2, STAGE3, STAGE4, DONE} state_t;
state_t state, state_d;

logic [1:0] done_sr;
assign done = (state == DONE);

// INSTANTIATE RADIX4 BFLY UNITS
genvar i;
generate 
    for (i = 0; i < N_BFLY; i++) begin : gen_BFLY
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
    out <= out_d;
    if (rst) begin
        done_sr <= 2'b0;
        state <= SET;
    end else begin
        done_sr <= {(state_d == DONE), done_sr[1]};
        state <= state_d;
    end
end

// state machine for butterfly unit inputs
always_comb begin
    case (state) 
    SET: begin
        for (int i = 0; i < N_BFLY; i++) begin
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

    // load time samples into upper 13 bits (real part) of a,b,c,d inputs. 
    // 12b time samples need to be sign extended by 1 bit.
    STAGE1: begin   
        for (int i = 0; i < N_BFLY; i++) begin
            a[i] = $signed({time_samples[i+N_BFLY*0], 14'b0}) >>> 1'b1;
            b[i] = $signed({time_samples[i+N_BFLY*1], 14'b0}) >>> 1'b1;
            c[i] = $signed({time_samples[i+N_BFLY*2], 14'b0}) >>> 1'b1;
            d[i] = $signed({time_samples[i+N_BFLY*3], 14'b0}) >>> 1'b1;
            w0[i]= w_256[0];
            w1[i]= w_256[0];
            w2[i]= w_256[0];
            w3[i]= w_256[0];
        end
    end

    STAGE2: begin
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 16; j++) begin
                a[i*16+j] = out[i][j+0*16];
                b[i*16+j] = out[i][j+1*16];
                c[i*16+j] = out[i][j+2*16];
                d[i*16+j] = out[i][j+3*16];
                w0[i*16+j]= w_256[i*(j+0*16)];
                w1[i*16+j]= w_256[i*(j+1*16)];
                w2[i*16+j]= w_256[i*(j+2*16)];
                w3[i*16+j]= w_256[i*(j+3*16)];
            end
        end
    end

    STAGE3: begin
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                for (int k = 0; k < 4; k++) begin
                    a[i*16+j*4+k] = out[j][i*16+k+0*4];
                    b[i*16+j*4+k] = out[j][i*16+k+1*4];
                    c[i*16+j*4+k] = out[j][i*16+k+2*4];
                    d[i*16+j*4+k] = out[j][i*16+k+3*4];
                    w0[i*16+j*4+k]= w_256[j*4*(k+0*4)];
                    w1[i*16+j*4+k]= w_256[j*4*(k+1*4)];
                    w2[i*16+j*4+k]= w_256[j*4*(k+2*4)];
                    w3[i*16+j*4+k]= w_256[j*4*(k+3*4)];
                end
            end
        end
    end

    STAGE4: begin
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                for (int k = 0; k < 4; k++) begin
                    a[i*16+j*4+k] = out[k][i*16+j*4+0];
                    b[i*16+j*4+k] = out[k][i*16+j*4+1];
                    c[i*16+j*4+k] = out[k][i*16+j*4+2];
                    d[i*16+j*4+k] = out[k][i*16+j*4+3];
                    w0[i*16+j*4+k]= w_256[k*0*16];
                    w1[i*16+j*4+k]= w_256[k*1*16];
                    w2[i*16+j*4+k]= w_256[k*2*16];
                    w3[i*16+j*4+k]= w_256[k*3*16];
                end
            end
        end
    end

    DONE: begin
        for (int i = 0; i < N_BFLY; i++) begin
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
        for (int i = 0; i < N_BFLY; i++) begin
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
            state_d = STAGE4;
        end
    end

    STAGE4: begin
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

// catch frequency outputs
always_ff @(negedge clk) begin
    if (done_sr == 2'b10) begin
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                for (int k = 0; k < 4; k++) begin
                    freq_real[i+j*4+k*16+N_BFLY*0] <= out[0][i*16+j*4+k][FULL_WIDTH-1:WIDTH];
                    freq_real[i+j*4+k*16+N_BFLY*1] <= out[1][i*16+j*4+k][FULL_WIDTH-1:WIDTH];
                    freq_real[i+j*4+k*16+N_BFLY*2] <= out[2][i*16+j*4+k][FULL_WIDTH-1:WIDTH];
                    freq_real[i+j*4+k*16+N_BFLY*3] <= out[3][i*16+j*4+k][FULL_WIDTH-1:WIDTH];

                    freq_imag[i+j*4+k*16+N_BFLY*0] <= out[0][i*16+j*4+k][WIDTH-1:0];
                    freq_imag[i+j*4+k*16+N_BFLY*1] <= out[1][i*16+j*4+k][WIDTH-1:0];
                    freq_imag[i+j*4+k*16+N_BFLY*2] <= out[2][i*16+j*4+k][WIDTH-1:0];
                    freq_imag[i+j*4+k*16+N_BFLY*3] <= out[3][i*16+j*4+k][WIDTH-1:0];
                end
            end
        end
    end else if (state_d == SET) begin
        for (int i = 0; i < N; i++) begin
            freq_real[i] <= 1'b0;
            freq_imag[i] <= 1'b0;
        end
    end
end

endmodule