module fft_256 #(
    parameter WIDTH = 12,
    parameter N = 256  // must be power of 4
) (
    input clk,
    input rst,
    input start,
    output done,

    input [WIDTH-1:0] time_samples [0:N-1],
    output logic [WIDTH:0] freq_real [0:N-1],
    output logic [WIDTH:0] freq_imag [0:N-1]
);

/*
    256-point decimation-in-time FFT using radix-4 butterfly units. 
    12b twiddle factor (plus sign bit) is necessary to retain uniqueness of finest granularity twiddle factors.
    increased width yields higher accuracy at the cost of more resources.
    this module assumes a 12b input bus of time-domain data, and outputs a 14b bus of approximated complex frequency magnitudes. 
    computations are performed using 13b numbers to prevent signed overflow

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

logic [FULL_WIDTH-1:0] a [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] b [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] c [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] d [0:N_BUTTERFLY-1];

// outputs 0:3 of butterfly units 0:N_BUTTERFLY-1, each of width FULL_WIDTH. 
logic [FULL_WIDTH-1:0] out   [0:3] [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] out_d [0:3] [0:N_BUTTERFLY-1];   // next outputs

logic [FULL_WIDTH-1:0] w0 [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] w1 [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] w2 [0:N_BUTTERFLY-1];
logic [FULL_WIDTH-1:0] w3 [0:N_BUTTERFLY-1];

// twiddle factors for 256-point FFT, generated by gen_twiddle.py
// TODO: look into loading ROM
logic [FULL_WIDTH-1:0] w_256 [0:N-1] = '{
    {{1'b0,  12'd2048},     {1'b0,  12'd0}},        // W0
    {{1'b0,  12'd2047},     {1'b1, -12'd50}},       // W1
    {{1'b0,  12'd2045},     {1'b1, -12'd100}},      // W2
    {{1'b0,  12'd2042},     {1'b1, -12'd150}},      // W3
    {{1'b0,  12'd2038},     {1'b1, -12'd200}},      // W4
    {{1'b0,  12'd2032},     {1'b1, -12'd250}},      // W5
    {{1'b0,  12'd2025},     {1'b1, -12'd300}},      // W6
    {{1'b0,  12'd2017},     {1'b1, -12'd350}},      // W7
    {{1'b0,  12'd2008},     {1'b1, -12'd399}},      // W8
    {{1'b0,  12'd1998},     {1'b1, -12'd448}},      // W9
    {{1'b0,  12'd1986},     {1'b1, -12'd497}},      // W10
    {{1'b0,  12'd1973},     {1'b1, -12'd546}},      // W11
    {{1'b0,  12'd1959},     {1'b1, -12'd594}},      // W12
    {{1'b0,  12'd1944},     {1'b1, -12'd642}},      // W13
    {{1'b0,  12'd1928},     {1'b1, -12'd689}},      // W14
    {{1'b0,  12'd1910},     {1'b1, -12'd737}},      // W15
    {{1'b0,  12'd1892},     {1'b1, -12'd783}},      // W16
    {{1'b0,  12'd1872},     {1'b1, -12'd829}},      // W17
    {{1'b0,  12'd1851},     {1'b1, -12'd875}},      // W18
    {{1'b0,  12'd1829},     {1'b1, -12'd920}},      // W19
    {{1'b0,  12'd1806},     {1'b1, -12'd965}},      // W20
    {{1'b0,  12'd1781},     {1'b1, -12'd1009}},     // W21
    {{1'b0,  12'd1756},     {1'b1, -12'd1052}},     // W22
    {{1'b0,  12'd1730},     {1'b1, -12'd1095}},     // W23
    {{1'b0,  12'd1702},     {1'b1, -12'd1137}},     // W24
    {{1'b0,  12'd1674},     {1'b1, -12'd1179}},     // W25
    {{1'b0,  12'd1644},     {1'b1, -12'd1219}},     // W26
    {{1'b0,  12'd1614},     {1'b1, -12'd1259}},     // W27
    {{1'b0,  12'd1583},     {1'b1, -12'd1299}},     // W28
    {{1'b0,  12'd1550},     {1'b1, -12'd1337}},     // W29
    {{1'b0,  12'd1517},     {1'b1, -12'd1375}},     // W30
    {{1'b0,  12'd1483},     {1'b1, -12'd1412}},     // W31
    {{1'b0,  12'd1448},     {1'b1, -12'd1448}},     // W32
    {{1'b0,  12'd1412},     {1'b1, -12'd1483}},     // W33
    {{1'b0,  12'd1375},     {1'b1, -12'd1517}},     // W34
    {{1'b0,  12'd1337},     {1'b1, -12'd1550}},     // W35
    {{1'b0,  12'd1299},     {1'b1, -12'd1583}},     // W36
    {{1'b0,  12'd1259},     {1'b1, -12'd1614}},     // W37
    {{1'b0,  12'd1219},     {1'b1, -12'd1644}},     // W38
    {{1'b0,  12'd1179},     {1'b1, -12'd1674}},     // W39
    {{1'b0,  12'd1137},     {1'b1, -12'd1702}},     // W40
    {{1'b0,  12'd1095},     {1'b1, -12'd1730}},     // W41
    {{1'b0,  12'd1052},     {1'b1, -12'd1756}},     // W42
    {{1'b0,  12'd1009},     {1'b1, -12'd1781}},     // W43
    {{1'b0,  12'd965},      {1'b1, -12'd1806}},     // W44
    {{1'b0,  12'd920},      {1'b1, -12'd1829}},     // W45
    {{1'b0,  12'd875},      {1'b1, -12'd1851}},     // W46
    {{1'b0,  12'd829},      {1'b1, -12'd1872}},     // W47
    {{1'b0,  12'd783},      {1'b1, -12'd1892}},     // W48
    {{1'b0,  12'd737},      {1'b1, -12'd1910}},     // W49
    {{1'b0,  12'd689},      {1'b1, -12'd1928}},     // W50
    {{1'b0,  12'd642},      {1'b1, -12'd1944}},     // W51
    {{1'b0,  12'd594},      {1'b1, -12'd1959}},     // W52
    {{1'b0,  12'd546},      {1'b1, -12'd1973}},     // W53
    {{1'b0,  12'd497},      {1'b1, -12'd1986}},     // W54
    {{1'b0,  12'd448},      {1'b1, -12'd1998}},     // W55
    {{1'b0,  12'd399},      {1'b1, -12'd2008}},     // W56
    {{1'b0,  12'd350},      {1'b1, -12'd2017}},     // W57
    {{1'b0,  12'd300},      {1'b1, -12'd2025}},     // W58
    {{1'b0,  12'd250},      {1'b1, -12'd2032}},     // W59
    {{1'b0,  12'd200},      {1'b1, -12'd2038}},     // W60
    {{1'b0,  12'd150},      {1'b1, -12'd2042}},     // W61
    {{1'b0,  12'd100},      {1'b1, -12'd2045}},     // W62
    {{1'b0,  12'd50},       {1'b1, -12'd2047}},     // W63
    {{1'b0,  12'd0},        {1'b1, -12'd2048}},     // W64
    {{1'b1, -12'd50},       {1'b1, -12'd2047}},     // W65
    {{1'b1, -12'd100},      {1'b1, -12'd2045}},     // W66
    {{1'b1, -12'd150},      {1'b1, -12'd2042}},     // W67
    {{1'b1, -12'd200},      {1'b1, -12'd2038}},     // W68
    {{1'b1, -12'd250},      {1'b1, -12'd2032}},     // W69
    {{1'b1, -12'd300},      {1'b1, -12'd2025}},     // W70
    {{1'b1, -12'd350},      {1'b1, -12'd2017}},     // W71
    {{1'b1, -12'd399},      {1'b1, -12'd2008}},     // W72
    {{1'b1, -12'd448},      {1'b1, -12'd1998}},     // W73
    {{1'b1, -12'd497},      {1'b1, -12'd1986}},     // W74
    {{1'b1, -12'd546},      {1'b1, -12'd1973}},     // W75
    {{1'b1, -12'd594},      {1'b1, -12'd1959}},     // W76
    {{1'b1, -12'd642},      {1'b1, -12'd1944}},     // W77
    {{1'b1, -12'd689},      {1'b1, -12'd1928}},     // W78
    {{1'b1, -12'd737},      {1'b1, -12'd1910}},     // W79
    {{1'b1, -12'd783},      {1'b1, -12'd1892}},     // W80
    {{1'b1, -12'd829},      {1'b1, -12'd1872}},     // W81
    {{1'b1, -12'd875},      {1'b1, -12'd1851}},     // W82
    {{1'b1, -12'd920},      {1'b1, -12'd1829}},     // W83
    {{1'b1, -12'd965},      {1'b1, -12'd1806}},     // W84
    {{1'b1, -12'd1009},     {1'b1, -12'd1781}},     // W85
    {{1'b1, -12'd1052},     {1'b1, -12'd1756}},     // W86
    {{1'b1, -12'd1095},     {1'b1, -12'd1730}},     // W87
    {{1'b1, -12'd1137},     {1'b1, -12'd1702}},     // W88
    {{1'b1, -12'd1179},     {1'b1, -12'd1674}},     // W89
    {{1'b1, -12'd1219},     {1'b1, -12'd1644}},     // W90
    {{1'b1, -12'd1259},     {1'b1, -12'd1614}},     // W91
    {{1'b1, -12'd1299},     {1'b1, -12'd1583}},     // W92
    {{1'b1, -12'd1337},     {1'b1, -12'd1550}},     // W93
    {{1'b1, -12'd1375},     {1'b1, -12'd1517}},     // W94
    {{1'b1, -12'd1412},     {1'b1, -12'd1483}},     // W95
    {{1'b1, -12'd1448},     {1'b1, -12'd1448}},     // W96
    {{1'b1, -12'd1483},     {1'b1, -12'd1412}},     // W97
    {{1'b1, -12'd1517},     {1'b1, -12'd1375}},     // W98
    {{1'b1, -12'd1550},     {1'b1, -12'd1337}},     // W99
    {{1'b1, -12'd1583},     {1'b1, -12'd1299}},     // W100
    {{1'b1, -12'd1614},     {1'b1, -12'd1259}},     // W101
    {{1'b1, -12'd1644},     {1'b1, -12'd1219}},     // W102
    {{1'b1, -12'd1674},     {1'b1, -12'd1179}},     // W103
    {{1'b1, -12'd1702},     {1'b1, -12'd1137}},     // W104
    {{1'b1, -12'd1730},     {1'b1, -12'd1095}},     // W105
    {{1'b1, -12'd1756},     {1'b1, -12'd1052}},     // W106
    {{1'b1, -12'd1781},     {1'b1, -12'd1009}},     // W107
    {{1'b1, -12'd1806},     {1'b1, -12'd965}},      // W108
    {{1'b1, -12'd1829},     {1'b1, -12'd920}},      // W109
    {{1'b1, -12'd1851},     {1'b1, -12'd875}},      // W110
    {{1'b1, -12'd1872},     {1'b1, -12'd829}},      // W111
    {{1'b1, -12'd1892},     {1'b1, -12'd783}},      // W112
    {{1'b1, -12'd1910},     {1'b1, -12'd737}},      // W113
    {{1'b1, -12'd1928},     {1'b1, -12'd689}},      // W114
    {{1'b1, -12'd1944},     {1'b1, -12'd642}},      // W115
    {{1'b1, -12'd1959},     {1'b1, -12'd594}},      // W116
    {{1'b1, -12'd1973},     {1'b1, -12'd546}},      // W117
    {{1'b1, -12'd1986},     {1'b1, -12'd497}},      // W118
    {{1'b1, -12'd1998},     {1'b1, -12'd448}},      // W119
    {{1'b1, -12'd2008},     {1'b1, -12'd399}},      // W120
    {{1'b1, -12'd2017},     {1'b1, -12'd350}},      // W121
    {{1'b1, -12'd2025},     {1'b1, -12'd300}},      // W122
    {{1'b1, -12'd2032},     {1'b1, -12'd250}},      // W123
    {{1'b1, -12'd2038},     {1'b1, -12'd200}},      // W124
    {{1'b1, -12'd2042},     {1'b1, -12'd150}},      // W125
    {{1'b1, -12'd2045},     {1'b1, -12'd100}},      // W126
    {{1'b1, -12'd2047},     {1'b1, -12'd50}},       // W127
    {{1'b1, -12'd2048},     {1'b0,  12'd0}},        // W128
    {{1'b1, -12'd2047},     {1'b0,  12'd50}},       // W129
    {{1'b1, -12'd2045},     {1'b0,  12'd100}},      // W130
    {{1'b1, -12'd2042},     {1'b0,  12'd150}},      // W131
    {{1'b1, -12'd2038},     {1'b0,  12'd200}},      // W132
    {{1'b1, -12'd2032},     {1'b0,  12'd250}},      // W133
    {{1'b1, -12'd2025},     {1'b0,  12'd300}},      // W134
    {{1'b1, -12'd2017},     {1'b0,  12'd350}},      // W135
    {{1'b1, -12'd2008},     {1'b0,  12'd399}},      // W136
    {{1'b1, -12'd1998},     {1'b0,  12'd448}},      // W137
    {{1'b1, -12'd1986},     {1'b0,  12'd497}},      // W138
    {{1'b1, -12'd1973},     {1'b0,  12'd546}},      // W139
    {{1'b1, -12'd1959},     {1'b0,  12'd594}},      // W140
    {{1'b1, -12'd1944},     {1'b0,  12'd642}},      // W141
    {{1'b1, -12'd1928},     {1'b0,  12'd689}},      // W142
    {{1'b1, -12'd1910},     {1'b0,  12'd737}},      // W143
    {{1'b1, -12'd1892},     {1'b0,  12'd783}},      // W144
    {{1'b1, -12'd1872},     {1'b0,  12'd829}},      // W145
    {{1'b1, -12'd1851},     {1'b0,  12'd875}},      // W146
    {{1'b1, -12'd1829},     {1'b0,  12'd920}},      // W147
    {{1'b1, -12'd1806},     {1'b0,  12'd965}},      // W148
    {{1'b1, -12'd1781},     {1'b0,  12'd1009}},     // W149
    {{1'b1, -12'd1756},     {1'b0,  12'd1052}},     // W150
    {{1'b1, -12'd1730},     {1'b0,  12'd1095}},     // W151
    {{1'b1, -12'd1702},     {1'b0,  12'd1137}},     // W152
    {{1'b1, -12'd1674},     {1'b0,  12'd1179}},     // W153
    {{1'b1, -12'd1644},     {1'b0,  12'd1219}},     // W154
    {{1'b1, -12'd1614},     {1'b0,  12'd1259}},     // W155
    {{1'b1, -12'd1583},     {1'b0,  12'd1299}},     // W156
    {{1'b1, -12'd1550},     {1'b0,  12'd1337}},     // W157
    {{1'b1, -12'd1517},     {1'b0,  12'd1375}},     // W158
    {{1'b1, -12'd1483},     {1'b0,  12'd1412}},     // W159
    {{1'b1, -12'd1448},     {1'b0,  12'd1448}},     // W160
    {{1'b1, -12'd1412},     {1'b0,  12'd1483}},     // W161
    {{1'b1, -12'd1375},     {1'b0,  12'd1517}},     // W162
    {{1'b1, -12'd1337},     {1'b0,  12'd1550}},     // W163
    {{1'b1, -12'd1299},     {1'b0,  12'd1583}},     // W164
    {{1'b1, -12'd1259},     {1'b0,  12'd1614}},     // W165
    {{1'b1, -12'd1219},     {1'b0,  12'd1644}},     // W166
    {{1'b1, -12'd1179},     {1'b0,  12'd1674}},     // W167
    {{1'b1, -12'd1137},     {1'b0,  12'd1702}},     // W168
    {{1'b1, -12'd1095},     {1'b0,  12'd1730}},     // W169
    {{1'b1, -12'd1052},     {1'b0,  12'd1756}},     // W170
    {{1'b1, -12'd1009},     {1'b0,  12'd1781}},     // W171
    {{1'b1, -12'd965},      {1'b0,  12'd1806}},     // W172
    {{1'b1, -12'd920},      {1'b0,  12'd1829}},     // W173
    {{1'b1, -12'd875},      {1'b0,  12'd1851}},     // W174
    {{1'b1, -12'd829},      {1'b0,  12'd1872}},     // W175
    {{1'b1, -12'd783},      {1'b0,  12'd1892}},     // W176
    {{1'b1, -12'd737},      {1'b0,  12'd1910}},     // W177
    {{1'b1, -12'd689},      {1'b0,  12'd1928}},     // W178
    {{1'b1, -12'd642},      {1'b0,  12'd1944}},     // W179
    {{1'b1, -12'd594},      {1'b0,  12'd1959}},     // W180
    {{1'b1, -12'd546},      {1'b0,  12'd1973}},     // W181
    {{1'b1, -12'd497},      {1'b0,  12'd1986}},     // W182
    {{1'b1, -12'd448},      {1'b0,  12'd1998}},     // W183
    {{1'b1, -12'd399},      {1'b0,  12'd2008}},     // W184
    {{1'b1, -12'd350},      {1'b0,  12'd2017}},     // W185
    {{1'b1, -12'd300},      {1'b0,  12'd2025}},     // W186
    {{1'b1, -12'd250},      {1'b0,  12'd2032}},     // W187
    {{1'b1, -12'd200},      {1'b0,  12'd2038}},     // W188
    {{1'b1, -12'd150},      {1'b0,  12'd2042}},     // W189
    {{1'b1, -12'd100},      {1'b0,  12'd2045}},     // W190
    {{1'b1, -12'd50},       {1'b0,  12'd2047}},     // W191
    {{1'b0,  12'd0},        {1'b0,  12'd2048}},     // W192
    {{1'b0,  12'd50},       {1'b0,  12'd2047}},     // W193
    {{1'b0,  12'd100},      {1'b0,  12'd2045}},     // W194
    {{1'b0,  12'd150},      {1'b0,  12'd2042}},     // W195
    {{1'b0,  12'd200},      {1'b0,  12'd2038}},     // W196
    {{1'b0,  12'd250},      {1'b0,  12'd2032}},     // W197
    {{1'b0,  12'd300},      {1'b0,  12'd2025}},     // W198
    {{1'b0,  12'd350},      {1'b0,  12'd2017}},     // W199
    {{1'b0,  12'd399},      {1'b0,  12'd2008}},     // W200
    {{1'b0,  12'd448},      {1'b0,  12'd1998}},     // W201
    {{1'b0,  12'd497},      {1'b0,  12'd1986}},     // W202
    {{1'b0,  12'd546},      {1'b0,  12'd1973}},     // W203
    {{1'b0,  12'd594},      {1'b0,  12'd1959}},     // W204
    {{1'b0,  12'd642},      {1'b0,  12'd1944}},     // W205
    {{1'b0,  12'd689},      {1'b0,  12'd1928}},     // W206
    {{1'b0,  12'd737},      {1'b0,  12'd1910}},     // W207
    {{1'b0,  12'd783},      {1'b0,  12'd1892}},     // W208
    {{1'b0,  12'd829},      {1'b0,  12'd1872}},     // W209
    {{1'b0,  12'd875},      {1'b0,  12'd1851}},     // W210
    {{1'b0,  12'd920},      {1'b0,  12'd1829}},     // W211
    {{1'b0,  12'd965},      {1'b0,  12'd1806}},     // W212
    {{1'b0,  12'd1009},     {1'b0,  12'd1781}},     // W213
    {{1'b0,  12'd1052},     {1'b0,  12'd1756}},     // W214
    {{1'b0,  12'd1095},     {1'b0,  12'd1730}},     // W215
    {{1'b0,  12'd1137},     {1'b0,  12'd1702}},     // W216
    {{1'b0,  12'd1179},     {1'b0,  12'd1674}},     // W217
    {{1'b0,  12'd1219},     {1'b0,  12'd1644}},     // W218
    {{1'b0,  12'd1259},     {1'b0,  12'd1614}},     // W219
    {{1'b0,  12'd1299},     {1'b0,  12'd1583}},     // W220
    {{1'b0,  12'd1337},     {1'b0,  12'd1550}},     // W221
    {{1'b0,  12'd1375},     {1'b0,  12'd1517}},     // W222
    {{1'b0,  12'd1412},     {1'b0,  12'd1483}},     // W223
    {{1'b0,  12'd1448},     {1'b0,  12'd1448}},     // W224
    {{1'b0,  12'd1483},     {1'b0,  12'd1412}},     // W225
    {{1'b0,  12'd1517},     {1'b0,  12'd1375}},     // W226
    {{1'b0,  12'd1550},     {1'b0,  12'd1337}},     // W227
    {{1'b0,  12'd1583},     {1'b0,  12'd1299}},     // W228
    {{1'b0,  12'd1614},     {1'b0,  12'd1259}},     // W229
    {{1'b0,  12'd1644},     {1'b0,  12'd1219}},     // W230
    {{1'b0,  12'd1674},     {1'b0,  12'd1179}},     // W231
    {{1'b0,  12'd1702},     {1'b0,  12'd1137}},     // W232
    {{1'b0,  12'd1730},     {1'b0,  12'd1095}},     // W233
    {{1'b0,  12'd1756},     {1'b0,  12'd1052}},     // W234
    {{1'b0,  12'd1781},     {1'b0,  12'd1009}},     // W235
    {{1'b0,  12'd1806},     {1'b0,  12'd965}},      // W236
    {{1'b0,  12'd1829},     {1'b0,  12'd920}},      // W237
    {{1'b0,  12'd1851},     {1'b0,  12'd875}},      // W238
    {{1'b0,  12'd1872},     {1'b0,  12'd829}},      // W239
    {{1'b0,  12'd1892},     {1'b0,  12'd783}},      // W240
    {{1'b0,  12'd1910},     {1'b0,  12'd737}},      // W241
    {{1'b0,  12'd1928},     {1'b0,  12'd689}},      // W242
    {{1'b0,  12'd1944},     {1'b0,  12'd642}},      // W243
    {{1'b0,  12'd1959},     {1'b0,  12'd594}},      // W244
    {{1'b0,  12'd1973},     {1'b0,  12'd546}},      // W245
    {{1'b0,  12'd1986},     {1'b0,  12'd497}},      // W246
    {{1'b0,  12'd1998},     {1'b0,  12'd448}},      // W247
    {{1'b0,  12'd2008},     {1'b0,  12'd399}},      // W248
    {{1'b0,  12'd2017},     {1'b0,  12'd350}},      // W249
    {{1'b0,  12'd2025},     {1'b0,  12'd300}},      // W250
    {{1'b0,  12'd2032},     {1'b0,  12'd250}},      // W251
    {{1'b0,  12'd2038},     {1'b0,  12'd200}},      // W252
    {{1'b0,  12'd2042},     {1'b0,  12'd150}},      // W253
    {{1'b0,  12'd2045},     {1'b0,  12'd100}},      // W254
    {{1'b0,  12'd2047},     {1'b0,  12'd50}}        // W255
};

typedef enum logic [2:0] {SET, STAGE1, STAGE2, STAGE3, STAGE4, DONE} state_t;
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

    // load time samples into upper 13 bits (real part) of a,b,c,d inputs. 
    // 12b time samples need to be sign extended by 1 bit.
    STAGE1: begin   
        for (int i = 0; i < N_BUTTERFLY; i++) begin
            a[i] = $signed({time_samples[i+N_BUTTERFLY*0], 14'b0}) >>> 1'b1;
            b[i] = $signed({time_samples[i+N_BUTTERFLY*1], 14'b0}) >>> 1'b1;
            c[i] = $signed({time_samples[i+N_BUTTERFLY*2], 14'b0}) >>> 1'b1;
            d[i] = $signed({time_samples[i+N_BUTTERFLY*3], 14'b0}) >>> 1'b1;
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

// catch frequency outputs
always_ff @(negedge clk) begin
    if (state_d == SET) begin
        for (int i = 0; i < N; i++) begin
            freq_real[i] <= 1'b0;
            freq_imag[i] <= 1'b0;
        end
    end else if (done_sr == 2'b10) begin
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                for (int k = 0; k < 4; k++) begin
                    freq_real[i+j*4+k*16+N_BUTTERFLY*0] <= out[0][i*16+j*4+k][FULL_WIDTH-1:WIDTH+1];
                    freq_real[i+j*4+k*16+N_BUTTERFLY*1] <= out[1][i*16+j*4+k][FULL_WIDTH-1:WIDTH+1];
                    freq_real[i+j*4+k*16+N_BUTTERFLY*2] <= out[2][i*16+j*4+k][FULL_WIDTH-1:WIDTH+1];
                    freq_real[i+j*4+k*16+N_BUTTERFLY*3] <= out[3][i*16+j*4+k][FULL_WIDTH-1:WIDTH+1];

                    freq_imag[i+j*4+k*16+N_BUTTERFLY*0] <= out[0][i*16+j*4+k][WIDTH:0];
                    freq_imag[i+j*4+k*16+N_BUTTERFLY*1] <= out[1][i*16+j*4+k][WIDTH:0];
                    freq_imag[i+j*4+k*16+N_BUTTERFLY*2] <= out[2][i*16+j*4+k][WIDTH:0];
                    freq_imag[i+j*4+k*16+N_BUTTERFLY*3] <= out[3][i*16+j*4+k][WIDTH:0];
                end
            end
        end
    end
end

endmodule