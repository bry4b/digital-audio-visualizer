module mag_est #(
    parameter WIDTH = 12,
    parameter N = 256
) (
    input [WIDTH:0] real_in [0:N-1],
    input [WIDTH:0] imag_in [0:N-1],

    output logic [WIDTH+1:0] magnitude [0:N-1]
);

/* 
    complex magnitude estimator using crude alphaMax betaMin approximation
    alpha=1 beta=0.5
    max error is 11.80%, average error is 8.68%
    https://en.wikipedia.org/wiki/Alpha_max_plus_beta_min_algorithm
*/

genvar i;
generate 
    for (i = 0; i < N; i++) begin : gen_mag_est
        mag_est_single #(.WIDTH(WIDTH)) estimator (
            .real_in(real_in[i]),
            .imag_in(imag_in[i]),
            .magnitude(magnitude[i])
        );
    end
endgenerate

endmodule

module mag_est_single #(
    parameter WIDTH = 12
) (
    input [WIDTH:0] real_in,
    input [WIDTH:0] imag_in,

    output logic [WIDTH+1:0] magnitude
);

logic [WIDTH-1:0] real_abs;
logic [WIDTH-1:0] imag_abs;

assign real_abs = (real_in[WIDTH]) ? (~(real_in[WIDTH-1:0])+1'b1) : (real_in[WIDTH-1:0]);
assign imag_abs = (imag_in[WIDTH]) ? (~(imag_in[WIDTH-1:0])+1'b1) : (imag_in[WIDTH-1:0]);

always_comb begin
    if (real_abs > imag_abs) begin
        magnitude = real_abs + (imag_abs >> 1'b1);
    end else begin
        magnitude = imag_abs + (real_abs >> 1'b1);
    end
end

endmodule