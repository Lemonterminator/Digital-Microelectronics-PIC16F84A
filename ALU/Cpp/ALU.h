#pragma once

#include <cstdint>

namespace pic16f84a {

// Subset of the PIC16F84A instruction set that is relevant to the ALU exercise.
// The names follow the assignment directly so that later we can map one opcode
// to one switch branch without translating between naming schemes.
enum class AluOp {
    // BYTE-ORIENTED FILE REGISTER OPERATIONS
    // result = f + W, affects C/DC/Z
    ADDWF,
    // result = f & W, affects Z
    ANDWF,

    // LITERAL AND CONTROL OPERATIONS
    // result = W + literal k, affects C/DC/Z
    ADDLW,
    // result = W & literal k, affects Z
    ANDLW,

    // BIT-ORIENTED FILE REGISTER OPERATIONS
    // clear bit b in file register f
    BCF,
    // test bit b in file register f, skip next instruction if clear
    BTFSC,
    // set bit b in file register f
    BSF,
    // test bit b in file register f, skip next instruction if set
    BTFSS,

    // BYTE-ORIENTED FILE REGISTER OPERATIONS
    // clear file register f, affects Z
    CLRF,
    // clear W register, affects Z
    CLRW,
    // result = bitwise complement of f, affects Z
    COMF,
    // result = f - 1, affects Z
    DECF,
    // result = f - 1, skip next instruction if result == 0
    DECFSZ,
    // result = f + 1, affects Z
    INCF,
    // result = f + 1, skip next instruction if result == 0
    INCFSZ,
    // result = W | literal k, affects Z
    IORLW,
    // copy f to destination, affects Z
    MOVF,
    // copy W to file register f, status flags unchanged
    MOVWF,

    // Control-flow instructions are listed here because the assignment's custom
    // enum includes them. In the ALU-only exercise they are placeholders and
    // will normally behave like NOP, since stack/PC updates belong to the CPU
    // control unit rather than combinational ALU logic.
    CALL,
    GOTO,
    // load literal k to W, status flags unchanged
    MOVLW,
    // return with literal in W; stack interaction is outside the ALU
    RETLW,
    // RETURN is named RETUR because return is a C++ keyword only in lowercase?
    // The assignment uses RETUR to mirror the VHDL exercise naming.
    RETUR,
    // result = f | W, affects Z
    IORWF,
    // no operation
    NOP,
    // rotate left through carry, affects C
    RLF,
    // rotate right through carry, affects C
    RRF,
    // result = literal k - W, affects C/DC/Z
    SUBLW,
    // result = f - W, affects C/DC/Z
    SUBWF,
    // swap upper and lower nibble of f, status flags unchanged
    SWAPF,
    // result = W xor literal k, affects Z
    XORLW,
    // result = f xor W, affects Z
    XORWF
};

// PIC status register subset used by the ALU exercise.
// z  = Zero flag
// dc = Digit carry / digit borrow flag (carry from bit 3 to bit 4)
// c  = Carry / borrow flag
//
// We store them as named booleans instead of packing into one byte because the
// later implementation will be easier to read and less error-prone.
struct Status {
    bool z{};
    bool dc{};
    bool c{};
};

// Full combinational ALU input bundle.
//
// a:
//   Usually the file register operand f. For subtraction-style operations this
//   is the minuend, because the ALU core consistently computes a op b.
// b:
//   Usually W or the literal operand k, depending on instruction decoding. For
//   SUBLW specifically, feed b = W and a = literal so the helper performs a-b.
// op:
//   Selected ALU operation from the assignment enum.
// bit_select:
//   Bit index used by bit-oriented instructions. Only the lowest 3 bits matter.
// status_in:
//   Current status register value. Needed especially for rotate-through-carry.
struct AluInput {
    std::uint8_t a{};
    std::uint8_t b{};
    AluOp op{AluOp::NOP};
    std::uint8_t bit_select{};
    Status status_in{};
};

// Full combinational ALU output bundle.
//
// result:
//   8-bit output value of the ALU.
// status:
//   Next value of the status bits managed by the ALU.
// skip_next:
//   Helper signal for instructions such as DECFSZ, INCFSZ, BTFSC, BTFSS.
//   This is not part of the original ALU entity from the VHDL exercise, but it
//   is useful in the C++ model because it lets the ALU report control intent
//   without owning the program counter.
struct AluResult {
    std::uint8_t result{};
    Status status{};
    bool skip_next{};
};

class ALU {
public:
    // Main entry point for the ALU model.
    // This function will remain purely combinational: it reads one input bundle
    // and returns one output bundle with no internal state.
    static AluResult execute(const AluInput& input);

private:
    // The exercise models bit_select as a 3-bit signal. This helper keeps the
    // software model aligned with that contract even though the C++ field is
    // stored in a full byte.
    static std::uint8_t normalizeBitIndex(std::uint8_t bit_index);

