//! Tokenizer is reponsible for reading the source files
//! and turning them into a stream of (will, as the name suggest) tokens.
//! NOTE: the current implementation uses an array list to return
//! the scanned tokens. it is not very efficiant approach and make the api
//! hard to use. i am planning to implement it in a way, that it does not
//! allocate memory during the scanning process (the same approach is used
//! by zig tokenizer)

const std = @import("std");
const panic = @import("../utils.zig").panic;
const eq = std.mem.eql;

/// represent all possible token types
const TokenType = enum {
    LEFT_PAREN,
    RIGHT_PAREN,
    LEFT_BRACE,
    RIGHT_BRACE,
    COMMA,
    DOT,
    MINUS,
    PLUS,
    SIMICOLON,
    SLASH,
    STAR,
    BANG,
    BANG_EQUAL,
    EQUAL,
    EQUAL_EQUAL,
    GREATER,
    GREATER_EQUAL,
    LESS,
    LESS_EQUAL,
    IDENTIFIER,
    STRING,
    NUMBER,
    NIL,
    TRUE,
    FALSE,
    AND,
    OR,
    IF,
    ELSE,
    FOR,
    WHILE,
    VAR,
    FN,
    RETURN,
    CLASS,
    THIS,
    SUPER,
    PRINT,
    EOF,
};

/// token represent a group of characters (also called
/// lexeme) mapped to specific type
const Token = struct {
    token_type: TokenType,
    lexeme: []const u8,
    line: u32,
};

/// Tokenizer Error
const SyntaxError = error{
    SomeError,
};

