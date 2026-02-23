#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include "logic_gate.h"

struct Sample {
  int t_ns;
  int a;
  int b;
  int y;
};

static void write_vcd(const std::string& path, const std::vector<Sample>& samples) {
  std::ofstream vcd(path);
  if (!vcd) {
    throw std::runtime_error("Failed to open VCD output");
  }

  vcd << "$date\n  Sat Feb 21 2026\n$end\n";
  vcd << "$version\n  cpp-lesson1\n$end\n";
  vcd << "$timescale\n  1ns\n$end\n";
  vcd << "$scope module tb_cpp $end\n";
  vcd << "$var wire 1 ! a $end\n";
  vcd << "$var wire 1 \" b $end\n";
  vcd << "$var wire 1 # y $end\n";
  vcd << "$upscope $end\n";
  vcd << "$enddefinitions $end\n";

  if (samples.empty()) {
    return;
  }

  vcd << "#" << samples.front().t_ns << "\n";
  vcd << samples.front().a << "!\n";
  vcd << samples.front().b << "\"\n";
  vcd << samples.front().y << "#\n";

  for (size_t i = 1; i < samples.size(); ++i) {
    vcd << "#" << samples[i].t_ns << "\n";
    vcd << samples[i].a << "!\n";
    vcd << samples[i].b << "\"\n";
    vcd << samples[i].y << "#\n";
  }
}

int main() {
  std::vector<Sample> samples;

  const int vectors[4][2] = {{0, 0}, {0, 1}, {1, 0}, {1, 1}};
  for (int i = 0; i < 4; ++i) {
    const int a = vectors[i][0];
    const int b = vectors[i][1];
    // const int y = a ^ b;
    const int x = xor_gate(a, b);
    const int y = not_gate(x);
    
    const int t_ns = i * 10;

    samples.push_back({t_ns, a, b, y});

    std::cout << "t=" << t_ns << "ns  a=" << a << " b=" << b << " y=" << y << "\n";
  }

  write_vcd("wave.vcd", samples);
  std::cout << "Wrote wave.vcd\n";
  return 0;
}
