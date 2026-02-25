#include <array>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

#include "mux.h"

struct Sample {
  int t_ns;
  std::vector<int> a; // 0/1 bits
  std::vector<int> b; // 0/1 bits
  bool s;             // select
  std::vector<int> q_exp; // expected 0/1 bits
};

static std::array<uint8_t, 8> vec_to_array8(const std::vector<int>& v) {
  if (v.size() != 8) throw std::invalid_argument("need exactly 8 bits");
  std::array<uint8_t, 8> a{};
  for (size_t i = 0; i < 8; ++i) {
    if (v[i] != 0 && v[i] != 1) throw std::invalid_argument("bit must be 0/1");
    a[i] = static_cast<uint8_t>(v[i]);
  }
  return a;
}

static std::vector<int> array8_to_vec(const std::array<uint8_t, 8>& a) {
  std::vector<int> v(8);
  for (size_t i = 0; i < 8; ++i) {
    v[i] = static_cast<int>(a[i]);
  }
  return v;
}

static std::string bits_to_vcd_binary_msb_first(const std::vector<int>& bits) {
  std::string out;
  out.reserve(bits.size());
  // Internal vectors are LSB-first, VCD binary is printed MSB-first.
  for (size_t idx = bits.size(); idx > 0; --idx) {
    const int v = bits[idx - 1];
    if (v != 0 && v != 1) throw std::invalid_argument("bit must be 0 or 1");
    out.push_back(v ? '1' : '0');
  }
  return out;
}

static void write_vcd(const std::string& path, const std::vector<Sample>& samples) {
  std::ofstream vcd(path);
  if (!vcd) throw std::runtime_error("Failed to open VCD output");
  if (samples.empty()) return;

  const size_t w = samples.front().a.size();
  if (w == 0) throw std::invalid_argument("bus width must be > 0");

  auto check_width = [w](const Sample& s) {
    return s.a.size() == w && s.b.size() == w && s.q_exp.size() == w;
  };
  for (const auto& s : samples) {
    if (!check_width(s)) throw std::invalid_argument("inconsistent bus width in samples");
  }

  vcd << "$date\n  Wed Feb 25 2026\n$end\n";
  vcd << "$version\n  cpp-mux-tb\n$end\n";
  vcd << "$timescale\n  1ns\n$end\n";
  vcd << "$scope module tb_cpp $end\n";
  vcd << "$var wire " << w << " ! a $end\n";
  vcd << "$var wire " << w << " \" b $end\n";
  vcd << "$var wire 1 # s $end\n";
  vcd << "$var wire " << w << " $ q $end\n";
  vcd << "$upscope $end\n";
  vcd << "$enddefinitions $end\n";

  for (const auto& s : samples) {
    vcd << "#" << s.t_ns << "\n";
    vcd << "b" << bits_to_vcd_binary_msb_first(s.a) << " !\n";
    vcd << "b" << bits_to_vcd_binary_msb_first(s.b) << " \"\n";
    vcd << (s.s ? '1' : '0') << "#\n";
    vcd << "b" << bits_to_vcd_binary_msb_first(s.q_exp) << " $\n";
  }
}

static std::vector<int> expected_q(const std::vector<int>& a,
                                   const std::vector<int>& b,
                                   bool s) {
  if (a.size() != b.size()) {
    throw std::invalid_argument("a and b must have the same width");
  }
  std::vector<int> q(a.size(), 0);
  for (size_t i = 0; i < a.size(); ++i) {
    if ((a[i] != 0 && a[i] != 1) || (b[i] != 0 && b[i] != 1)) {
      throw std::invalid_argument("input bits must be 0/1");
    }
    q[i] = s ? b[i] : a[i];
  }
  return q;
}

int main() {
  std::vector<Sample> samples = {
      {0, {0, 0, 0, 0, 1, 1, 0, 1}, {1, 0, 1, 1, 0, 0, 1, 0}, false, {}},
      {10, {0, 0, 0, 0, 1, 1, 0, 1}, {1, 0, 1, 1, 0, 0, 1, 0}, true, {}},
      {20, {1, 1, 0, 0, 1, 0, 1, 0}, {0, 0, 1, 1, 0, 1, 0, 1}, false, {}},
      {30, {1, 1, 0, 0, 1, 0, 1, 0}, {0, 0, 1, 1, 0, 1, 0, 1}, true, {}},
  };

  for (auto& s : samples) {
    s.q_exp = expected_q(s.a, s.b, s.s);
  }

  bool pass_var = true;
  bool pass_8 = true;

  for (const auto& s : samples) {
    const std::vector<int> q_var = mux(s.a, s.b, s.s);
    if (q_var != s.q_exp) {
      pass_var = false;
      std::cerr << "Variable mux mismatch at t=" << s.t_ns << "ns\n";
    }

    const std::array<uint8_t, 8> a8 = vec_to_array8(s.a);
    const std::array<uint8_t, 8> b8 = vec_to_array8(s.b);
    const std::array<uint8_t, 8> q8 = mux_8_bit(a8, b8, s.s);
    if (array8_to_vec(q8) != s.q_exp) {
      pass_8 = false;
      std::cerr << "8-bit mux mismatch at t=" << s.t_ns << "ns\n";
    }
  }

  write_vcd("wave.vcd", samples);

  std::cout << "Variable mux: " << (pass_var ? "PASS" : "FAIL") << "\n";
  std::cout << "8-bit mux: " << (pass_8 ? "PASS" : "FAIL") << "\n";
  std::cout << "Wrote wave.vcd\n";

  return (pass_var && pass_8) ? 0 : 1;
}
