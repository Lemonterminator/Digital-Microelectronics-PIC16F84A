#!/usr/bin/env bash
set -euo pipefail

iverilog -g2012 -o simv tb_hello.v or.v xor.v and.v not.v
vvp simv

echo "Simulation complete: wave.vcd"
echo "Open with: gtkwave wave.vcd"
