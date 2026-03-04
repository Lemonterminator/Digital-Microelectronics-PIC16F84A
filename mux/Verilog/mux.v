module mux_8_bit (
    input   wire        s,
    input   wire[7:0]   A,
    input   wire[7:0]   B,
    output  wire[7:0]   Q
);
assign Q =  (s==1'b0)   ?   A:
            (s==1'b1)   ?   B:
            8b'00000000;
endmodule
