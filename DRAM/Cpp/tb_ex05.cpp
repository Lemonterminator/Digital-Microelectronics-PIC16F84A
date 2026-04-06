#include "dram.h"

#include <array>
#include <cstddef>
#include <exception>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <string_view>

namespace {

using pic16f84a::AluOp;
using pic16f84a::Status;
using pic16f84a::TopLevelInput;
using pic16f84a::TopLevelOutput;
using pic16f84a::TopLevelAluMem;

struct ProgramRow {
    std::size_t line_number{};
    std::string op_name{};
    TopLevelInput input{};
};

constexpr std::array<std::pair<std::string_view, AluOp>, 32> kOpTable{{
    {"ADDWF", AluOp::ADDWF},
    {"ANDWF", AluOp::ANDWF},
    {"ADDLW", AluOp::ADDLW},
    {"ANDLW", AluOp::ANDLW},
    {"BCF", AluOp::BCF},
    {"BTFSC", AluOp::BTFSC},
    {"BSF", AluOp::BSF},
    {"BTFSS", AluOp::BTFSS},
    {"CLRF", AluOp::CLRF},
    {"CLRW", AluOp::CLRW},
    {"COMF", AluOp::COMF},
    {"DECF", AluOp::DECF},
    {"DECFSZ", AluOp::DECFSZ},
    {"INCF", AluOp::INCF},
    {"INCFSZ", AluOp::INCFSZ},
    {"IORLW", AluOp::IORLW},
    {"MOVF", AluOp::MOVF},
    {"MOVWF", AluOp::MOVWF},
    {"CALL", AluOp::CALL},
    {"GOTO", AluOp::GOTO},
    {"MOVLW", AluOp::MOVLW},
    {"RETLW", AluOp::RETLW},
    {"RETUR", AluOp::RETUR},
    {"IORWF", AluOp::IORWF},
    {"NOP", AluOp::NOP},
    {"RLF", AluOp::RLF},
    {"RRF", AluOp::RRF},
    {"SUBLW", AluOp::SUBLW},
    {"SUBWF", AluOp::SUBWF},
    {"SWAPF", AluOp::SWAPF},
    {"XORLW", AluOp::XORLW},
    {"XORWF", AluOp::XORWF},
}};

std::string trimComment(const std::string& line) {
    const std::size_t comment_pos = line.find('#');
    const std::string without_comment = line.substr(0, comment_pos);
    const std::size_t first = without_comment.find_first_not_of(" \t\r\n");

    if (first == std::string::npos) {
        return "";
    }

    const std::size_t last = without_comment.find_last_not_of(" \t\r\n");
    return without_comment.substr(first, last - first + 1u);
}

AluOp parseOp(const std::string& token) {
    for (const auto& [name, op] : kOpTable) {
        if (name == token) {
            return op;
        }
    }

    throw std::runtime_error("unknown operation: " + token);
}

std::uint8_t parseByte(const std::string& token, const char* field_name) {
    std::size_t parsed_chars = 0;
    const unsigned long value = std::stoul(token, &parsed_chars, 0);

    if (parsed_chars != token.size() || value > 0xFFu) {
        throw std::runtime_error(std::string("invalid 8-bit value for ") + field_name + ": " + token);
    }

    return static_cast<std::uint8_t>(value);
}

bool parseBool01(const std::string& token, const char* field_name) {
    if (token == "0") {
        return false;
    }

    if (token == "1") {
        return true;
    }

    throw std::runtime_error(std::string("invalid boolean value for ") + field_name + ": " + token);
}

std::uint8_t parseBitSelect(const std::string& token) {
    std::size_t parsed_chars = 0;
    const unsigned long value = std::stoul(token, &parsed_chars, 0);

    if (parsed_chars != token.size() || value > 7u) {
        throw std::runtime_error("invalid bit_select value: " + token);
    }

    return static_cast<std::uint8_t>(value);
}

std::string formatByte(std::uint8_t value) {
    std::ostringstream stream;
    stream << "0x"
           << std::uppercase << std::hex << std::setw(2) << std::setfill('0')
           << static_cast<unsigned int>(value);
    return stream.str();
}

std::string formatStatus(const Status& status) {
    std::string bits;
    bits += status.z ? '1' : '0';
    bits += status.dc ? '1' : '0';
    bits += status.c ? '1' : '0';
    return bits;
}

ProgramRow parseProgramRow(const std::string& line, std::size_t line_number) {
    std::istringstream stream(line);
    std::string op_token;
    std::string w_token;
    std::string addr_token;
    std::string re_token;
    std::string we_token;
    std::string bit_token;

    if (!(stream >> op_token >> w_token >> addr_token >> re_token >> we_token >> bit_token)) {
        throw std::runtime_error("expected 6 fields: op w_in addr mem_re mem_we bit_select");
    }

    std::string extra_token;
    if (stream >> extra_token) {
        throw std::runtime_error("too many fields on line");
    }

    return ProgramRow{
        line_number,
        op_token,
        TopLevelInput{
            true,
            parseByte(addr_token, "addr"),
            parseOp(op_token),
            parseByte(w_token, "w_in"),
            parseBool01(re_token, "mem_re"),
            parseBool01(we_token, "mem_we"),
            parseBitSelect(bit_token),
        },
    };
}

void writeHeader(std::ofstream& output) {
    output << "# output_format: index op w_in addr mem_re mem_we mem_before alu_result alu_status skip mem_after\n";
    output << "# STATUS register is mirrored at address 0x03 using packed ZDC bits.\n";
}

}  // namespace