// TODO: reimplement it using the same strategy used by the zig tokenizer (zero allocation)
pub fn scan(tokens: *std.ArrayList(Token), source: []const u8) !void {
    var line: u32 = 1;
    var current: u32 = 0;
    var start: u32 = 0;

    while (current < source.len) : (current += 1) {
        start = current;
        const token: ?Token = switch (source[current]) {
            ' ', '\r', '\t' => null,
            '\n' => blk: {
                line += 1;
                break :blk null;
            },
            '(' => .{ .line = line, .lexeme = source[start .. current + 1], .token_type = .LEFT_PAREN },
            ')' => .{ .line = line, .lexeme = source[start .. current + 1], .token_type = .RIGHT_PAREN },
            '{' => .{ .line = line, .lexeme = source[start .. current + 1], .token_type = .LEFT_BRACE },
            '}' => .{ .line = line, .lexeme = source[start .. current + 1], .token_type = .RIGHT_BRACE },
            ',' => .{ .line = line, .lexeme = source[start .. current + 1], .token_type = .COMMA },
            '.' => .{ .line = line, .lexeme = source[start .. current + 1], .token_type = .DOT },
            '-' => .{ .line = line, .lexeme = source[start .. current + 1], .token_type = .MINUS },
            '+' => .{ .line = line, .lexeme = source[start .. current + 1], .token_type = .PLUS },
            ';' => .{ .line = line, .lexeme = source[start .. current + 1], .token_type = .SIMICOLON },
            '*' => .{ .line = line, .lexeme = source[start .. current + 1], .token_type = .STAR },
            '!' => blk: {
                if ((current + 1 < source.len) and (source[current + 1] == '=')) {
                    current += 1;
                    break :blk .{
                        .line = line,
                        .lexeme = source[start .. current + 1],
                        .token_type = .BANG_EQUAL,
                    };
                }
                break :blk .{
                    .line = line,
                    .lexeme = source[start .. current + 1],
                    .token_type = .BANG,
                };
            },
            '=' => blk: {
                if ((current + 1 < source.len) and (source[current + 1] == '=')) {
                    current += 1;
                    break :blk .{
                        .line = line,
                        .lexeme = source[start .. current + 1],
                        .token_type = .EQUAL_EQUAL,
                    };
                }
                break :blk .{
                    .line = line,
                    .lexeme = source[start .. current + 1],
                    .token_type = .EQUAL,
                };
            },
            '<' => blk: {
                if ((current + 1 < source.len) and (source[current + 1] == '=')) {
                    current += 1;
                    break :blk .{
                        .line = line,
                        .lexeme = source[start .. current + 1],
                        .token_type = .LESS_EQUAL,
                    };
                }
                break :blk .{
                    .line = line,
                    .lexeme = source[start .. current + 1],
                    .token_type = .LESS,
                };
            },
            '>' => blk: {
                if ((current + 1 < source.len) and (source[current + 1] == '=')) {
                    current += 1;
                    break :blk .{
                        .line = line,
                        .lexeme = source[start .. current + 1],
                        .token_type = .GREATER_EQUAL,
                    };
                }
                break :blk .{
                    .line = line,
                    .lexeme = source[start .. current + 1],
                    .token_type = .GREATER,
                };
            },
            '/' => blk: {
                if ((current + 1 < source.len) and (source[current + 1] == '/')) {
                    current += 1;
                    while ((current + 1 < source.len) and (source[current + 1] != '\n')) : (current += 1) {}
                    break :blk null;
                } else {
                    break :blk .{
                        .line = line,
                        .lexeme = source[start .. current + 1],
                        .token_type = .SLASH,
                    };
                }
            },
            '"' => blk: {
                while (true) {
                    if ((current + 1 >= source.len) or (source[current + 1] == '\n')) {
                        break :blk null;
                    } else if (source[current + 1] == '"') {
                        // trim the surrounding qoutes (string lexem is the content of the string without the quouts)
                        current += 1;
                        break :blk Token{ .line = line, .lexeme = source[start + 1 .. current], .token_type = .STRING };
                    }
                    current += 1;
                }
            },
            '0'...'9' => blk: {
                while (current + 1 < source.len and source[current + 1] >= '0' and source[current + 1] <= '9') : (current += 1) {}

                // if the number contains dot we continue
                if (current + 1 < source.len and source[current + 1] == '.' and source[current + 2] >= '0' and source[current + 2] <= '9') {
                    current += 1;
                } else {
                    break :blk Token{ .line = line, .lexeme = source[start .. current + 1], .token_type = .NUMBER };
                }

                while (current + 1 < source.len and source[current + 1] >= '0' and source[current + 1] <= '9') : (current += 1) {}
                break :blk Token{ .line = line, .lexeme = source[start .. current + 1], .token_type = .NUMBER };
            },
            'a'...'z', 'A'...'Z', '_' => blk: {
                _ = subblk: while (current + 1 < source.len) : (current += 1) {
                    switch (source[current + 1]) {
                        'a'...'z', 'A'...'Z', '0'...'9', '_' => continue,
                        else => break :subblk,
                    }
                };
                // use hashmap or find a better way to do it in zig
                const k = source[start .. current + 1];
                const tokenType = if (eq(u8, k, "and"))
                    TokenType.AND
                else if (eq(u8, k, "or"))
                    TokenType.OR
                else if (eq(u8, k, "true"))
                    TokenType.TRUE
                else if (eq(u8, k, "false"))
                    TokenType.FALSE
                else if (eq(u8, k, "nil"))
                    TokenType.NIL
                else if (eq(u8, k, "if"))
                    TokenType.IF
                else if (eq(u8, k, "else"))
                    TokenType.ELSE
                else if (eq(u8, k, "while"))
                    TokenType.WHILE
                else if (eq(u8, k, "for"))
                    TokenType.FOR
                else if (eq(u8, k, "var"))
                    TokenType.VAR
                else if (eq(u8, k, "fn"))
                    TokenType.FN
                else if (eq(u8, k, "return"))
                    TokenType.RETURN
                else if (eq(u8, k, "class"))
                    TokenType.CLASS
                else if (eq(u8, k, "this"))
                    TokenType.THIS
                else if (eq(u8, k, "super"))
                    TokenType.SUPER
                else if (eq(u8, k, "print"))
                    TokenType.PRINT
                else
                    TokenType.IDENTIFIER;
                break :blk Token{ .line = line, .lexeme = k, .token_type = tokenType };
            },
            else => {
                // TODO: how to handle errors
                // std.log.err("unexpected character in line {}", .{line});
                continue;
            },
        };

        if (token) |t| {
            try tokens.append(t);
        }
    }

    // at end of the file add the eof token
    try tokens.append(.{
        .token_type = .EOF,
        .lexeme = "",
        .line = line,
    });
}

