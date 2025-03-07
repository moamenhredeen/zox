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

pub fn scan(allocator: std.mem.Allocator, source: []const u8) ![]Token {
    var line: u32 = 1;
    var current: u32 = 0;
    var start: u32 = 0;

    var tokens: std.ArrayList(Token) = std.ArrayList(Token).init(allocator);

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

    return tokens.items;
}

test "empty" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const allocator = arena_allocator.allocator();
    const tokens = try scan(allocator, "");
    try std.testing.expectEqual(1, tokens.len);
}

test "unknown characters should be ignored" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const allocator = arena_allocator.allocator();
    const tokens = try scan(allocator, "@");
    try std.testing.expectEqual(1, tokens.len);
}

test "scan single characters lexemes" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const allocator = arena_allocator.allocator();
    const tokens = try scan(allocator, "!(){}-+*/.,;");
    try std.testing.expectEqualDeep(&[_]Token{
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
    }, tokens);
}

test "multi character operators" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const allocator = arena_allocator.allocator();

    var tokens: []Token = undefined;
    tokens = try scan(allocator, "! != = == < <= > >=");
    try std.testing.expectEqualDeep(&[_]Token{
        Token{ .line = 1, .lexeme = "!", .token_type = .BANG },
        Token{ .line = 1, .lexeme = "!=", .token_type = .BANG_EQUAL },
        Token{ .line = 1, .lexeme = "=", .token_type = .EQUAL },
        Token{ .line = 1, .lexeme = "==", .token_type = .EQUAL_EQUAL },
        Token{ .line = 1, .lexeme = "<", .token_type = .LESS },
        Token{ .line = 1, .lexeme = "<=", .token_type = .LESS_EQUAL },
        Token{ .line = 1, .lexeme = ">", .token_type = .GREATER },
        Token{ .line = 1, .lexeme = ">=", .token_type = .GREATER_EQUAL },
        Token{ .line = 1, .lexeme = "", .token_type = .EOF },
    }, tokens);
}

test "ignore comments" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const allocator = arena_allocator.allocator();

    const tokens = try scan(allocator, "// this a comment");
    try std.testing.expectEqualDeep(&[_]Token{
        Token{ .line = 1, .lexeme = "", .token_type = .EOF },
    }, tokens);
}

test "ignore commented code" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const allocator = arena_allocator.allocator();
    const tokens = try scan(allocator,
        \\!
        \\// this a comment
        \\!
    );
    try std.testing.expectEqualDeep(&[_]Token{
        Token{ .line = 1, .lexeme = "!", .token_type = .BANG },
        Token{ .line = 3, .lexeme = "!", .token_type = .BANG },
        Token{ .line = 3, .lexeme = "", .token_type = .EOF },
    }, tokens);
}

test "scan code before one the same line before the comment" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const allocator = arena_allocator.allocator();
    const tokens = try scan(allocator,
        \\!
        \\!// this a comment
        \\!
    );
    try std.testing.expectEqualDeep(&[_]Token{
        Token{ .line = 1, .lexeme = "!", .token_type = .BANG },
        Token{ .line = 2, .lexeme = "!", .token_type = .BANG },
        Token{ .line = 3, .lexeme = "!", .token_type = .BANG },
        Token{ .line = 3, .lexeme = "", .token_type = .EOF },
    }, tokens);
}

test "operators and comments small program" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const allocator = arena_allocator.allocator();
    const tokens = try scan(allocator,
        \\// this is a comment
        \\(( )){} // grouping stuff
        \\!*+-/=<> <= == // operators
    );
    try std.testing.expectEqualDeep(&[_]Token{
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
    }, tokens);
}
