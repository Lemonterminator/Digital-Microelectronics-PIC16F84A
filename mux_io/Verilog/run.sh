#!/usr/bin/env bash
set -euo pipefail

iverilog -g2012 -o simv tb_mux_io.v mux.v
vvp simv

echo "Simulation complete"
echo "Wrote output file: output"
