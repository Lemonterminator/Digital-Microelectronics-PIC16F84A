`timescale 1ns/1ps

module tb_hello;
  reg a = 1'b0;
  reg b = 1'b0;
  wire and_y;
  wire y;

  and_gate u_and (
    .a(a),
    .b(b),
    .y(and_y)
  );

  not_gate u_not (
    .a(and_y),
    .y(y)
  );

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_hello);

    a = 1'b0; b = 1'b0; #10;
    a = 1'b0; b = 1'b1; #10;
    a = 1'b1; b = 1'b0; #10;
    a = 1'b1; b = 1'b1; #10;

    $finish;
  end
endmodule
