#!/usr/bin/env bash
set -euo pipefail

ghdl -a --std=08 not_gate.vhd xor_gate.vhd or_gate.vhd and_gate.vhd nand_gate.vhd tb_hello.vhd
ghdl -e --std=08 tb_hello
ghdl -r --std=08 tb_hello --vcd=wave.vcd --stop-time=50ns

echo "Simulation complete: wave.vcd"
echo "Open with: gtkwave wave.vcd"
