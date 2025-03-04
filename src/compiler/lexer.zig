const std = @import("std");
const panic = @import("../utils.zig").panic;

/// token type
const TokenType = enum {
    // single character tokens
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

    // one or two character tokens
    BANG,
    BANG_EQUAL,
    EQUAL,
    EQUAL_EQUAL,
    GREATER,
    GREATER_EQUAL,
    LESS,
    LESS_EQUAL,

    // Literals
    IDENTIFIER,
    STRING,
    NUMBER,

    // Keywords
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

/// token representation
const Token = struct {
    token_type: TokenType,
    lexeme: []const u8,
    line: u32,
};

/// scanner
pub const Lexer = struct {
    allocator: std.mem.Allocator,
    source: []const u8,
    tokens: std.ArrayList(Token),
    pub fn init(allocator: std.mem.Allocator, source: []const u8) Lexer {
        return .{
            .allocator = allocator,
            .source = source,
            .tokens = std.ArrayList(Token).init(allocator),
        };
    }
    pub fn scan(self: *Lexer) ![]Token {
        const line: u32 = 1;
        var current: u32 = 0;
        var start: u32 = 0;

        while (current < self.source.len) : (current += 1) {
            start = current;
            const token: Token = switch (self.source[current]) {
                '(' => .{ .line = line, .lexeme = self.source[start .. current + 1], .token_type = .LEFT_PAREN },
                ')' => .{ .line = line, .lexeme = self.source[start .. current + 1], .token_type = .RIGHT_PAREN },
                '{' => .{ .line = line, .lexeme = self.source[start .. current + 1], .token_type = .LEFT_BRACE },
                '}' => .{ .line = line, .lexeme = self.source[start .. current + 1], .token_type = .RIGHT_BRACE },
                ',' => .{ .line = line, .lexeme = self.source[start .. current + 1], .token_type = .COMMA },
                '.' => .{ .line = line, .lexeme = self.source[start .. current + 1], .token_type = .DOT },
                '-' => .{ .line = line, .lexeme = self.source[start .. current + 1], .token_type = .MINUS },
                '+' => .{ .line = line, .lexeme = self.source[start .. current + 1], .token_type = .PLUS },
                ';' => .{ .line = line, .lexeme = self.source[start .. current + 1], .token_type = .SIMICOLON },
                '*' => .{ .line = line, .lexeme = self.source[start .. current + 1], .token_type = .STAR },
                '/' => .{ .line = line, .lexeme = self.source[start .. current + 1], .token_type = .SLASH },
                else => {
                    std.log.err("unexpected character in line {}", .{line});
                    continue;
                },
            };
            try self.tokens.append(token);
        }

        // at end of the file add the eof token
        try self.tokens.append(.{
            .token_type = .EOF,
            .lexeme = "",
            .line = line,
        });

        return self.tokens.items;
    }
};

test "empty" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();

    var lexer = Lexer.init(allocator, "");
    const tokens = try lexer.scan();
    try std.testing.expectEqual(1, tokens.len);
}

test "scan single characters lexemes" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();

    var lexer = Lexer.init(allocator, "()");
    const tokens = try lexer.scan();
    try std.testing.expectEqualDeep(&[_]Token{
        Token{ .line = 1, .lexeme = "(", .token_type = .LEFT_PAREN },
        Token{ .line = 1, .lexeme = ")", .token_type = .RIGHT_PAREN },
        Token{ .line = 1, .lexeme = "", .token_type = .EOF },
    }, tokens);
}

test "unknown characters should be ignored" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();

    var lexer = Lexer.init(allocator, "@");
    const tokens = try lexer.scan();
    try std.testing.expectEqual(1, tokens.len);
}
