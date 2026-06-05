#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <map>
#include <sstream>
#include <iomanip>

// --- Lexer ---
enum TokenType {
    IDENT, NUMBER, PLUS, STAR, ASSIGN, SEMICOLON, END_OF_FILE, UNKNOWN
};

struct Token {
    TokenType type;
    std::string value;
};

class Lexer {
    std::string source;
    size_t pos;
public:
    Lexer(const std::string& src) : source(src), pos(0) {}
    
    Token nextToken() {
        while (pos < source.length() && isspace(source[pos])) pos++;
        if (pos >= source.length()) return {END_OF_FILE, ""};
        
        char c = source[pos];
        if (isalpha(c)) {
            std::string id;
            while (pos < source.length() && (isalnum(source[pos]) || source[pos] == '_')) {
                id += source[pos++];
            }
            return {IDENT, id};
        }
        if (isdigit(c)) {
            std::string num;
            while (pos < source.length() && isdigit(source[pos])) {
                num += source[pos++];
            }
            return {NUMBER, num};
        }
        if (c == '+') { pos++; return {PLUS, "+"}; }
        if (c == '*') { pos++; return {STAR, "*"}; }
        if (c == '=') { pos++; return {ASSIGN, "="}; }
        if (c == ';') { pos++; return {SEMICOLON, ";"}; }
        
        pos++;
        return {UNKNOWN, std::string(1, c)};
    }
};

// --- AST ---
struct ExprNode {
    std::string op;
    std::string left;
    std::string right;
};

struct AssignNode {
    std::string target;
    ExprNode expr;
};

// --- Parser ---
class Parser {
    Lexer& lexer;
    Token currentToken;
    void advance() { currentToken = lexer.nextToken(); }
public:
    Parser(Lexer& lex) : lexer(lex) { advance(); }
    
    std::vector<AssignNode> parse() {
        std::vector<AssignNode> stmts;
        while (currentToken.type != END_OF_FILE) {
            if (currentToken.type == IDENT) {
                AssignNode node;
                node.target = currentToken.value;
                advance();
                if (currentToken.type == ASSIGN) {
                    advance();
                    if (currentToken.type == IDENT || currentToken.type == NUMBER) {
                        node.expr.left = currentToken.value;
                        advance();
                        if (currentToken.type == PLUS || currentToken.type == STAR) {
                            node.expr.op = currentToken.value;
                            advance();
                            if (currentToken.type == IDENT || currentToken.type == NUMBER) {
                                node.expr.right = currentToken.value;
                                advance();
                                if (currentToken.type == SEMICOLON) {
                                    advance();
                                    stmts.push_back(node);
                                } else {
                                    std::cerr << "Parser Error: Expected ';'" << std::endl;
                                }
                            } else {
                                std::cerr << "Parser Error: Expected IDENT or NUMBER" << std::endl;
                            }
                        } else {
                            std::cerr << "Parser Error: Expected '+' or '*'" << std::endl;
                        }
                    } else {
                        std::cerr << "Parser Error: Expected IDENT or NUMBER" << std::endl;
                    }
                } else {
                    advance(); // Skip unexpected tokens
                }
            } else {
                advance(); // Skip unexpected tokens
            }
        }
        return stmts;
    }
};

// --- CodeGen ---
class CodeGen {
    std::map<std::string, uint8_t> symTable;
    uint8_t nextAddr = 0x10; // Start placing variables at address 0x10
    
    uint8_t getAddr(const std::string& var) {
        if (symTable.find(var) == symTable.end()) {
            symTable[var] = nextAddr++;
        }
        return symTable[var];
    }

public:
    std::vector<uint32_t> generate(const std::vector<AssignNode>& stmts) {
        std::vector<uint32_t> instructions;
        // Basic register allocation mapping
        uint8_t R1 = 1, R2 = 2, R3 = 3;
        
        for (const auto& stmt : stmts) {
            uint8_t addr1 = getAddr(stmt.expr.left);
            uint8_t addr2 = getAddr(stmt.expr.right);
            uint8_t addrT = getAddr(stmt.target);
            
            // LOAD R1, addr1  -> Opcode: 0x01 [Dest: R1] [Ignored: 00] [Addr: addr1]
            instructions.push_back((0x01 << 24) | (R1 << 16) | addr1);
            
            // LOAD R2, addr2  -> Opcode: 0x01 [Dest: R2] [Ignored: 00] [Addr: addr2]
            instructions.push_back((0x01 << 24) | (R2 << 16) | addr2);
            
            // ALU OP R3, R1, R2 -> Opcode: 0x03 or 0x04 [Dest: R3] [Src1: R1] [Src2: R2]
            uint8_t opcode = (stmt.expr.op == "+") ? 0x03 : 0x04;
            instructions.push_back((opcode << 24) | (R3 << 16) | (R1 << 8) | R2);
            
            // STORE R3, addrT -> Opcode: 0x02 [Src: R3] [Ignored: 00] [Addr: addrT]
            instructions.push_back((0x02 << 24) | (R3 << 16) | addrT);
        }
        
        // HALT -> Opcode: 0x00
        instructions.push_back(0x00000000);
        return instructions;
    }
    
    void printSymTable() {
        std::cout << "[TitanCC] Symbol Table Mapping:" << std::endl;
        for (const auto& pair : symTable) {
            std::cout << "  " << pair.first << " -> MemAddr: 0x" << std::hex << (int)pair.second << std::dec << std::endl;
        }
    }
};

int main(int argc, char** argv) {
    if (argc < 3) {
        std::cerr << "Usage: " << argv[0] << " <input_kernel.cpp> <output.bin>" << std::endl;
        return 1;
    }
    
    std::ifstream infile(argv[1]);
    if (!infile.is_open()) {
        std::cerr << "Error: Cannot open input file " << argv[1] << std::endl;
        return 1;
    }
    
    std::stringstream buffer;
    buffer << infile.rdbuf();
    std::string source = buffer.str();
    
    std::cout << "[TitanCC] Compiling " << argv[1] << "..." << std::endl;
    
    // Phase 1 & 2: Lexing & Parsing
    Lexer lexer(source);
    Parser parser(lexer);
    auto ast = parser.parse();
    
    if (ast.empty()) {
        std::cerr << "[TitanCC] Warning: No valid statements parsed." << std::endl;
    }
    
    // Phase 3: Code Generation
    CodeGen codegen;
    auto insts = codegen.generate(ast);
    codegen.printSymTable();
    
    // Output
    std::ofstream outfile(argv[2]);
    if (!outfile.is_open()) {
        std::cerr << "Error: Cannot open output file " << argv[2] << std::endl;
        return 1;
    }
    
    for (uint32_t inst : insts) {
        outfile << std::hex << std::setw(8) << std::setfill('0') << inst << std::endl;
    }
    
    std::cout << "[TitanCC] Compilation successful. Hex opcodes generated at " << argv[2] << std::endl;
    return 0;
}
