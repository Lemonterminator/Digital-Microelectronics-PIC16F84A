#!/usr/bin/env bash
set -euo pipefail

# NEXT STEP: after adding file-IO in main.cpp, verify generated `output` against expected results.
g++ -std=c++17 -O2 -Wall -Wextra -pedantic main.cpp mux.cpp -o sim_cpp
./sim_cpp

echo "Run complete: wave.vcd"
echo "Open with: gtkwave wave.vcd"
