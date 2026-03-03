`timescale 1ns/1ps

module tb_mux;
    reg         s = 1'b0;
    reg [7:0]   A = 8'b0000_0000;
    reg [7:0]   B = 8'b0000_0000;
    wire [7:0]  Q; 

    mux_8_bit dut(
        .s(s),
        .A(A),
        .B(B),
        .Q(Q)
    );
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_mux);

        A = 8'h3C; B = 8'hA5; s = 1'b0; #10;
        s = 1'b1; # 10;
        $finish;
    end 

endmodule
