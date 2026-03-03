#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

rm -f wave.vcd output work-obj08.cf

ghdl -a --std=08 mux_8_bit.vhd tb_ex01.vhd
ghdl -e --std=08 tb_ex01
ghdl -r --std=08 tb_ex01 --vcd=wave.vcd

echo "Simulation complete: wave.vcd"
echo "Vector output file: output"

if command -v gtkwave >/dev/null 2>&1; then
  echo "Open with: gtkwave wave.vcd"
else
  echo "gtkwave not found in PATH."
fi