fn testTokenizer(source: []const u8, expected: []const Token) !void {
    var tokens = std.ArrayList(Token).init(std.testing.allocator);
    defer tokens.deinit();
    try scan(&tokens, source);
    try std.testing.expectEqualDeep(expected, tokens.items);
}

test "empty" {
    try testTokenizer("", &[_]Token{
        Token{ .line = 1, .lexeme = "", .token_type = .EOF },
    });
}

test "unknown characters should be ignored" {
    try testTokenizer("@", &[_]Token{
        Token{ .line = 1, .lexeme = "", .token_type = .EOF },
    });
}

test "scan single characters lexemes" {
    try testTokenizer("!(){}-+*/.,;", &[_]Token{
        Token{ .line = 1, .lexeme = "!", .token_type = .BANG },
        Token{ .line = 1, .lexeme = "(", .token_type = .LEFT_PAREN },
        Token{ .line = 1, .lexeme = ")", .token_type = .RIGHT_PAREN },
        Token{ .line = 1, .lexeme = "{", .token_type = .LEFT_BRACE },
        Token{ .line = 1, .lexeme = "}", .token_type = .RIGHT_BRACE },
        Token{ .line = 1, .lexeme = "-", .token_type = .MINUS },
        Token{ .line = 1, .lexeme = "+", .token_type = .PLUS },
        Token{ .line = 1, .lexeme = "*", .token_type = .STAR },
        Token{ .line = 1, .lexeme = "/", .token_type = .SLASH },
        Token{ .line = 1, .lexeme = ".", .token_type = .DOT },
        Token{ .line = 1, .lexeme = ",", .token_type = .COMMA },
        Token{ .line = 1, .lexeme = ";", .token_type = .SIMICOLON },
        Token{ .line = 1, .lexeme = "", .token_type = .EOF },
    });
}

test "multi character operators" {
    try testTokenizer("! != = == < <= > >=", &[_]Token{
        Token{ .line = 1, .lexeme = "!", .token_type = .BANG },
        Token{ .line = 1, .lexeme = "!=", .token_type = .BANG_EQUAL },
        Token{ .line = 1, .lexeme = "=", .token_type = .EQUAL },
        Token{ .line = 1, .lexeme = "==", .token_type = .EQUAL_EQUAL },
        Token{ .line = 1, .lexeme = "<", .token_type = .LESS },
        Token{ .line = 1, .lexeme = "<=", .token_type = .LESS_EQUAL },
        Token{ .line = 1, .lexeme = ">", .token_type = .GREATER },
        Token{ .line = 1, .lexeme = ">=", .token_type = .GREATER_EQUAL },
        Token{ .line = 1, .lexeme = "", .token_type = .EOF },
    });
}

test "ignore comments" {
    try testTokenizer("// this a comment", &[_]Token{
        Token{ .line = 1, .lexeme = "", .token_type = .EOF },
    });
}

test "ignore commented code" {
    try testTokenizer(
        \\!
        \\// this a comment
        \\!
    , &[_]Token{
        Token{ .line = 1, .lexeme = "!", .token_type = .BANG },
        Token{ .line = 3, .lexeme = "!", .token_type = .BANG },
        Token{ .line = 3, .lexeme = "", .token_type = .EOF },
    });
}

test "scan code before one the same line before the comment" {
    try testTokenizer(
        \\!
        \\!// this a comment
        \\!
    , &[_]Token{
        Token{ .line = 1, .lexeme = "!", .token_type = .BANG },
        Token{ .line = 2, .lexeme = "!", .token_type = .BANG },
        Token{ .line = 3, .lexeme = "!", .token_type = .BANG },
        Token{ .line = 3, .lexeme = "", .token_type = .EOF },
    });
}

