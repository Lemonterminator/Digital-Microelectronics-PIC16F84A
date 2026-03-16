#ifndef ADDER_1BIT_H
#define ADDER_1BIT_H

#include <array>
#include <cstddef>
#include <cstdint>

struct Adder1BitResult {
    uint8_t s;
    uint8_t co;
};

template <std::size_t N>
struct AdderNBitsResult {
    std::array<uint8_t, N> s;
    uint8_t co;
};

inline Adder1BitResult adder_1bit(const uint8_t a, const uint8_t b, const uint8_t ci) {
    return {
        static_cast<uint8_t>((a + b + ci) % 2),
        static_cast<uint8_t>((a + b + ci) / 2)
    };
}

template <std::size_t N>
AdderNBitsResult<N> adder_nbits(
    const std::array<uint8_t, N>& A,
    const std::array<uint8_t, N>& B,
    uint8_t ci
) {
    uint8_t ci_n = ci;
    std::array<uint8_t, N> S{};

    for (std::size_t i = 0; i < N; ++i) {
        const Adder1BitResult res = adder_1bit(A[i], B[i], ci_n);
        S[i] = res.s;
        ci_n = res.co;
    }

    return {S, ci_n};
}

#endif
