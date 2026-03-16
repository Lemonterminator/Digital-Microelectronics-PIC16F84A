#include "adder1bit.h"

#include <array>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

namespace {

constexpr std::size_t kWidth = 8;

std::array<uint8_t, kWidth> uint8_to_bits(const unsigned int value) {
    std::array<uint8_t, kWidth> bits{};
    for (std::size_t i = 0; i < kWidth; ++i) {
        bits[i] = static_cast<uint8_t>((value >> i) & 0x1U);
    }
    return bits;
}

unsigned int bits_to_uint8(const std::array<uint8_t, kWidth>& bits) {
    unsigned int value = 0;
    for (std::size_t i = 0; i < kWidth; ++i) {
        value |= static_cast<unsigned int>(bits[i] & 0x1U) << i;
    }
    return value;
}

bool parse_csv_line(const std::string& line, unsigned int& a, unsigned int& b) {
    if (line.empty()) {
        return false;
    }

    std::stringstream ss(line);
    std::string a_str;
    std::string b_str;

    if (!std::getline(ss, a_str, ',')) {
        return false;
    }
    if (!std::getline(ss, b_str, ',')) {
        return false;
    }

    a = static_cast<unsigned int>(std::stoul(a_str));
    b = static_cast<unsigned int>(std::stoul(b_str));
    return true;
}

}  // namespace

int main() {
    std::ifstream input("adder_input.csv");
    std::ofstream output("adder_output.csv");

    if (!input.is_open()) {
        std::cerr << "Failed to open adder_input.csv\n";
        return 1;
    }
    if (!output.is_open()) {
        std::cerr << "Failed to open adder_output.csv\n";
        return 1;
    }

    output << "A,B,S,CO\n";

    std::string line;
    while (std::getline(input, line)) {
        unsigned int a = 0;
        unsigned int b = 0;
        if (!parse_csv_line(line, a, b)) {
            continue;
        }

        const auto a_bits = uint8_to_bits(a);
        const auto b_bits = uint8_to_bits(b);
        const auto result = adder_nbits<kWidth>(a_bits, b_bits, 0);

        output << a << ',' << b << ',' << bits_to_uint8(result.s) << ','
               << static_cast<unsigned int>(result.co) << '\n';
    }

    return 0;
}
