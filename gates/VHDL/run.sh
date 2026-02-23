#!/usr/bin/env bash
set -euo pipefail

ghdl -a hello.vhd tb_hello.vhd
ghdl -e tb_hello
ghdl -r tb_hello --vcd=wave.vcd --stop-time=50ns

echo "Simulation complete: wave.vcd"
echo "Open with: gtkwave wave.vcd"
