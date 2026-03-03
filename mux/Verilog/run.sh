#!/usr/bin/env bash
set -euo pipefail

iverilog -g2012 -o simv tb_mux.v mux.v
vvp simv

echo "Simulation complete: wave.vcd"
echo "Open with: gtkwave wave.vcd"