test "operators and comments small program" {
    try testTokenizer(
        \\// this is a comment
        \\(( )){} // grouping stuff
        \\!*+-/=<> <= == // operators
    , &[_]Token{
        // second line
        Token{ .line = 2, .lexeme = "(", .token_type = .LEFT_PAREN },
        Token{ .line = 2, .lexeme = "(", .token_type = .LEFT_PAREN },
        Token{ .line = 2, .lexeme = ")", .token_type = .RIGHT_PAREN },
        Token{ .line = 2, .lexeme = ")", .token_type = .RIGHT_PAREN },
        Token{ .line = 2, .lexeme = "{", .token_type = .LEFT_BRACE },
        Token{ .line = 2, .lexeme = "}", .token_type = .RIGHT_BRACE },
        // thid line
        Token{ .line = 3, .lexeme = "!", .token_type = .BANG },
        Token{ .line = 3, .lexeme = "*", .token_type = .STAR },
        Token{ .line = 3, .lexeme = "+", .token_type = .PLUS },
        Token{ .line = 3, .lexeme = "-", .token_type = .MINUS },
        Token{ .line = 3, .lexeme = "/", .token_type = .SLASH },
        Token{ .line = 3, .lexeme = "=", .token_type = .EQUAL },
        Token{ .line = 3, .lexeme = "<", .token_type = .LESS },
        Token{ .line = 3, .lexeme = ">", .token_type = .GREATER },
        Token{ .line = 3, .lexeme = "<=", .token_type = .LESS_EQUAL },
        Token{ .line = 3, .lexeme = "==", .token_type = .EQUAL_EQUAL },
        Token{ .line = 3, .lexeme = "", .token_type = .EOF },
    });
}

test "string literals" {
    try testTokenizer(
        \\"hello world"
    , &[_]Token{
        Token{ .line = 1, .lexeme = "hello world", .token_type = .STRING },
        Token{ .line = 1, .lexeme = "", .token_type = .EOF },
    });
}

test "unterminated string literal" {
    try testTokenizer(
        \\"hello world
    , &[_]Token{
        Token{ .line = 1, .lexeme = "", .token_type = .EOF },
    });
}

test "string with operators" {
    try testTokenizer(
        \\"hello" + "world"
    , &[_]Token{
        Token{ .line = 1, .lexeme = "hello", .token_type = .STRING },
        Token{ .line = 1, .lexeme = "+", .token_type = .PLUS },
        Token{ .line = 1, .lexeme = "world", .token_type = .STRING },
        Token{ .line = 1, .lexeme = "", .token_type = .EOF },
    });

    try testTokenizer(
        \\- "first item"
        \\- "second item"
    , &[_]Token{
        Token{ .line = 1, .lexeme = "-", .token_type = .MINUS },
        Token{ .line = 1, .lexeme = "first item", .token_type = .STRING },
        Token{ .line = 2, .lexeme = "-", .token_type = .MINUS },
        Token{ .line = 2, .lexeme = "second item", .token_type = .STRING },
        Token{ .line = 2, .lexeme = "", .token_type = .EOF },
    });
}

test "number literals" {
    try testTokenizer(
        \\123
        \\12.25
    , &[_]Token{
        Token{ .line = 1, .lexeme = "123", .token_type = .NUMBER },
        Token{ .line = 2, .lexeme = "12.25", .token_type = .NUMBER },
        Token{ .line = 2, .lexeme = "", .token_type = .EOF },
    });
}

