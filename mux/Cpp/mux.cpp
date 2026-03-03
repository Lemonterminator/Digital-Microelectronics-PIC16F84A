#include "mux.h"
#include <vector>
#include <array>
#include <cstdint>
#include <stdexcept>

// Variable length mux
std::vector<int> mux(const std::vector<int> & A, const std::vector<int> & B, bool s){

    // Error handling
    if (A.size() != B.size()){
        throw std::invalid_argument("A and B must be of the same size");
    }

    std::vector<int> q(A.size());
    const int sel   = s? 1:0;
    const int nsel  = s? 0:1;

    // Select bit by bit
    for (size_t i=0; i<A.size(); ++i){
        // Error handling
        if ((A[i] != 0 && A[i] != 1) || (B[i] != 0 && B[i] != 1)) {
            throw std::invalid_argument("A and B must contain only 0/1");
        }
        q[i] = ((nsel & A[i])|(sel & B[i]));
    }
    return q;
};

// Fixed 8 bit mux
std::array<uint8_t, 8> mux_8_bit(   const std::array<uint8_t, 8> & A,
                                    const std::array<uint8_t, 8> & B, 
                                    bool s){
    // Fixed sized input, no need for error handling

    const int sel   = s? 1:0;
    const int nsel  = s? 0:1;
    std::array<uint8_t, 8> q{};

    // Select bit by bit
    for (size_t i=0; i<A.size(); ++i){
        // Error handling
        if ((A[i] != 0 && A[i] != 1) || (B[i] != 0 && B[i] != 1)) {
            throw std::invalid_argument("A and B must contain only 0/1");
        }
        q[i] = ((nsel & A[i])|(sel & B[i]));
    }
    return q;

};