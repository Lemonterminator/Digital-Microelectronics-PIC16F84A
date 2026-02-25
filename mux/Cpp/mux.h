#ifndef MUX_H
#define MUX_H

#include <vector>
#include <array>
#include <cstdint>

std::vector<int> mux(const std::vector<int> & A, const std::vector<int> & B, bool s);

std::array<uint8_t, 8> mux_8_bit(   const std::array<uint8_t, 8> & A,
                                    const std::array<uint8_t, 8> & B, 
                                    bool s);
#endif