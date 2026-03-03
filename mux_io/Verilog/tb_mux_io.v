`timescale 1ns/1ps

module tb_mux;
    integer fd, fd_out, r;
    reg [16:0] bits17;
    reg [7:0] A, B;
    reg s;
    wire [7:0] Q;

    mux_8_bit dut(
        .s(s),
        .A(A),
        .B(B),
        .Q(Q)
    );

    initial begin
        fd = $fopen("input", "r");
        if (fd == 0) begin
            $display("Failed to open input");
            $finish;
        end

        fd_out = $fopen("output", "w");
        if (fd_out == 0) begin
            $display("Failed to open output");
            $finish;
        end

        // Read token-by-token: each token is one 17-bit line A[7:0]B[7:0]s
        r = $fscanf(fd, "%b\n", bits17);
        while (r == 1) begin
            A = bits17[16:9];
            B = bits17[8:1];
            s = bits17[0];
            #10;
            $fdisplay(fd_out, "%08b", Q);
            $display("A=%08b B=%08b s=%0b -> Q=%08b", A, B, s, Q);
            r = $fscanf(fd, "%b\n", bits17);
        end

        if (r != -1) begin
            $display("Parse error in input file (expected 17-bit binary per line)");
        end

        $fclose(fd);
        $fclose(fd_out);
        $finish;
    end

endmodule
