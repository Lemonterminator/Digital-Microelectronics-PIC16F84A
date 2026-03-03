#!/usr/bin/env bash
set -euo pipefail

g++ -std=c++17 -O2 -Wall -Wextra -pedantic main.cpp logic_gate.c -o sim_cpp
./sim_cpp

echo "Run complete: wave.vcd"
echo "Open with: gtkwave wave.vcd"
