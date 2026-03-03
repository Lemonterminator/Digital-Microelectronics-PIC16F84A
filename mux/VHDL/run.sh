#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

rm -f wave.vcd

# Analyze and elaborate
ghdl -a --std=08 mux_8_bit.vhd tb_ex01.vhd
ghdl -e --std=08 tb_ex01

# Run simulation and dump VCD
ghdl -r --std=08 tb_ex01 --vcd=wave.vcd --stop-time=30ns

echo "Simulation complete: wave.vcd"
echo "Open with: gtkwave wave.vcd"
