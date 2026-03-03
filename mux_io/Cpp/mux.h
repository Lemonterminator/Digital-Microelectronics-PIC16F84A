#ifndef MUX_H
#define MUX_H

#include <array>
#include <cstdint>

// NEXT STEP: add file-IO driven testbench flow in main.cpp (read 17-bit lines, write Q per 10ns).
std::array<uint8_t, 8> mux_8_bit(   const std::array<uint8_t, 8> & A,
                                    const std::array<uint8_t, 8> & B, 
                                    bool s);
#endif
