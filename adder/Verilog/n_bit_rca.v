module n_bit_rca #(parameter n = 4) (
    input  [n-1:0] A,
    input  [n-1:0] B,
    output [n-1:0] S,
    output         CO
);

    wire [n:0] c;
    genvar i;

    assign c[0] = 1'b0;
    assign CO   = c[n];

    generate
        for (i = 0; i < n; i = i + 1) begin : gen_fa
            full_adder fa (
                .a (A[i]),
                .b (B[i]),
                .ci(c[i]),
                .s (S[i]),
                .co(c[i+1])
            );
        end
    endgenerate

endmodule
