module n_bit_adder #(parameter n = 8;)(
    input   [n-1:0] A,
    input   [n-1:0] B,
    output  [n-1:0] S,
    output          CO
);
    wire [n:0] sum_ext;
    assign sum_ext = {1'b0, A} + {1'b0, B};
    assign S = sum_ext[n-1:0];
    assign CO = sum_ext[n];

endmodule