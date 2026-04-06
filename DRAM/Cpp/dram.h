#pragma once

#include <array>
#include <cstddef>
#include <cstdint>

#include "../../ALU/Cpp/ALU.h"

namespace pic16f84a {

// Narrow-width helpers:
// these wrappers keep the software model close to the VHDL port widths without
// forcing the ex05 prototype to implement the full ex06 controller yet.
struct Addr7 {
    std::uint8_t value{};
};

struct BitSelect3 {
    std::uint8_t value{};
};

struct Literal8 {
    std::uint8_t value{};
};

struct Pc13 {
    std::uint16_t value{};
};

// Reserved for ex06:
// the controller FSM will step through IFetch, MRead, Execute and MWrite.
// The ex05 model does not use these states yet, but keeping the names here
// makes the future controller-side API easier to align with the assignment.
enum class ControllerStage {
    IFetch,
    MRead,
    Execute,
    MWrite,
};

// Reserved for ex06:
// status writes are normally sourced from the ALU result, but instructions that
// target STATUS directly can override that path. This mirrors the VHDL exercise
// requirement to mark such cases explicitly with assertions later on.
enum class StatusWriteMode {
    Preserve,
    FromAlu,
    OverrideFromWriteData,
};

// Reserved for ex06:
// this bundle mirrors the state-machine output ports described in the next
// assignment. It is intentionally not wired into the ex05 model yet.
struct ControllerSignals {
    AluOp op{AluOp::NOP};
    std::uint8_t data{};
    Addr7 addr{};
    BitSelect3 bit_select{};
    Pc13 pc{};
    bool we_mem{};
    bool re_mem{};
    bool we_w{};
    bool instr_ret{};
};

// Reserved for ex06:
// this bundle is the natural place to hold one decoded instruction and the
// controller decisions derived from it. It stays as documentation scaffolding
// for now, because the current prototype still receives already-decoded ALU
// inputs from the testbench.
struct DecodedInstruction {
    AluOp alu_op{AluOp::NOP};
    Addr7 file_addr{};
    BitSelect3 bit_select{};
    Literal8 literal{};
    bool destination_is_file{};
    bool needs_memory_read{};
    bool writes_memory{};
    bool writes_w{};
    bool instruction_complete{};
    StatusWriteMode status_write_mode{StatusWriteMode::Preserve};
};

// VHDL dpram input bundle for ex05.
// d_status is kept as named flags because the ALU already produces Status in
// that form. The DPRAM implementation packs/unpacks it when mirroring STATUS at
// address 0x03, exactly like the VHDL model.
struct DpramInput {
    bool clk{};
    bool we{};
    bool re{};
    std::uint8_t d{};
    Status d_status{};
    std::uint8_t addr{};
};

// VHDL dpram output bundle for ex05.
// q corresponds to the 8-bit read data bus and q_status is the dedicated
// 3-flag STATUS side channel consumed by the ALU.
struct DpramOutput {
    std::uint8_t q{};
    Status q_status{};
};

// Top-level datapath stimulus for ex05.
// This is intentionally a thin ALU+memory bundle, not a full instruction word.
// For ex06 the preferred replacement is:
//   opcode -> DecodedInstruction -> ControllerSignals -> datapath inputs
struct TopLevelInput {
    bool clk{};
    std::uint8_t addr{};
    AluOp op{AluOp::NOP};
    std::uint8_t w_in{};
    bool mem_re{};
    bool mem_we{};
    std::uint8_t bit_select{};
};

// Observable trace from one ex05 cycle.
// mem_before and alu_result are testbench-friendly observability signals. The
// future controller model can keep them in a trace structure even if the VHDL
// top-level ports only expose a smaller architectural interface.
struct TopLevelOutput {
    std::uint8_t mem_before{};
    std::uint8_t mem_data_out{};
    std::uint8_t alu_result{};
    Status alu_status{};
    bool skip_next{};
};

// Dual-port RAM model matching DRAM/VHDL/dpram.vhd.
// Key rule: STATUS exists both as a dedicated flag register and as a mirrored
// packed byte at address 0x03. Both representations must remain in sync.
class Dpram {
public:
    static constexpr std::uint8_t kStatusAddr = 0x03u;
    static constexpr std::size_t kDepth = 128u;
    static std::uint8_t normalizeAddr(std::uint8_t addr);

    void setInput(const DpramInput& input);
    const DpramOutput& output() const;

    void evalRead();
    void tickRising();

    void loadByte(std::uint8_t addr, std::uint8_t value);
    void loadStatus(const Status& status);

private:
    std::array<std::uint8_t, kDepth> memory_{};
    Status status_reg_{};
    DpramInput input_{};
    DpramOutput output_{};
    bool prev_clk_{};
};

// ex05 top-level prototype:
// wires W input, ALU, and DPRAM together for a single memory-oriented datapath
// experiment. It is not the ex06 controller yet.
//
// Reserved naming for the next step:
// - input_.addr      -> future controller addr output
// - input_.mem_re    -> future re_mem
// - input_.mem_we    -> future we_mem
// - input_.bit_select-> future bit_select
// - output_.skip_next-> future control-flow hint after Execute
class TopLevelAluMem {
public:
    void setInput(const TopLevelInput& input);

    void evalCombinational();
    void tickRising();
    TopLevelOutput cycle(const TopLevelInput& input);

    void preloadMemory(std::uint8_t addr, std::uint8_t value);
    void preloadStatus(const Status& status);

    const TopLevelOutput& output() const;
    const DpramOutput& memoryOutput() const;

private:
    static std::uint8_t normalizeBitSelect(std::uint8_t bit_select);

    Dpram dpram_{};
    TopLevelInput input_{};
    TopLevelOutput output_{};
    AluResult last_alu_{};
    std::uint8_t last_mem_before_{};
};

}  // namespace pic16f84a
