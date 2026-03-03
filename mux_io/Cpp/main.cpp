#include <array>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <string>

#include "mux.h"

int main() {
  std::ifstream infile("input");
  if (!infile) {
    std::cerr << "Failed to open input file\n";
    return 1;
  }

  std::ofstream outfile("output");
  if (!outfile) {
    std::cerr << "Failed to open output file\n";
    return 1;
  }

  std::string line;
  size_t line_no = 0;
  while (std::getline(infile, line)) {
    ++line_no;
    if (line.size() != 17) {
      std::cerr << "Line " << line_no << ": length must be 17 (A[7:0]B[7:0]S)\n";
      return 1;
    }

    std::array<uint8_t, 8> A{};
    std::array<uint8_t, 8> B{};
    bool s = false;

    for (size_t i = 0; i < line.size(); ++i) {
      if (line[i] != '0' && line[i] != '1') {
        std::cerr << "Line " << line_no << ": invalid character at position " << (i + 1)
                  << " (must be 0 or 1)\n";
        return 1;
      }

      const uint8_t bit = static_cast<uint8_t>(line[i] - '0');
      if (i < 8) {
        A[i] = bit;
      } else if (i < 16) {
        B[i - 8] = bit;
      } else {
        s = (bit == 1);
      }
    }

    const std::array<uint8_t, 8> Q = mux_8_bit(A, B, s);
    std::string out_line;
    out_line.reserve(Q.size());
    for (uint8_t bit : Q) {
      out_line.push_back(bit ? '1' : '0');
    }
    outfile << out_line << '\n';
  }

  return 0;
}