    // Read one bit from an 8-bit value.
    // bit_index is expected to be in [0, 7].
    static std::uint8_t getBit(std::uint8_t value, std::uint8_t bit_index);

    // Return a copy of value with one selected bit replaced.
    static std::uint8_t setBit(std::uint8_t value, std::uint8_t bit_index, bool bit_value);

    // Update only the Z flag according to whether result equals zero.
    // Other flags are preserved.
    static void updateZeroFlag(std::uint8_t result, Status& status);

    // 8-bit addition helpers for ADDWF and ADDLW.
    // These functions will compute the arithmetic result and the PIC flags:
    // C  = carry out from bit 7
    // DC = carry out from bit 3
    // Z  = result equals zero
    static AluResult add8(std::uint8_t lhs, std::uint8_t rhs, Status status_in);

    // 8-bit subtraction helpers for SUBWF and SUBLW.
    // PIC subtraction semantics are a little special:
    // C  = 1 means no borrow
    // DC = 1 means no borrow from bit 4
    // Z  = result equals zero
    static AluResult sub8(std::uint8_t lhs, std::uint8_t rhs, Status status_in);

    // Rotate left/right through the carry flag.
    // The incoming carry is taken from status_in.c and the outgoing carry is the
    // bit shifted out of the operand.
    static AluResult rotateLeftThroughCarry(std::uint8_t value, Status status_in);
    static AluResult rotateRightThroughCarry(std::uint8_t value, Status status_in);

    // Swap upper and lower 4-bit nibbles. Status flags are normally unchanged.
    static AluResult swapNibbles(std::uint8_t value, Status status_in);

    // Bit-oriented helpers.
    // BCF/BSF modify the selected bit in the result.
    // BTFSC/BTFSS keep the original value but may assert skip_next.
    static AluResult clearBit(std::uint8_t value, std::uint8_t bit_index, Status status_in);
    static AluResult setBitOp(std::uint8_t value, std::uint8_t bit_index, Status status_in);
    static AluResult bitTestSkipIfClear(std::uint8_t value, std::uint8_t bit_index, Status status_in);
    static AluResult bitTestSkipIfSet(std::uint8_t value, std::uint8_t bit_index, Status status_in);

    // Data movement and simple unary operations.
    // move(..., true) is useful for MOVF because MOVF affects Z.
    // move(..., false) is useful for MOVWF/MOVLW style operations that should
    // preserve the incoming status flags.
    static AluResult move(std::uint8_t value, Status status_in, bool update_zero_flag);

    // CLRF / CLRW clear the output value to zero.
    static AluResult clear(Status status_in);

    // COMF computes the one's complement of the operand and updates Z.
    static AluResult complement(std::uint8_t value, Status status_in);

    // DECF / DECFSZ and INCF / INCFSZ share core arithmetic. On PIC16F84A the
    // skip variants do not update status bits, while DECF/INCF update only Z.
    static AluResult decrement(std::uint8_t value, Status status_in, bool skip_if_zero);
    static AluResult increment(std::uint8_t value, Status status_in, bool skip_if_zero);

    // Logic operations that update only Z in the PIC status subset used here.
    static AluResult bitwiseAnd(std::uint8_t lhs, std::uint8_t rhs, Status status_in);
    static AluResult bitwiseOr(std::uint8_t lhs, std::uint8_t rhs, Status status_in);
    static AluResult bitwiseXor(std::uint8_t lhs, std::uint8_t rhs, Status status_in);

    // Generic placeholder used by NOP and by control-flow instructions that are
    // outside the scope of this ALU-only exercise. The value is forwarded so
    // the datapath stays non-destructive in the software model.
    static AluResult passthrough(std::uint8_t value, Status status_in);
};

}  // namespace pic16f84a
