#include "dram.h"

namespace {

std::uint8_t packStatus(const pic16f84a::Status& status) {
    std::uint8_t value = 0u;
    if (status.z) {
        value |= 0x04u;
    }
    if (status.dc) {
        value |= 0x02u;
    }
    if (status.c) {
        value |= 0x01u;
    }
    return value;
}

pic16f84a::Status unpackStatus(std::uint8_t value) {
    return pic16f84a::Status{
        (value & 0x04u) != 0u,
        (value & 0x02u) != 0u,
        (value & 0x01u) != 0u,
    };
}

}  // namespace


namespace pic16f84a {

std::uint8_t Dpram::normalizeAddr(std::uint8_t addr) {
    return static_cast<std::uint8_t>(addr & 0x7Fu);
}

void Dpram::setInput(const DpramInput& input) {
    input_ = input;
}

const DpramOutput& Dpram::output() const {
    return output_;
}

void Dpram::evalRead() {
    output_.q_status = status_reg_;

    if (input_.re) {
        const std::size_t index = static_cast<std::size_t>(normalizeAddr(input_.addr));
        output_.q = memory_.at(index);
    } else {
        output_.q = 0u;
    }
}


void Dpram::tickRising() {
    const bool is_rising_edge = (!prev_clk_ && input_.clk);
    prev_clk_ = input_.clk;

    if (!is_rising_edge || !input_.we) {
        return;
    }

    const std::size_t index = static_cast<std::size_t>(normalizeAddr(input_.addr));

    // Normal memory write path always writes the data byte.
    memory_.at(index) = input_.d;

    if (index == kStatusAddr) {
        // Address 0x03 is the STATUS register. When both sources target it,
        // the normal data input d has precedence, so the dedicated status
        // register must reflect input_.d rather than input_.d_status.
        status_reg_ = unpackStatus(input_.d);
    } else {
        // For other addresses, the dedicated status path updates STATUS.
        status_reg_ = input_.d_status;
        memory_.at(kStatusAddr) = packStatus(status_reg_);
    }
}


void Dpram::loadByte(std::uint8_t addr, std::uint8_t value) {
    // Testbench helper for preloading memory contents before a cycle-based run.
    memory_.at(static_cast<std::size_t>(normalizeAddr(addr))) = value;
}

void Dpram::loadStatus(const Status& status) {
    // Testbench helper for preloading the dedicated status register.
    status_reg_ = status;
    memory_.at(kStatusAddr) = packStatus(status_reg_);
}

std::uint8_t TopLevelAluMem::normalizeBitSelect(std::uint8_t bit_select) {
    return static_cast<std::uint8_t>(bit_select & 0x07u);
}

void TopLevelAluMem::setInput(const TopLevelInput& input) {
    input_ = input;
}

void TopLevelAluMem::evalCombinational() {
    // Phase 1: present the current memory-side control signals.
    dpram_.setInput(DpramInput{
        input_.clk,
        input_.mem_we,
        input_.mem_re,
        0u,
        {},
        Dpram::normalizeAddr(input_.addr),
    });

    // Phase 2: evaluate the memory read side so the ALU can consume q/q_status.
    dpram_.evalRead();
    last_mem_before_ = dpram_.output().q;

    // Phase 3: wire the top-level datapath into the existing ALU model.
    //   ALU.a         <- w_in
    //   ALU.b         <- memory q
    //   ALU.status_in <- memory q_status
    last_alu_ = ALU::execute(AluInput{
        input_.w_in,
        dpram_.output().q,
        input_.op,
        normalizeBitSelect(input_.bit_select),
        dpram_.output().q_status,
    });

    // Phase 4: stage the ALU outputs back toward memory.
    // In ex06, the controller FSM will own the meaning of mem_we/re and will
    // drive them per state. The reserved names in dram.h are documented so the
    // eventual state-machine ports line up with this datapath bundle.
    dpram_.setInput(DpramInput{
        input_.clk,
        input_.mem_we,
        input_.mem_re,
        last_alu_.result,
        last_alu_.status,
        Dpram::normalizeAddr(input_.addr),
    });

    output_.mem_before = last_mem_before_;
    output_.mem_data_out = dpram_.output().q;
    output_.alu_result = last_alu_.result;
    output_.alu_status = last_alu_.status;
    output_.skip_next = last_alu_.skip_next;
}

void TopLevelAluMem::tickRising() {
    // ex05 commit point.
    // ex06 will keep this synchronous boundary, but the controller FSM will
    // decide when an instruction reaches write-back and when instr_ret should
    // be raised.
    dpram_.tickRising();

    // Re-run the read side so mem_data_out can reflect the post-edge state once
    // real memory behavior is added.
    dpram_.evalRead();
    output_.mem_data_out = dpram_.output().q;
}

TopLevelOutput TopLevelAluMem::cycle(const TopLevelInput& input) {
    // One full clocked cycle for the prototype:
    //   1. Hold clk low and evaluate the combinational datapath.
    //   2. Raise clk and evaluate again so the staged write-back is committed
    //      on a genuine 0->1 transition inside DPRAM.
    TopLevelInput low_phase = input;
    low_phase.clk = false;
    setInput(low_phase);
    evalCombinational();
    tickRising();

    TopLevelInput high_phase = input;
    high_phase.clk = true;
    setInput(high_phase);
    evalCombinational();
    tickRising();

    return output_;
}

void TopLevelAluMem::preloadMemory(std::uint8_t addr, std::uint8_t value) {
    dpram_.loadByte(addr, value);
}

void TopLevelAluMem::preloadStatus(const Status& status) {
    dpram_.loadStatus(status);
}

const TopLevelOutput& TopLevelAluMem::output() const {
    return output_;
}

const DpramOutput& TopLevelAluMem::memoryOutput() const {
    return dpram_.output();
}

}  // namespace pic16f84a