int main(int argc, char* argv[]) {
    const std::string input_path = (argc > 1) ? argv[1] : "input_ex05.txt";
    const std::string output_path = (argc > 2) ? argv[2] : "output_ex05.txt";

    std::ifstream input(input_path);
    if (!input) {
        std::cerr << "Failed to open input file: " << input_path << '\n';
        return 1;
    }

    std::ofstream output(output_path);
    if (!output) {
        std::cerr << "Failed to open output file: " << output_path << '\n';
        return 1;
    }

    writeHeader(output);

    TopLevelAluMem dut;
    dut.preloadStatus(Status{false, false, false});
    dut.preloadMemory(0x10u, 0x12u);
    dut.preloadMemory(0x11u, 0x34u);
    dut.preloadMemory(0x12u, 0x56u);
    dut.preloadMemory(0x14u, 0x56u);
    dut.preloadMemory(0x15u, 0xA0u);
    dut.preloadMemory(0x16u, 0x0Fu);
    dut.preloadMemory(0x17u, 0x01u);
    dut.preloadMemory(0x18u, 0x55u);
    dut.preloadMemory(0x19u, 0x80u);
    dut.preloadMemory(0x1Au, 0x0Fu);
    dut.preloadMemory(0x1Bu, 0xF0u);
    dut.preloadMemory(0x1Cu, 0xAAu);

    std::size_t executed_rows = 0;
    std::string raw_line;
    std::size_t line_number = 0;

    while (std::getline(input, raw_line)) {
        ++line_number;
        const std::string line = trimComment(raw_line);

        if (line.empty()) {
            continue;
        }

        try {
            const ProgramRow row = parseProgramRow(line, line_number);
            const TopLevelOutput result = dut.cycle(row.input);

            output << std::setw(2) << executed_rows
                   << ' ' << row.op_name
                   << ' ' << formatByte(row.input.w_in)
                   << ' ' << formatByte(row.input.addr)
                   << ' ' << (row.input.mem_re ? '1' : '0')
                   << ' ' << (row.input.mem_we ? '1' : '0')
                   << ' ' << formatByte(result.mem_before)
                   << ' ' << formatByte(result.alu_result)
                   << ' ' << formatStatus(result.alu_status)
                   << ' ' << (result.skip_next ? '1' : '0')
                   << ' ' << formatByte(result.mem_data_out)
                   << '\n';

            ++executed_rows;
        } catch (const std::exception& ex) {
            std::cerr << "Parse/execute error on line " << line_number << ": " << ex.what() << '\n';
            return 2;
        }
    }

    output << "# summary rows=" << executed_rows << '\n';

    std::cout << "Executed " << executed_rows
              << " DRAM skeleton rows and wrote " << output_path << '\n';
    return 0;
}
