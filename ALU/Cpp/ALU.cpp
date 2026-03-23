#include "ALU.h"

namespace pic16f84a {

AluResult ALU::execute(const AluInput& input) {
    switch (input.op) {
        case AluOp::ADDWF:
        case AluOp::ADDLW:
            return add8(input.a, input.b, input.status_in);

        case AluOp::ANDWF:
        case AluOp::ANDLW:
            return bitwiseAnd(input.a, input.b, input.status_in);

        case AluOp::BCF:
            return clearBit(input.a, input.bit_select, input.status_in);

        case AluOp::BTFSC:
            return bitTestSkipIfClear(input.a, input.bit_select, input.status_in);

        case AluOp::BSF:
            return setBitOp(input.a, input.bit_select, input.status_in);

        case AluOp::BTFSS:
            return bitTestSkipIfSet(input.a, input.bit_select, input.status_in);

        case AluOp::CLRF:
        case AluOp::CLRW:
            return clear(input.status_in);

        case AluOp::COMF:
            return complement(input.a, input.status_in);

        case AluOp::DECF:
            return decrement(input.a, input.status_in, false);

        case AluOp::DECFSZ:
            return decrement(input.a, input.status_in, true);

        case AluOp::INCF:
            return increment(input.a, input.status_in, false);

        case AluOp::INCFSZ:
            return increment(input.a, input.status_in, true);

        case AluOp::IORLW:
        case AluOp::IORWF:
            return bitwiseOr(input.a, input.b, input.status_in);

        case AluOp::MOVF:
            return move(input.a, input.status_in, true);

        case AluOp::MOVWF:
        case AluOp::MOVLW:
        case AluOp::RETLW:
            return move(input.b, input.status_in, false);

        case AluOp::CALL:
        case AluOp::GOTO:
        case AluOp::RETUR:
        case AluOp::NOP:
            return passthrough(input.a, input.status_in);

        case AluOp::RLF:
            return rotateLeftThroughCarry(input.a, input.status_in);

        case AluOp::RRF:
            return rotateRightThroughCarry(input.a, input.status_in);

        case AluOp::SUBLW:
        case AluOp::SUBWF:
            return sub8(input.a, input.b, input.status_in);

        case AluOp::SWAPF:
            return swapNibbles(input.a, input.status_in);

        case AluOp::XORLW:
        case AluOp::XORWF:
            return bitwiseXor(input.a, input.b, input.status_in);
    }

    return passthrough(input.a, input.status_in);
}

std::uint8_t ALU::normalizeBitIndex(std::uint8_t bit_index) {
    return static_cast<std::uint8_t>(bit_index & 0x07u);
}

std::uint8_t ALU::getBit(std::uint8_t value, std::uint8_t bit_index) {
    const std::uint8_t normalized_index = normalizeBitIndex(bit_index);
    return static_cast<std::uint8_t>((value >> normalized_index) & 0x01u);
}

std::uint8_t ALU::setBit(std::uint8_t value, std::uint8_t bit_index, bool bit_value) {
    const std::uint8_t normalized_index = normalizeBitIndex(bit_index);
    const std::uint8_t mask = static_cast<std::uint8_t>(1u << normalized_index);

    if (bit_value) {
        return static_cast<std::uint8_t>(value | mask);
    }

    return static_cast<std::uint8_t>(value & static_cast<std::uint8_t>(~mask));
}

void ALU::updateZeroFlag(std::uint8_t result, Status& status) {
    status.z = (result == 0u);
}

AluResult ALU::add8(std::uint8_t lhs, std::uint8_t rhs, Status status_in) {
    const std::uint16_t sum = static_cast<std::uint16_t>(lhs) + static_cast<std::uint16_t>(rhs);
    const std::uint8_t result = static_cast<std::uint8_t>(sum & 0x00FFu);
    const bool c = (sum > 0x00FFu);
    const bool dc = (((lhs & 0x0Fu) + (rhs & 0x0Fu)) > 0x0Fu);
    const bool z = (result == 0u);

    Status status = status_in;
    status.c = c;
    status.dc = dc;
    status.z = z;
    return AluResult{result, status, false};
}

AluResult ALU::sub8(std::uint8_t lhs, std::uint8_t rhs, Status status_in) {
    const std::uint8_t result = static_cast<std::uint8_t>(lhs - rhs);

    Status status = status_in;
    status.z = (result == 0u);
    status.c = (lhs >= rhs);
    status.dc = ((lhs & 0x0Fu) >= (rhs & 0x0Fu));

    return AluResult{result, status, false};
}


AluResult ALU::rotateLeftThroughCarry(std::uint8_t value, Status status_in) {
    const bool old_msb = ((value & 0x80u) != 0u);

    std::uint8_t rotated = static_cast<std::uint8_t>(value << 1);

    if (status_in.c) {
        rotated = static_cast<std::uint8_t>(rotated | 0x01u);
    }

    Status status = status_in;
    status.c = old_msb;

    return AluResult{rotated, status, false};
}

AluResult ALU::rotateRightThroughCarry(std::uint8_t value, Status status_in) {
    const bool old_lsb = ((value & 0x01u) != 0u);
    std::uint8_t rotated = static_cast<std::uint8_t> (value >> 1);

    if (status_in.c) {
        rotated = static_cast<std::uint8_t>(rotated | 0x80u);
    }

    Status status = status_in;
    status.c = old_lsb;

    return AluResult{rotated, status, false};
}

AluResult ALU::swapNibbles(std::uint8_t value, Status status_in) {
    std::uint8_t swapped = static_cast<std::uint8_t>((value << 4) | (value>>4));
    return AluResult{swapped, status_in, false};
}

AluResult ALU::clearBit(std::uint8_t value, std::uint8_t bit_index, Status status_in) {
    return AluResult{setBit(value, bit_index, false), status_in, false};
}

AluResult ALU::setBitOp(std::uint8_t value, std::uint8_t bit_index, Status status_in) {
    return AluResult{setBit(value, bit_index, true), status_in, false};
}

AluResult ALU::bitTestSkipIfClear(std::uint8_t value, std::uint8_t bit_index, Status status_in) {
    const bool should_skip = (getBit(value, bit_index) == 0u);
    return AluResult{value, status_in, should_skip};
}

AluResult ALU::bitTestSkipIfSet(std::uint8_t value, std::uint8_t bit_index, Status status_in) {
    const bool should_skip = (getBit(value, bit_index) != 0u);
    return AluResult{value, status_in, should_skip};
}

AluResult ALU::move(std::uint8_t value, Status status_in, bool update_zero_flag) {
    AluResult result{value, status_in, false};

    if (update_zero_flag) {
        updateZeroFlag(result.result, result.status);
    }

    return result;
}

AluResult ALU::clear(Status status_in) {
    AluResult result{0u, status_in, false};
    updateZeroFlag(result.result, result.status);
    return result;
}

AluResult ALU::complement(std::uint8_t value, Status status_in) {
    const std::uint8_t result = static_cast<std::uint8_t>(~value);
    Status status = status_in;
    updateZeroFlag(result, status);
    return AluResult{result, status, false};
}

AluResult ALU::decrement(std::uint8_t value, Status status_in, bool skip_if_zero) {
    const std::uint8_t next_value = static_cast<std::uint8_t>(value - 1u);
    Status status = status_in;

    if (!skip_if_zero) {
        updateZeroFlag(next_value, status);
    }

    return AluResult{next_value, status, skip_if_zero && (next_value == 0u)};
}

AluResult ALU::increment(std::uint8_t value, Status status_in, bool skip_if_zero) {
    const std::uint8_t next_value = static_cast<std::uint8_t>(value + 1u);
    Status status = status_in;

    if (!skip_if_zero) {
        updateZeroFlag(next_value, status);
    }

    return AluResult{next_value, status, skip_if_zero && (next_value == 0u)};
}

AluResult ALU::bitwiseAnd(std::uint8_t lhs, std::uint8_t rhs, Status status_in) {
    const std::uint8_t result = static_cast<std::uint8_t>(lhs & rhs);
    Status status = status_in;
    updateZeroFlag(result, status);
    return AluResult{result, status, false};
}

AluResult ALU::bitwiseOr(std::uint8_t lhs, std::uint8_t rhs, Status status_in) {
    std::uint8_t result = static_cast<std::uint8_t>(lhs | rhs);
    Status status = status_in;
    updateZeroFlag(result, status);
    return AluResult{result, status, false};
}

AluResult ALU::bitwiseXor(std::uint8_t lhs, std::uint8_t rhs, Status status_in) {
    std::uint8_t result = static_cast<std::uint8_t>(lhs ^ rhs);
    Status status = status_in;
    updateZeroFlag(result, status);
    return AluResult{result, status, false};
}

AluResult ALU::passthrough(std::uint8_t value, Status status_in) {
    return AluResult{value, status_in, false};
}

}  // namespace pic16f84a
