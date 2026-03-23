#include "ALU.h"

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

using pic16f84a::ALU;
using pic16f84a::AluInput;
using pic16f84a::AluOp;
using pic16f84a::AluResult;
using pic16f84a::Status;

struct ProgramRow {
    std::size_t line_number{};
    AluInput input{};
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

std::string_view toString(AluOp op) {
    for (const auto& [name, table_op] : kOpTable) {
        if (table_op == op) {
            return name;
        }
    }

    return "UNKNOWN";
}

std::uint8_t parseByte(const std::string& token, const char* field_name) {
    std::size_t parsed_chars = 0;
    const unsigned long value = std::stoul(token, &parsed_chars, 0);

    if (parsed_chars != token.size() || value > 0xFFu) {
        throw std::runtime_error(std::string("invalid 8-bit value for ") + field_name + ": " + token);
    }

    return static_cast<std::uint8_t>(value);
}

std::uint8_t parseBitSelect(const std::string& token) {
    std::size_t parsed_chars = 0;
    const unsigned long value = std::stoul(token, &parsed_chars, 0);

    if (parsed_chars != token.size() || value > 7u) {
        throw std::runtime_error("invalid bit_select value: " + token);
    }

    return static_cast<std::uint8_t>(value);
}

Status parseStatus(const std::string& token) {
    if (token.size() != 3u) {
        throw std::runtime_error("status must use exactly 3 bits in ZDC order: " + token);
    }

    for (char ch : token) {
        if (ch != '0' && ch != '1') {
            throw std::runtime_error("status must contain only 0/1 digits: " + token);
        }
    }

    return Status{
        token[0] == '1',
        token[1] == '1',
        token[2] == '1',
    };
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
    std::string a_token;
    std::string b_token;
    std::string bit_token;
    std::string status_token;

    if (!(stream >> op_token >> a_token >> b_token >> bit_token >> status_token)) {
        throw std::runtime_error("expected 5 fields: op a b bit_select status_in");
    }

    std::string extra_token;
    if (stream >> extra_token) {
        throw std::runtime_error("too many fields on line");
    }

    return ProgramRow{
        line_number,
        AluInput{
            parseByte(a_token, "a"),
            parseByte(b_token, "b"),
            parseOp(op_token),
            parseBitSelect(bit_token),
            parseStatus(status_token),
        },
    };
}

void writeHeader(std::ofstream& output) {
    output << "# output_format: index op a b bit_select status_in result status_out skip_next\n";
    output << "# status bits use ZDC order\n";
}

}  // namespace

int main(int argc, char* argv[]) {
    const std::string input_path = (argc > 1) ? argv[1] : "input_ex04.txt";
    const std::string output_path = (argc > 2) ? argv[2] : "output_ex04.txt";

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

    std::array<bool, kOpTable.size()> covered_ops{};
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
            const AluResult result = ALU::execute(row.input);
            covered_ops.at(static_cast<std::size_t>(row.input.op)) = true;

            output << std::setw(2) << executed_rows
                   << ' ' << toString(row.input.op)
                   << ' ' << formatByte(row.input.a)
                   << ' ' << formatByte(row.input.b)
                   << ' ' << static_cast<unsigned int>(row.input.bit_select)
                   << ' ' << formatStatus(row.input.status_in)
                   << ' ' << formatByte(result.result)
                   << ' ' << formatStatus(result.status)
                   << ' ' << (result.skip_next ? '1' : '0')
                   << '\n';

            ++executed_rows;
        } catch (const std::exception& ex) {
            std::cerr << "Parse/execute error on line " << line_number << ": " << ex.what() << '\n';
            return 2;
        }
    }

    bool missing_ops = false;
    for (std::size_t index = 0; index < covered_ops.size(); ++index) {
        if (!covered_ops[index]) {
            missing_ops = true;
            std::cerr << "Missing test case for operation " << toString(static_cast<AluOp>(index)) << '\n';
        }
    }

    output << "# summary rows=" << executed_rows
           << " covered_ops=";

    std::size_t covered_count = 0;
    for (bool covered : covered_ops) {
        covered_count += covered ? 1u : 0u;
    }

    output << covered_count << '/' << covered_ops.size() << '\n';

    if (missing_ops) {
        return 3;
    }

    std::cout << "Executed " << executed_rows
              << " ALU test rows and wrote " << output_path << '\n';
    return 0;
}