test "identifiers and keywords" {
    try testTokenizer(
        \\nil true false and or if else for while var fn return class this super print my_variable_1
    , &[_]Token{
        Token{ .line = 1, .lexeme = "nil", .token_type = .NIL },
        Token{ .line = 1, .lexeme = "true", .token_type = .TRUE },
        Token{ .line = 1, .lexeme = "false", .token_type = .FALSE },
        Token{ .line = 1, .lexeme = "and", .token_type = .AND },
        Token{ .line = 1, .lexeme = "or", .token_type = .OR },
        Token{ .line = 1, .lexeme = "if", .token_type = .IF },
        Token{ .line = 1, .lexeme = "else", .token_type = .ELSE },
        Token{ .line = 1, .lexeme = "for", .token_type = .FOR },
        Token{ .line = 1, .lexeme = "while", .token_type = .WHILE },
        Token{ .line = 1, .lexeme = "var", .token_type = .VAR },
        Token{ .line = 1, .lexeme = "fn", .token_type = .FN },
        Token{ .line = 1, .lexeme = "return", .token_type = .RETURN },
        Token{ .line = 1, .lexeme = "class", .token_type = .CLASS },
        Token{ .line = 1, .lexeme = "this", .token_type = .THIS },
        Token{ .line = 1, .lexeme = "super", .token_type = .SUPER },
        Token{ .line = 1, .lexeme = "print", .token_type = .PRINT },
        Token{ .line = 1, .lexeme = "my_variable_1", .token_type = .IDENTIFIER },
        Token{ .line = 1, .lexeme = "", .token_type = .EOF },
    });
}

test "final" {
    try testTokenizer(
        \\// the tokenizer should be able to handle the following program
        \\class User {
        \\  int id;
        \\  string name;
        \\}
        \\fn main() {
        \\  var user = User(1, "moamen");
        \\  print(user); // this should print User(1, moamen)
        \\}
    , &[_]Token{
        Token{ .line = 2, .lexeme = "class", .token_type = .CLASS },
        Token{ .line = 2, .lexeme = "User", .token_type = .IDENTIFIER },
        Token{ .line = 2, .lexeme = "{", .token_type = .LEFT_BRACE },
        Token{ .line = 3, .lexeme = "int", .token_type = .IDENTIFIER },
        Token{ .line = 3, .lexeme = "id", .token_type = .IDENTIFIER },
        Token{ .line = 3, .lexeme = ";", .token_type = .SIMICOLON },
        Token{ .line = 4, .lexeme = "string", .token_type = .IDENTIFIER },
        Token{ .line = 4, .lexeme = "name", .token_type = .IDENTIFIER },
        Token{ .line = 4, .lexeme = ";", .token_type = .SIMICOLON },
        Token{ .line = 5, .lexeme = "}", .token_type = .RIGHT_BRACE },
        Token{ .line = 6, .lexeme = "fn", .token_type = .FN },
        Token{ .line = 6, .lexeme = "main", .token_type = .IDENTIFIER },
        Token{ .line = 6, .lexeme = "(", .token_type = .LEFT_PAREN },
        Token{ .line = 6, .lexeme = ")", .token_type = .RIGHT_PAREN },
        Token{ .line = 6, .lexeme = "{", .token_type = .LEFT_BRACE },
        Token{ .line = 7, .lexeme = "var", .token_type = .VAR },
        Token{ .line = 7, .lexeme = "user", .token_type = .IDENTIFIER },
        Token{ .line = 7, .lexeme = "=", .token_type = .EQUAL },
        Token{ .line = 7, .lexeme = "User", .token_type = .IDENTIFIER },
        Token{ .line = 7, .lexeme = "(", .token_type = .LEFT_PAREN },
        Token{ .line = 7, .lexeme = "1", .token_type = .NUMBER },
        Token{ .line = 7, .lexeme = ",", .token_type = .COMMA },
        Token{ .line = 7, .lexeme = "moamen", .token_type = .STRING },
        Token{ .line = 7, .lexeme = ")", .token_type = .RIGHT_PAREN },
        Token{ .line = 7, .lexeme = ";", .token_type = .SIMICOLON },
        Token{ .line = 8, .lexeme = "print", .token_type = .PRINT },
        Token{ .line = 8, .lexeme = "(", .token_type = .LEFT_PAREN },
        Token{ .line = 8, .lexeme = "user", .token_type = .IDENTIFIER },
        Token{ .line = 8, .lexeme = ")", .token_type = .RIGHT_PAREN },
        Token{ .line = 8, .lexeme = ";", .token_type = .SIMICOLON },
        Token{ .line = 9, .lexeme = "}", .token_type = .RIGHT_BRACE },
        Token{ .line = 9, .lexeme = "", .token_type = .EOF },
    });
}
